using System.IO;
using UnityEditor;
using UnityEngine;

namespace SpecialEducationGames
{
    public partial class FlaticonIconBrowserWindow
    {
        private const string OutlineThicknessEditorPref = "SEG_FlatIcon_OutlineThickness";
        private const string OutlinePaddingEditorPref = "SEG_FlatIcon_OutlinePadding";
        private const string OutlineColorEditorPref = "SEG_FlatIcon_OutlineColor";
        private const string OutlineCanvasModeEditorPref = "SEG_FlatIcon_OutlineCanvasMode";
        private const string OutlineSourceAssetPathEditorPref = "SEG_FlatIcon_OutlineSourceAssetPath";

        private enum OutlineCanvasMode
        {
            ExpandCanvas = 0,
            FitInsideSameCanvas = 1
        }

        private int _outlineThickness = 6;
        private int _outlinePadding = 4;
        private Color _outlineColor = Color.black;
        private OutlineCanvasMode _outlineCanvasMode = OutlineCanvasMode.ExpandCanvas;
        private string _outlineSourceAssetPath = string.Empty;
        private string _outlineSourceLabel = string.Empty;
        private string _outlineSourceBaseName = "icon";
        private string _outlineStatusMessage = "Browser sekmesinde bir ikon seç veya Project penceresinden PNG seç.";

        private Texture2D _outlineSourceTexture;
        private Texture2D _outlineResultTexture;

        private GUIStyle _outlinePanelTitleStyle;
        private GUIStyle _outlineButtonStyle;
        private GUIStyle _outlineModeToolbarStyle;

        private void OnEnableOutlineTab()
        {
            _outlineThickness = EditorPrefs.GetInt(OutlineThicknessEditorPref, 6);
            _outlinePadding = EditorPrefs.GetInt(OutlinePaddingEditorPref, 4);
            _outlineCanvasMode = (OutlineCanvasMode)EditorPrefs.GetInt(OutlineCanvasModeEditorPref, (int)OutlineCanvasMode.ExpandCanvas);
            _outlineSourceAssetPath = EditorPrefs.GetString(OutlineSourceAssetPathEditorPref, string.Empty);

            string htmlColor = EditorPrefs.GetString(OutlineColorEditorPref, "000000FF");
            if (ColorUtility.TryParseHtmlString("#" + htmlColor, out Color loadedColor))
            {
                _outlineColor = loadedColor;
            }

            if (!string.IsNullOrWhiteSpace(_outlineSourceAssetPath))
            {
                Texture2D asset = AssetDatabase.LoadAssetAtPath<Texture2D>(_outlineSourceAssetPath);
                if (asset != null)
                {
                    SetOutlineSourceFromAsset(asset, true);
                }
            }
        }

        private void OnDisableOutlineTab()
        {
            EditorPrefs.SetInt(OutlineThicknessEditorPref, _outlineThickness);
            EditorPrefs.SetInt(OutlinePaddingEditorPref, _outlinePadding);
            EditorPrefs.SetInt(OutlineCanvasModeEditorPref, (int)_outlineCanvasMode);
            EditorPrefs.SetString(OutlineColorEditorPref, ColorUtility.ToHtmlStringRGBA(_outlineColor));
            EditorPrefs.SetString(OutlineSourceAssetPathEditorPref, _outlineSourceAssetPath ?? string.Empty);

            DestroyOutlineTexture(ref _outlineSourceTexture);
            DestroyOutlineTexture(ref _outlineResultTexture);
        }

        private void DrawOutlineTab()
        {
            EnsureOutlineStyles();

            if (_outlineSourceTexture == null)
            {
                TryUseSelectedBrowserIcon(true);
            }

            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                EditorGUILayout.LabelField("Outline Creator", _outlinePanelTitleStyle);
                EditorGUILayout.LabelField("PNG ikonlara editor içinde hýzlýca outline ekler. Birden fazla seçim varsa ilk seçili ikon kullanýlýr.", EditorStyles.wordWrappedMiniLabel);

                if (!string.IsNullOrWhiteSpace(_outlineStatusMessage))
                {
                    GUILayout.Space(6f);
                    EditorGUILayout.HelpBox(_outlineStatusMessage, MessageType.Info);
                }
            }

            GUILayout.Space(SectionSpacing);

            DrawOutlineSourceSection();
            GUILayout.Space(SectionSpacing);

            DrawOutlineSettingsSection();
            GUILayout.Space(SectionSpacing);

            DrawOutlineActionSection();
            GUILayout.Space(SectionSpacing);

            DrawOutlinePreviewSection();
        }

        private void EnsureOutlineStyles()
        {
            if (_outlinePanelTitleStyle == null)
            {
                _outlinePanelTitleStyle = new GUIStyle(EditorStyles.boldLabel)
                {
                    fontSize = 13,
                    wordWrap = true
                };
            }

            if (_outlineButtonStyle == null)
            {
                _outlineButtonStyle = new GUIStyle(GUI.skin.button)
                {
                    fontStyle = FontStyle.Bold,
                    fixedHeight = 30f
                };
            }

            if (_outlineModeToolbarStyle == null)
            {
                _outlineModeToolbarStyle = new GUIStyle(GUI.skin.button)
                {
                    fixedHeight = 28f,
                    fontStyle = FontStyle.Bold
                };
            }
        }

        private void DrawOutlineSourceSection()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                EditorGUILayout.LabelField("Source", _sectionTitleStyle);
                GUILayout.Space(4f);

                using (new EditorGUILayout.HorizontalScope())
                {
                    if (GUILayout.Button("Use Selected Icon", GUILayout.Height(28f)))
                    {
                        TryUseSelectedBrowserIcon(false);
                    }

                    using (new EditorGUI.DisabledScope(_outlineSourceTexture == null))
                    {
                        if (GUILayout.Button("Clear", GUILayout.Width(90f), GUILayout.Height(28f)))
                        {
                            ClearOutlineSource();
                        }
                    }
                }

                GUILayout.Space(6f);

                Texture2D currentAsset = string.IsNullOrWhiteSpace(_outlineSourceAssetPath)
                    ? null
                    : AssetDatabase.LoadAssetAtPath<Texture2D>(_outlineSourceAssetPath);

                EditorGUI.BeginChangeCheck();
                Texture2D nextAsset = (Texture2D)EditorGUILayout.ObjectField("Local PNG", currentAsset, typeof(Texture2D), false);
                if (EditorGUI.EndChangeCheck())
                {
                    if (nextAsset != null)
                    {
                        SetOutlineSourceFromAsset(nextAsset, false);
                    }
                    else
                    {
                        ClearOutlineSource();
                    }
                }

                EditorGUILayout.LabelField(
                    "Current Source",
                    string.IsNullOrWhiteSpace(_outlineSourceLabel) ? "-" : _outlineSourceLabel,
                    EditorStyles.wordWrappedMiniLabel);
            }
        }

        private void DrawOutlineSettingsSection()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                EditorGUILayout.LabelField("Outline Settings", _sectionTitleStyle);
                GUILayout.Space(4f);

                EditorGUILayout.LabelField("Canvas Mode", _filterTitleStyle);
                _outlineCanvasMode = (OutlineCanvasMode)GUILayout.Toolbar(
                    (int)_outlineCanvasMode,
                    new[] { "Expand Canvas", "Keep Same Size" },
                    _outlineModeToolbarStyle);

                GUILayout.Space(6f);

                _outlineThickness = EditorGUILayout.IntSlider("Thickness", _outlineThickness, 1, 32);
                _outlinePadding = EditorGUILayout.IntSlider("Padding", _outlinePadding, 0, 32);
                _outlineColor = EditorGUILayout.ColorField(new GUIContent("Color"), _outlineColor, true, true, true);
                if (_outlineCanvasMode == OutlineCanvasMode.ExpandCanvas)
                {
                    EditorGUILayout.HelpBox("Canvas büyür. Outline hiçbir tarafta kesilmez.", MessageType.None);
                }
                else
                {
                    EditorGUILayout.HelpBox("Canvas boyutu ayný kalýr. Ýkon, outline ile birlikte sýðmasý için içeri doðru ölçeklenir.", MessageType.None);
                }

                EditorGUILayout.HelpBox("Daha net çýktý için browser sekmesinde Thumbnail Size deðerini büyütebilirsin.", MessageType.None);
            }
        }

        private void DrawOutlineActionSection()
        {
            using (new EditorGUILayout.HorizontalScope(EditorStyles.helpBox))
            {
                using (new EditorGUI.DisabledScope(_outlineSourceTexture == null))
                {
                    if (GUILayout.Button("Create Outline", _outlineButtonStyle))
                    {
                        CreateOutlinePreview();
                    }
                }

                using (new EditorGUI.DisabledScope(_outlineResultTexture == null))
                {
                    if (GUILayout.Button("Save Outlined PNG", _outlineButtonStyle))
                    {
                        SaveOutlinedTexture();
                    }
                }
            }
        }

        private void DrawOutlinePreviewSection()
        {
            float availableWidth = Mathf.Max(420f, position.width - (OuterPadding * 2f) - 20f);
            bool stackVertically = availableWidth < 760f;
            float previewWidth = stackVertically ? availableWidth : ((availableWidth - 8f) * 0.5f);

            if (stackVertically)
            {
                DrawOutlinePreviewCard("Original", _outlineSourceTexture, previewWidth);
                GUILayout.Space(8f);
                DrawOutlinePreviewCard("Outlined", _outlineResultTexture, previewWidth);
                return;
            }

            using (new EditorGUILayout.HorizontalScope())
            {
                DrawOutlinePreviewCard("Original", _outlineSourceTexture, previewWidth);
                GUILayout.Space(8f);
                DrawOutlinePreviewCard("Outlined", _outlineResultTexture, previewWidth);
            }
        }

        private void DrawOutlinePreviewCard(string title, Texture2D texture, float width)
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox, GUILayout.Width(width)))
            {
                EditorGUILayout.LabelField(title, _filterTitleStyle);
                GUILayout.Space(4f);

                Rect outerRect = GUILayoutUtility.GetRect(width - 16f, 310f, GUILayout.ExpandWidth(true));
                GUI.Box(outerRect, GUIContent.none, EditorStyles.helpBox);

                Rect previewRect = new Rect(
                    outerRect.x + 8f,
                    outerRect.y + 8f,
                    outerRect.width - 16f,
                    outerRect.height - 16f);

                DrawPreviewSurface(previewRect, texture);
            }
        }

        private void DrawPreviewSurface(Rect rect, Texture2D texture)
        {
            GUI.BeginGroup(rect);
            try
            {
                Rect localRect = new Rect(0f, 0f, rect.width, rect.height);
                DrawCheckerBackground(localRect);

                if (texture != null)
                {
                    Rect textureRect = GetScaledTextureRect(localRect, texture.width, texture.height, 12f);
                    GUI.DrawTexture(textureRect, texture, ScaleMode.ScaleToFit, true);

                    Rect infoRect = new Rect(
                        8f,
                        localRect.height - 24f,
                        localRect.width - 16f,
                        18f);

                    EditorGUI.DrawRect(infoRect, new Color(0f, 0f, 0f, 0.55f));
                    GUI.Label(infoRect, texture.width + " x " + texture.height, _overlayLabelStyle);
                }
                else
                {
                    GUI.Label(localRect, "Görsel yok", GetCenteredMiniLabel());
                }
            }
            finally
            {
                GUI.EndGroup();
            }
        }

        private bool TryUseSelectedBrowserIcon(bool silent)
        {
            IconViewModel selectedIcon = GetFirstSelectedIconWithPreview();
            if (selectedIcon == null)
            {
                if (!silent)
                {
                    _outlineStatusMessage = "Outline için önce browser sekmesinde bir ikon seç.";
                }

                return false;
            }

            Texture2D clonedTexture = CreateReadableCopy(selectedIcon.PreviewTexture);
            string baseName = string.IsNullOrWhiteSpace(selectedIcon.Slug)
                ? "icon_" + selectedIcon.Id
                : selectedIcon.Slug;

            SetOutlineSourceTexture(clonedTexture, GetDisplayName(selectedIcon), baseName);

            _outlineSourceAssetPath = string.Empty;
            _outlineStatusMessage = "Kaynak ikon seçildi: " + GetDisplayName(selectedIcon);
            return true;
        }

        private IconViewModel GetFirstSelectedIconWithPreview()
        {
            for (int i = 0; i < _results.Count; i++)
            {
                IconViewModel item = _results[i];
                if (item.IsSelected && item.PreviewTexture != null)
                {
                    return item;
                }
            }

            return null;
        }

        private void SetOutlineSourceFromAsset(Texture2D asset, bool silent)
        {
            if (asset == null)
            {
                return;
            }

            _outlineSourceAssetPath = AssetDatabase.GetAssetPath(asset);

            Texture2D clonedTexture = CreateReadableCopy(asset);
            SetOutlineSourceTexture(clonedTexture, asset.name, asset.name);

            if (!silent)
            {
                _outlineStatusMessage = "Kaynak asset seçildi: " + asset.name;
            }
        }

        private void SetOutlineSourceTexture(Texture2D texture, string label, string baseName)
        {
            DestroyOutlineTexture(ref _outlineSourceTexture);
            DestroyOutlineTexture(ref _outlineResultTexture);

            _outlineSourceTexture = texture;
            _outlineSourceLabel = label;
            _outlineSourceBaseName = string.IsNullOrWhiteSpace(baseName) ? "icon" : baseName;
        }

        private void ClearOutlineSource()
        {
            DestroyOutlineTexture(ref _outlineSourceTexture);
            DestroyOutlineTexture(ref _outlineResultTexture);

            _outlineSourceAssetPath = string.Empty;
            _outlineSourceLabel = string.Empty;
            _outlineSourceBaseName = "icon";
            _outlineStatusMessage = "Kaynak temizlendi.";
        }

        private void CreateOutlinePreview()
        {
            if (_outlineSourceTexture == null)
            {
                _outlineStatusMessage = "Önce bir kaynak ikon seç.";
                return;
            }

            DestroyOutlineTexture(ref _outlineResultTexture);
            _outlineResultTexture = CreateOutlinedTexture(
                _outlineSourceTexture,
                _outlineThickness,
                _outlinePadding,
                _outlineColor,
                _outlineCanvasMode);

            _outlineResultTexture.name = SanitizeFileName(_outlineSourceBaseName) + "_outlined";
            _outlineStatusMessage = "Outline oluþturuldu.";
        }

        private void SaveOutlinedTexture()
        {
            if (_outlineResultTexture == null)
            {
                _outlineStatusMessage = "Kaydedilecek outline sonucu yok.";
                return;
            }

            if (!TryPrepareOutputFolder(out string fullFolderPath))
            {
                _outlineStatusMessage = "Geçerli bir klasör seç.";
                return;
            }

            byte[] pngBytes = _outlineResultTexture.EncodeToPNG();
            string safeBaseName = SanitizeFileName(_outlineSourceBaseName) + "_outlined";
            string filePath = Path.Combine(fullFolderPath, safeBaseName + ".png");

            int counter = 1;
            while (File.Exists(filePath))
            {
                filePath = Path.Combine(fullFolderPath, safeBaseName + "_" + counter + ".png");
                counter++;
            }

            File.WriteAllBytes(filePath, pngBytes);

            if (IsPathInsideProject(fullFolderPath))
            {
                AssetDatabase.Refresh();
            }

            _outlineStatusMessage = "Outline kaydedildi: " + Path.GetFileName(filePath);
        }

        private static Texture2D CreateOutlinedTexture(
            Texture2D source,
            int thickness,
            int padding,
            Color outlineColor,
            OutlineCanvasMode canvasMode)
        {
            if (source == null)
            {
                return null;
            }

            int radius = Mathf.Max(1, thickness);
            int border = radius + Mathf.Max(0, padding);

            if (canvasMode == OutlineCanvasMode.ExpandCanvas)
            {
                int targetWidth = source.width + (border * 2);
                int targetHeight = source.height + (border * 2);

                return RenderOutlinedTexture(
                    source.GetPixels32(),
                    source.width,
                    source.height,
                    targetWidth,
                    targetHeight,
                    border,
                    border,
                    radius,
                    outlineColor);
            }

            int maxBorderX = Mathf.Max(0, (source.width - 1) / 2);
            int maxBorderY = Mathf.Max(0, (source.height - 1) / 2);
            int appliedBorder = Mathf.Min(border, maxBorderX, maxBorderY);

            int scaledWidth = Mathf.Max(1, source.width - (appliedBorder * 2));
            int scaledHeight = Mathf.Max(1, source.height - (appliedBorder * 2));

            Texture2D scaledSource = ScaleTexture(source, scaledWidth, scaledHeight);

            try
            {
                int offsetX = (source.width - scaledWidth) / 2;
                int offsetY = (source.height - scaledHeight) / 2;

                return RenderOutlinedTexture(
                    scaledSource.GetPixels32(),
                    scaledWidth,
                    scaledHeight,
                    source.width,
                    source.height,
                    offsetX,
                    offsetY,
                    radius,
                    outlineColor);
            }
            finally
            {
                if (scaledSource != null)
                {
                    DestroyImmediate(scaledSource);
                }
            }
        }

        private static Texture2D RenderOutlinedTexture(
            Color32[] sourcePixels,
            int sourceWidth,
            int sourceHeight,
            int targetWidth,
            int targetHeight,
            int offsetX,
            int offsetY,
            int radius,
            Color outlineColor)
        {
            Color32[] resultPixels = new Color32[targetWidth * targetHeight];
            Color32 outlineColor32 = outlineColor;
            int radiusSquared = radius * radius;

            for (int y = 0; y < sourceHeight; y++)
            {
                for (int x = 0; x < sourceWidth; x++)
                {
                    Color32 sourcePixel = sourcePixels[(y * sourceWidth) + x];
                    if (sourcePixel.a == 0)
                    {
                        continue;
                    }

                    int centerX = x + offsetX;
                    int centerY = y + offsetY;
                    byte appliedAlpha = (byte)((outlineColor32.a * sourcePixel.a) / 255);

                    for (int offsetYLoop = -radius; offsetYLoop <= radius; offsetYLoop++)
                    {
                        for (int offsetXLoop = -radius; offsetXLoop <= radius; offsetXLoop++)
                        {
                            if ((offsetXLoop * offsetXLoop) + (offsetYLoop * offsetYLoop) > radiusSquared)
                            {
                                continue;
                            }

                            int targetX = centerX + offsetXLoop;
                            int targetY = centerY + offsetYLoop;

                            if (targetX < 0 || targetY < 0 || targetX >= targetWidth || targetY >= targetHeight)
                            {
                                continue;
                            }

                            int targetIndex = (targetY * targetWidth) + targetX;
                            if (appliedAlpha > resultPixels[targetIndex].a)
                            {
                                resultPixels[targetIndex] = new Color32(
                                    outlineColor32.r,
                                    outlineColor32.g,
                                    outlineColor32.b,
                                    appliedAlpha);
                            }
                        }
                    }
                }
            }

            for (int y = 0; y < sourceHeight; y++)
            {
                for (int x = 0; x < sourceWidth; x++)
                {
                    Color32 sourcePixel = sourcePixels[(y * sourceWidth) + x];
                    if (sourcePixel.a == 0)
                    {
                        continue;
                    }

                    int targetX = x + offsetX;
                    int targetY = y + offsetY;
                    int targetIndex = (targetY * targetWidth) + targetX;
                    resultPixels[targetIndex] = AlphaBlend(resultPixels[targetIndex], sourcePixel);
                }
            }

            Texture2D texture = new Texture2D(targetWidth, targetHeight, TextureFormat.RGBA32, false);
            texture.SetPixels32(resultPixels);
            texture.Apply();
            return texture;
        }

        private static Color32 AlphaBlend(Color32 background, Color32 foreground)
        {
            float foregroundAlpha = foreground.a / 255f;
            if (foregroundAlpha <= 0f)
            {
                return background;
            }

            float backgroundAlpha = background.a / 255f;
            float outputAlpha = foregroundAlpha + (backgroundAlpha * (1f - foregroundAlpha));
            if (outputAlpha <= 0f)
            {
                return new Color32(0, 0, 0, 0);
            }

            float red = ((foreground.r / 255f) * foregroundAlpha) + ((background.r / 255f) * backgroundAlpha * (1f - foregroundAlpha));
            float green = ((foreground.g / 255f) * foregroundAlpha) + ((background.g / 255f) * backgroundAlpha * (1f - foregroundAlpha));
            float blue = ((foreground.b / 255f) * foregroundAlpha) + ((background.b / 255f) * backgroundAlpha * (1f - foregroundAlpha));

            return new Color(red / outputAlpha, green / outputAlpha, blue / outputAlpha, outputAlpha);
        }

        private static Texture2D ScaleTexture(Texture source, int width, int height)
        {
            RenderTexture renderTexture = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGB32);
            RenderTexture previous = RenderTexture.active;

            Graphics.Blit(source, renderTexture);
            RenderTexture.active = renderTexture;

            Texture2D texture = new Texture2D(width, height, TextureFormat.RGBA32, false);
            texture.ReadPixels(new Rect(0f, 0f, width, height), 0, 0);
            texture.Apply();

            RenderTexture.active = previous;
            RenderTexture.ReleaseTemporary(renderTexture);
            return texture;
        }

        private static Texture2D CreateReadableCopy(Texture source)
        {
            if (source == null)
            {
                return null;
            }

            return ScaleTexture(source, source.width, source.height);
        }

        private static Rect GetScaledTextureRect(Rect containerRect, int textureWidth, int textureHeight, float padding)
        {
            Rect paddedRect = new Rect(
                containerRect.x + padding,
                containerRect.y + padding,
                Mathf.Max(1f, containerRect.width - (padding * 2f)),
                Mathf.Max(1f, containerRect.height - (padding * 2f)));

            if (textureWidth <= 0 || textureHeight <= 0)
            {
                return paddedRect;
            }

            float textureAspect = textureWidth / (float)textureHeight;
            float rectAspect = paddedRect.width / paddedRect.height;

            if (textureAspect > rectAspect)
            {
                float height = paddedRect.width / textureAspect;
                float y = paddedRect.y + ((paddedRect.height - height) * 0.5f);
                return new Rect(paddedRect.x, y, paddedRect.width, height);
            }

            float width = paddedRect.height * textureAspect;
            float x = paddedRect.x + ((paddedRect.width - width) * 0.5f);
            return new Rect(x, paddedRect.y, width, paddedRect.height);
        }

        private static void DestroyOutlineTexture(ref Texture2D texture)
        {
            if (texture == null)
            {
                return;
            }

            DestroyImmediate(texture);
            texture = null;
        }

        private static void DrawCheckerBackground(Rect rect)
        {
            const float size = 12f;
            Color colorA = new Color(0.23f, 0.23f, 0.23f);
            Color colorB = new Color(0.31f, 0.31f, 0.31f);

            int columns = Mathf.CeilToInt(rect.width / size);
            int rows = Mathf.CeilToInt(rect.height / size);

            for (int y = 0; y < rows; y++)
            {
                for (int x = 0; x < columns; x++)
                {
                    float cellX = x * size;
                    float cellY = y * size;
                    float cellWidth = Mathf.Min(size, rect.width - cellX);
                    float cellHeight = Mathf.Min(size, rect.height - cellY);

                    if (cellWidth <= 0f || cellHeight <= 0f)
                    {
                        continue;
                    }

                    Rect cell = new Rect(rect.x + cellX, rect.y + cellY, cellWidth, cellHeight);
                    EditorGUI.DrawRect(cell, ((x + y) % 2 == 0) ? colorA : colorB);
                }
            }
        }
    }
}
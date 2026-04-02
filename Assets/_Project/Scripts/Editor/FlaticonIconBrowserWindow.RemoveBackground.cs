using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using UnityEditor;
using UnityEngine;
using System.Text;
using System.Threading.Tasks;
using UnityEngine.Networking;

namespace SpecialEducationGames
{
    public partial class FlaticonIconBrowserWindow
    {
        private const string BackgroundRemoveSourceAssetPathEditorPref = "SEG_BackgroundRemove_SourceAssetPath";
        private const string BackgroundRemoveTrimTransparentBoundsEditorPref = "SEG_BackgroundRemove_TrimTransparentBounds";
        private const string BackgroundRemoveWhiteThresholdEditorPref = "SEG_BackgroundRemove_WhiteThreshold";
        private const string BackgroundRemoveWhiteSoftnessEditorPref = "SEG_BackgroundRemove_WhiteSoftness";
        private const string BackgroundRemoveSaveFullSizeEditorPref = "SEG_BackgroundRemove_SaveFullSize";
        private const string BackgroundRemoveSaveWidthEditorPref = "SEG_BackgroundRemove_SaveWidth";
        private const string BackgroundRemoveSaveHeightEditorPref = "SEG_BackgroundRemove_SaveHeight";
        private const string BackgroundRemoveSaveKeepAspectEditorPref = "SEG_BackgroundRemove_SaveKeepAspect";

        private const string ZipExportTemporaryImportFolder = "Assets/_Project/Temp/FlaticonZipExporterPsdImports";

        private string _backgroundRemoveSourceAssetPath = string.Empty;
        private string _backgroundRemoveSourceLabel = string.Empty;
        private string _backgroundRemoveSourceBaseName = "image";
        private string _backgroundRemoveStatusMessage = "Bir görsel seç ve Remove Background ile dene.";

        private bool _backgroundRemoveTrimTransparentBounds = true;
        private float _backgroundRemoveWhiteThreshold = 0.94f;
        private float _backgroundRemoveWhiteSoftness = 0.04f;

        private Texture2D _backgroundRemoveSourceTexture;
        private Texture2D _backgroundRemoveResultTexture;
        private const string BackgroundRemoveImgBbApiKeyEditorPref = "SEG_BackgroundRemove_ImgBbApiKey";
        private const string BackgroundRemoveApiEndpoint = "https://api.freepik.com/v1/ai/beta/remove-background";

        private string _backgroundRemoveImgBbApiKey = string.Empty;
        private bool _isBackgroundRemoveApiRunning;

        private bool _backgroundRemoveSaveFullSize = true;
        private int _backgroundRemoveSaveWidth = 256;
        private int _backgroundRemoveSaveHeight = 256;
        private bool _backgroundRemoveSaveKeepAspect = true;

        [Serializable]
        private sealed class ImgBbResponse
        {
            public ImgBbData data;
        }

        [Serializable]
        private sealed class ImgBbData
        {
            public string url;
        }

        [Serializable]
        private sealed class FreepikRemoveBackgroundResponse
        {
            public string original;
            public string high_resolution;
            public string preview;
            public string url;
        }

        private enum PsdLayerExportMode
        {
            Flattened = 0,
            CompositeWithoutBackground = 1,
            ExportEachLayer = 2
        }

        private sealed class ImageProcessingOptions
        {
            public bool ResizeOutput;
            public int TargetWidth;
            public int TargetHeight;
            public bool KeepAspect;
            public bool TrimTransparentBounds;
            public bool RemoveNearWhiteFromJpg;
            public float WhiteThreshold;
            public float WhiteSoftness;
            public PsdLayerExportMode PsdLayerMode;
        }

        private void OnEnableZipExportTab()
        {
            _backgroundRemoveSourceAssetPath = EditorPrefs.GetString(BackgroundRemoveSourceAssetPathEditorPref, string.Empty);
            _backgroundRemoveTrimTransparentBounds = EditorPrefs.GetBool(BackgroundRemoveTrimTransparentBoundsEditorPref, true);
            _backgroundRemoveWhiteThreshold = Mathf.Clamp01(EditorPrefs.GetFloat(BackgroundRemoveWhiteThresholdEditorPref, 0.94f));
            _backgroundRemoveWhiteSoftness = Mathf.Clamp(EditorPrefs.GetFloat(BackgroundRemoveWhiteSoftnessEditorPref, 0.04f), 0f, 0.20f);
            _backgroundRemoveImgBbApiKey = EditorPrefs.GetString(BackgroundRemoveImgBbApiKeyEditorPref, string.Empty);

            _backgroundRemoveSaveFullSize = EditorPrefs.GetBool(BackgroundRemoveSaveFullSizeEditorPref, true);
            _backgroundRemoveSaveWidth = Mathf.Max(1, EditorPrefs.GetInt(BackgroundRemoveSaveWidthEditorPref, 512));
            _backgroundRemoveSaveHeight = Mathf.Max(1, EditorPrefs.GetInt(BackgroundRemoveSaveHeightEditorPref, 512));
            _backgroundRemoveSaveKeepAspect = EditorPrefs.GetBool(BackgroundRemoveSaveKeepAspectEditorPref, true);

            if (!string.IsNullOrWhiteSpace(_backgroundRemoveSourceAssetPath))
            {
                Texture2D asset = AssetDatabase.LoadAssetAtPath<Texture2D>(_backgroundRemoveSourceAssetPath);
                if (asset != null)
                {
                    SetBackgroundRemoveSourceFromAsset(asset, true);
                }
            }
        }

        private void OnDisableZipExportTab()
        {
            EditorPrefs.SetString(BackgroundRemoveSourceAssetPathEditorPref, _backgroundRemoveSourceAssetPath ?? string.Empty);
            EditorPrefs.SetBool(BackgroundRemoveTrimTransparentBoundsEditorPref, _backgroundRemoveTrimTransparentBounds);
            EditorPrefs.SetFloat(BackgroundRemoveWhiteThresholdEditorPref, Mathf.Clamp01(_backgroundRemoveWhiteThreshold));
            EditorPrefs.SetFloat(BackgroundRemoveWhiteSoftnessEditorPref, Mathf.Clamp(_backgroundRemoveWhiteSoftness, 0f, 0.20f));
            EditorPrefs.SetString(BackgroundRemoveImgBbApiKeyEditorPref, _backgroundRemoveImgBbApiKey ?? string.Empty);

            EditorPrefs.SetBool(BackgroundRemoveSaveFullSizeEditorPref, _backgroundRemoveSaveFullSize);
            EditorPrefs.SetInt(BackgroundRemoveSaveWidthEditorPref, Mathf.Max(1, _backgroundRemoveSaveWidth));
            EditorPrefs.SetInt(BackgroundRemoveSaveHeightEditorPref, Mathf.Max(1, _backgroundRemoveSaveHeight));
            EditorPrefs.SetBool(BackgroundRemoveSaveKeepAspectEditorPref, _backgroundRemoveSaveKeepAspect);

            DestroyTextures(_backgroundRemoveSourceTexture, _backgroundRemoveResultTexture);
            _backgroundRemoveSourceTexture = null;
            _backgroundRemoveResultTexture = null;
        }

        private void DrawZipExportTab()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                EditorGUILayout.LabelField("Background Remove", _sectionTitleStyle);
                EditorGUILayout.LabelField(
                    "Near-white alanlarý transparan yapmaya çalýþýr. Düz beyaz arka planda daha iyi sonuç verir.",
                    EditorStyles.wordWrappedMiniLabel);

                GUILayout.Space(6f);

                if (!string.IsNullOrWhiteSpace(_backgroundRemoveStatusMessage))
                {
                    EditorGUILayout.HelpBox(_backgroundRemoveStatusMessage, MessageType.Info);
                }
            }

            GUILayout.Space(SectionSpacing);

            DrawBackgroundRemoveSourceSection();
            GUILayout.Space(SectionSpacing);

            DrawBackgroundRemoveSettingsSection();
            GUILayout.Space(SectionSpacing);

            DrawBackgroundRemoveActionSection();
            GUILayout.Space(SectionSpacing);

            DrawBackgroundRemovePreviewSection();
        }

        private void DrawBackgroundRemoveSourceSection()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                EditorGUILayout.LabelField("Source", _sectionTitleStyle);
                GUILayout.Space(4f);

                using (new EditorGUILayout.HorizontalScope())
                {
                    if (GUILayout.Button("Select File", GUILayout.Height(28f)))
                    {
                        string selectedFile = EditorUtility.OpenFilePanel(
                            "Select Image",
                            Application.dataPath,
                            string.Empty);

                        if (!string.IsNullOrWhiteSpace(selectedFile))
                        {
                            SetBackgroundRemoveSourceFromFile(selectedFile, false);
                        }
                    }

                    using (new EditorGUI.DisabledScope(_backgroundRemoveSourceTexture == null))
                    {
                        if (GUILayout.Button("Clear", GUILayout.Width(90f), GUILayout.Height(28f)))
                        {
                            ClearBackgroundRemoveSource();
                        }
                    }
                }

                GUILayout.Space(6f);

                Texture2D currentAsset = string.IsNullOrWhiteSpace(_backgroundRemoveSourceAssetPath)
                    ? null
                    : AssetDatabase.LoadAssetAtPath<Texture2D>(_backgroundRemoveSourceAssetPath);

                EditorGUI.BeginChangeCheck();
                Texture2D nextAsset = (Texture2D)EditorGUILayout.ObjectField("Project Image", currentAsset, typeof(Texture2D), false);
                if (EditorGUI.EndChangeCheck())
                {
                    if (nextAsset != null)
                    {
                        SetBackgroundRemoveSourceFromAsset(nextAsset, false);
                    }
                    else
                    {
                        ClearBackgroundRemoveSource();
                    }
                }

                using (new EditorGUILayout.HorizontalScope())
                {
                    _outputFolder = EditorGUILayout.TextField("Save Folder", _outputFolder);

                    if (GUILayout.Button("Select", GUILayout.Width(80f)))
                    {
                        string selectedFolder = EditorUtility.OpenFolderPanel("Select Output Folder", Application.dataPath, string.Empty);
                        if (!string.IsNullOrWhiteSpace(selectedFolder))
                        {
                            _outputFolder = MakeProjectRelativePath(selectedFolder);
                            EditorPrefs.SetString(OutputFolderEditorPref, _outputFolder ?? string.Empty);
                        }
                    }
                }

                EditorGUILayout.LabelField(
                    "Current Source",
                    string.IsNullOrWhiteSpace(_backgroundRemoveSourceLabel) ? "-" : _backgroundRemoveSourceLabel,
                    EditorStyles.wordWrappedMiniLabel);
            }
        }

        private void DrawBackgroundRemoveSettingsSection()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                EditorGUILayout.LabelField("Settings", _sectionTitleStyle);
                GUILayout.Space(4f);

                _backgroundRemoveTrimTransparentBounds = EditorGUILayout.ToggleLeft("Transparan boþluklarý trim et", _backgroundRemoveTrimTransparentBounds);
                _backgroundRemoveWhiteThreshold = EditorGUILayout.Slider("White Threshold", _backgroundRemoveWhiteThreshold, 0.80f, 1.00f);
                _backgroundRemoveWhiteSoftness = EditorGUILayout.Slider("White Softness", _backgroundRemoveWhiteSoftness, 0.00f, 0.20f);

                GUILayout.Space(8f);
                EditorGUILayout.LabelField("Save Settings", _filterTitleStyle);

                _backgroundRemoveSaveFullSize = EditorGUILayout.ToggleLeft("Full Size kaydet", _backgroundRemoveSaveFullSize);

                using (new EditorGUI.DisabledScope(_backgroundRemoveSaveFullSize))
                {
                    using (new EditorGUILayout.HorizontalScope())
                    {
                        _backgroundRemoveSaveWidth = Mathf.Max(1, EditorGUILayout.IntField("Width", _backgroundRemoveSaveWidth));
                        GUILayout.Space(8f);
                        _backgroundRemoveSaveHeight = Mathf.Max(1, EditorGUILayout.IntField("Height", _backgroundRemoveSaveHeight));
                    }

                    _backgroundRemoveSaveKeepAspect = EditorGUILayout.ToggleLeft(
                        "Keep Aspect Ratio ve transparan canvas içine ortala",
                        _backgroundRemoveSaveKeepAspect);
                }

                GUILayout.Space(8f);
                EditorGUILayout.LabelField("API Settings", _filterTitleStyle);

                EditorGUI.BeginChangeCheck();
                _apiKey = EditorGUILayout.PasswordField("Freepik API Key", _apiKey);
                if (EditorGUI.EndChangeCheck())
                {
                    EditorPrefs.SetString(ApiKeyEditorPref, _apiKey ?? string.Empty);
                }

                EditorGUI.BeginChangeCheck();
                _backgroundRemoveImgBbApiKey = EditorGUILayout.PasswordField("ImgBB API Key", _backgroundRemoveImgBbApiKey);
                if (EditorGUI.EndChangeCheck())
                {
                    EditorPrefs.SetString(BackgroundRemoveImgBbApiKeyEditorPref, _backgroundRemoveImgBbApiKey ?? string.Empty);
                }

                GUILayout.Space(6f);
                EditorGUILayout.HelpBox(
                    "Local yöntem sadece near-white bölgeleri siler. Karmaþýk arka planlarda API butonunu kullan.",
                    MessageType.None);

                if (string.IsNullOrWhiteSpace(_apiKey))
                {
                    EditorGUILayout.HelpBox("API removal için Freepik API key gerekli.", MessageType.Warning);
                }

                if (string.IsNullOrWhiteSpace(_backgroundRemoveImgBbApiKey))
                {
                    EditorGUILayout.HelpBox("API removal için ImgBB API key gerekli.", MessageType.Warning);
                }
            }
        }

        private void DrawBackgroundRemoveActionSection()
        {
            using (new EditorGUILayout.HorizontalScope(EditorStyles.helpBox))
            {
                using (new EditorGUI.DisabledScope(_backgroundRemoveSourceTexture == null || _isBackgroundRemoveApiRunning))
                {
                    if (GUILayout.Button("Remove White Background", GUILayout.Height(30f)))
                    {
                        RemoveBackgroundPreview();
                    }
                }

                bool canUseApi =
                    _backgroundRemoveSourceTexture != null &&
                    !_isBackgroundRemoveApiRunning &&
                    !string.IsNullOrWhiteSpace(_apiKey) &&
                    !string.IsNullOrWhiteSpace(_backgroundRemoveImgBbApiKey);

                using (new EditorGUI.DisabledScope(!canUseApi))
                {
                    if (GUILayout.Button(_isBackgroundRemoveApiRunning ? "API Processing..." : "Remove Background (API)", GUILayout.Height(30f)))
                    {
                        RemoveBackgroundWithApiAsync().Forget();
                    }
                }

                using (new EditorGUI.DisabledScope(_backgroundRemoveResultTexture == null || _isBackgroundRemoveApiRunning))
                {
                    if (GUILayout.Button("Save Result PNG", GUILayout.Height(30f)))
                    {
                        SaveBackgroundRemovedTexture();
                    }
                }
            }
        }

        private void DrawBackgroundRemovePreviewSection()
        {
            float availableWidth = Mathf.Max(420f, position.width - (OuterPadding * 2f) - 20f);
            bool stackVertically = availableWidth < 760f;
            float previewWidth = stackVertically ? availableWidth : ((availableWidth - 8f) * 0.5f);

            if (stackVertically)
            {
                DrawBackgroundPreviewCard("Original", _backgroundRemoveSourceTexture, previewWidth);
                GUILayout.Space(8f);
                DrawBackgroundPreviewCard("Result", _backgroundRemoveResultTexture, previewWidth);
                return;
            }

            using (new EditorGUILayout.HorizontalScope())
            {
                DrawBackgroundPreviewCard("Original", _backgroundRemoveSourceTexture, previewWidth);
                GUILayout.Space(8f);
                DrawBackgroundPreviewCard("Result", _backgroundRemoveResultTexture, previewWidth);
            }
        }

        private void DrawBackgroundPreviewCard(string title, Texture2D texture, float width)
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

        private void SetBackgroundRemoveSourceFromAsset(Texture2D asset, bool silent)
        {
            if (asset == null)
            {
                return;
            }

            Texture2D readableTexture = CreateReadableCopy(asset);
            if (readableTexture == null)
            {
                _backgroundRemoveStatusMessage = "Seçilen asset okunamadý.";
                return;
            }

            _backgroundRemoveSourceAssetPath = AssetDatabase.GetAssetPath(asset);
            SetBackgroundRemoveSourceTexture(readableTexture, asset.name, asset.name);

            if (!silent)
            {
                _backgroundRemoveStatusMessage = "Kaynak asset seçildi: " + asset.name;
            }
        }

        private void SetBackgroundRemoveSourceFromFile(string filePath, bool silent)
        {
            if (string.IsNullOrWhiteSpace(filePath) || !File.Exists(filePath))
            {
                _backgroundRemoveStatusMessage = "Geçerli bir dosya seç.";
                return;
            }

            if (!TryLoadTextureFromSourcePath(filePath, out Texture2D texture, out string errorMessage))
            {
                _backgroundRemoveStatusMessage = errorMessage;
                return;
            }

            _backgroundRemoveSourceAssetPath = string.Empty;
            string label = Path.GetFileName(filePath);
            string baseName = Path.GetFileNameWithoutExtension(filePath);

            SetBackgroundRemoveSourceTexture(texture, label, baseName);

            if (!silent)
            {
                _backgroundRemoveStatusMessage = "Kaynak dosya seçildi: " + label;
            }
        }

        private void SetBackgroundRemoveSourceTexture(Texture2D texture, string label, string baseName)
        {
            DestroyTextures(_backgroundRemoveSourceTexture, _backgroundRemoveResultTexture);
            _backgroundRemoveSourceTexture = texture;
            _backgroundRemoveResultTexture = null;
            _backgroundRemoveSourceLabel = label;
            _backgroundRemoveSourceBaseName = string.IsNullOrWhiteSpace(baseName) ? "image" : baseName;
        }

        private void ClearBackgroundRemoveSource()
        {
            DestroyTextures(_backgroundRemoveSourceTexture, _backgroundRemoveResultTexture);
            _backgroundRemoveSourceTexture = null;
            _backgroundRemoveResultTexture = null;
            _backgroundRemoveSourceAssetPath = string.Empty;
            _backgroundRemoveSourceLabel = string.Empty;
            _backgroundRemoveSourceBaseName = "image";
            _backgroundRemoveStatusMessage = "Kaynak temizlendi.";
        }

        private void RemoveBackgroundPreview()
        {
            if (_backgroundRemoveSourceTexture == null)
            {
                _backgroundRemoveStatusMessage = "Önce bir görsel seç.";
                return;
            }

            Texture2D workingTexture = CreateReadableCopy(_backgroundRemoveSourceTexture);
            if (workingTexture == null)
            {
                _backgroundRemoveStatusMessage = "Kaynak görsel iþlenemedi.";
                return;
            }

            Texture2D trimmedTexture = null;

            try
            {
                RemoveNearWhiteBackgroundInPlace(
                    workingTexture,
                    _backgroundRemoveWhiteThreshold,
                    _backgroundRemoveWhiteSoftness);

                Texture2D resultTexture = workingTexture;

                if (_backgroundRemoveTrimTransparentBounds)
                {
                    trimmedTexture = TrimTransparentBorders(workingTexture, 0);
                    resultTexture = trimmedTexture;
                }

                DestroyTextures(_backgroundRemoveResultTexture);
                _backgroundRemoveResultTexture = ReferenceEquals(resultTexture, workingTexture)
                    ? CreateReadableCopy(resultTexture)
                    : resultTexture;

                if (!ReferenceEquals(_backgroundRemoveResultTexture, resultTexture))
                {
                    DestroyTextures(resultTexture);
                }

                _backgroundRemoveStatusMessage = "Background removal denendi.";
            }
            finally
            {
                DestroyTextures(workingTexture);

                if (trimmedTexture != null && !ReferenceEquals(trimmedTexture, _backgroundRemoveResultTexture))
                {
                    DestroyTextures(trimmedTexture);
                }
            }
        }

        private void SaveBackgroundRemovedTexture()
        {
            if (_backgroundRemoveResultTexture == null)
            {
                _backgroundRemoveStatusMessage = "Kaydedilecek sonuç yok.";
                return;
            }

            if (!TryPrepareOutputFolder(out string fullFolderPath))
            {
                _backgroundRemoveStatusMessage = "Geçerli bir klasör seç.";
                return;
            }

            string outputBaseName = SanitizeFileName(_backgroundRemoveSourceBaseName) + "_bg_removed";
            string outputFilePath = BuildUniquePngFilePath(fullFolderPath, outputBaseName);

            Texture2D textureToSave = null;

            try
            {
                textureToSave = _backgroundRemoveSaveFullSize
                    ? CreateReadableCopy(_backgroundRemoveResultTexture)
                    : ResizeTextureForExport(
                        _backgroundRemoveResultTexture,
                        _backgroundRemoveSaveWidth,
                        _backgroundRemoveSaveHeight,
                        _backgroundRemoveSaveKeepAspect);

                if (textureToSave == null)
                {
                    _backgroundRemoveStatusMessage = "Kaydedilecek görsel hazýrlanamadý.";
                    return;
                }

                byte[] pngBytes = textureToSave.EncodeToPNG();
                File.WriteAllBytes(outputFilePath, pngBytes);

                if (IsPathInsideProject(fullFolderPath))
                {
                    AssetDatabase.Refresh();
                }

                _backgroundRemoveStatusMessage = "PNG kaydedildi: " + Path.GetFileName(outputFilePath);
            }
            finally
            {
                DestroyTextures(textureToSave);
            }
        }

        private bool TryProcessInputFileToPng(
            string inputFilePath,
            string outputFolderPath,
            string outputBaseName,
            ImageProcessingOptions options,
            out string outputFilePath,
            out int outputFileCount,
            out string errorMessage)
        {
            outputFilePath = string.Empty;
            outputFileCount = 0;
            errorMessage = string.Empty;

            if (string.IsNullOrWhiteSpace(inputFilePath) || !File.Exists(inputFilePath))
            {
                errorMessage = "Ýþlenecek dosya bulunamadý.";
                return false;
            }

            if (IsZipFile(inputFilePath))
            {
                return TryProcessZipFileToPng(
                    inputFilePath,
                    outputFolderPath,
                    outputBaseName,
                    options,
                    out outputFilePath,
                    out outputFileCount,
                    out errorMessage);
            }

            return TryProcessSingleSourceFileToPng(
                inputFilePath,
                outputFolderPath,
                outputBaseName,
                options,
                out outputFilePath,
                out outputFileCount,
                out errorMessage);
        }

        private bool TryProcessZipFileToPng(
            string zipFilePath,
            string outputFolderPath,
            string outputBaseName,
            ImageProcessingOptions options,
            out string outputFilePath,
            out int outputFileCount,
            out string errorMessage)
        {
            outputFilePath = string.Empty;
            outputFileCount = 0;
            errorMessage = string.Empty;

            string zipFolderName = Path.GetFileNameWithoutExtension(zipFilePath);
            string extractionFolder = BuildUniqueDirectoryPathPreserveSpaces(
                Path.GetDirectoryName(zipFilePath),
                SanitizeFolderNamePreserveSpaces(zipFolderName) + "_contents");

            Directory.CreateDirectory(extractionFolder);

            try
            {
                ZipFile.ExtractToDirectory(zipFilePath, extractionFolder);

                if (!TrySelectBestSourceFileFromExtractedFolder(extractionFolder, out string selectedFilePath, out errorMessage))
                {
                    return false;
                }

                return TryProcessSingleSourceFileToPng(
                    selectedFilePath,
                    outputFolderPath,
                    outputBaseName,
                    options,
                    out outputFilePath,
                    out outputFileCount,
                    out errorMessage);
            }
            catch (Exception ex)
            {
                Debug.LogException(ex);
                errorMessage = "ZIP iþlenemedi: " + Path.GetFileName(zipFilePath);
                return false;
            }
        }

        private bool TryProcessSingleSourceFileToPng(
            string sourceFilePath,
            string outputFolderPath,
            string outputBaseName,
            ImageProcessingOptions options,
            out string outputFilePath,
            out int outputFileCount,
            out string errorMessage)
        {
            outputFilePath = string.Empty;
            outputFileCount = 0;
            errorMessage = string.Empty;

            if (IsPsdFile(sourceFilePath))
            {
                return TryProcessPsdFileToPng(
                    sourceFilePath,
                    outputFolderPath,
                    outputBaseName,
                    options,
                    out outputFilePath,
                    out outputFileCount,
                    out errorMessage);
            }

            if (!TryLoadTextureFromSourcePath(sourceFilePath, out Texture2D sourceTexture, out errorMessage))
            {
                return false;
            }

            Texture2D finalTexture = null;

            try
            {
                bool isJpg = IsJpgFile(sourceFilePath);

                finalTexture = ProcessTextureForOutput(sourceTexture, isJpg, options);
                if (finalTexture == null)
                {
                    errorMessage = "Görsel iþlenemedi.";
                    return false;
                }

                outputFilePath = BuildUniquePngFilePath(outputFolderPath, outputBaseName);
                byte[] pngBytes = finalTexture.EncodeToPNG();
                File.WriteAllBytes(outputFilePath, pngBytes);
                outputFileCount = 1;
                return true;
            }
            catch (Exception ex)
            {
                Debug.LogException(ex);
                errorMessage = "Dosya iþlenemedi: " + Path.GetFileName(sourceFilePath);
                return false;
            }
            finally
            {
                DestroyTextures(finalTexture, sourceTexture);
            }
        }

        private bool TryProcessPsdFileToPng(
            string sourceFilePath,
            string outputFolderPath,
            string outputBaseName,
            ImageProcessingOptions options,
            out string outputFilePath,
            out int outputFileCount,
            out string errorMessage)
        {
            outputFilePath = string.Empty;
            outputFileCount = 0;
            errorMessage = string.Empty;

            if (!TryImportPsdAsset(sourceFilePath, out string assetPath, out string importError))
            {
                errorMessage = importError;
                return false;
            }

            try
            {
                Texture2D flatTexture = AssetDatabase.LoadAssetAtPath<Texture2D>(assetPath);
                if (flatTexture == null)
                {
                    errorMessage = "PSD import edildi fakat Texture2D yüklenemedi.";
                    return false;
                }

                List<Sprite> layerSprites = GetPsdLayerSprites(assetPath);

                if (options.PsdLayerMode == PsdLayerExportMode.ExportEachLayer && layerSprites.Count > 0)
                {
                    List<Sprite> exportSprites = FilterBackgroundLikeSprites(layerSprites, true);
                    if (exportSprites.Count == 0)
                    {
                        exportSprites = layerSprites;
                    }

                    string firstOutputPath = string.Empty;
                    int exportedCount = 0;

                    for (int i = 0; i < exportSprites.Count; i++)
                    {
                        Sprite layerSprite = exportSprites[i];
                        Texture2D layerTexture = null;
                        Texture2D finalTexture = null;

                        try
                        {
                            layerTexture = ExtractTextureFromSprite(layerSprite);
                            finalTexture = ProcessTextureForOutput(layerTexture, false, options);

                            if (finalTexture == null)
                            {
                                continue;
                            }

                            string layerName = string.IsNullOrWhiteSpace(layerSprite.name)
                                ? "layer_" + i
                                : SanitizeFileName(layerSprite.name);

                            string currentOutputPath = BuildUniquePngFilePath(outputFolderPath, outputBaseName + "_" + layerName);
                            File.WriteAllBytes(currentOutputPath, finalTexture.EncodeToPNG());

                            if (string.IsNullOrWhiteSpace(firstOutputPath))
                            {
                                firstOutputPath = currentOutputPath;
                            }

                            exportedCount++;
                        }
                        finally
                        {
                            DestroyTextures(finalTexture, layerTexture);
                        }
                    }

                    if (exportedCount == 0)
                    {
                        errorMessage = "PSD layer export baþarýsýz oldu.";
                        return false;
                    }

                    outputFilePath = firstOutputPath;
                    outputFileCount = exportedCount;
                    return true;
                }

                Texture2D sourceTexture = null;
                Texture2D finalTextureComposite = null;

                try
                {
                    if (options.PsdLayerMode == PsdLayerExportMode.CompositeWithoutBackground && layerSprites.Count > 0)
                    {
                        List<Sprite> compositeSprites = FilterBackgroundLikeSprites(layerSprites, true);
                        if (compositeSprites.Count > 0)
                        {
                            sourceTexture = CompositeSpritesToTexture(flatTexture.width, flatTexture.height, compositeSprites);
                        }
                    }

                    if (sourceTexture == null)
                    {
                        sourceTexture = CreateReadableCopy(flatTexture);
                    }

                    finalTextureComposite = ProcessTextureForOutput(sourceTexture, false, options);
                    if (finalTextureComposite == null)
                    {
                        errorMessage = "PSD iþlenemedi.";
                        return false;
                    }

                    outputFilePath = BuildUniquePngFilePath(outputFolderPath, outputBaseName);
                    File.WriteAllBytes(outputFilePath, finalTextureComposite.EncodeToPNG());
                    outputFileCount = 1;
                    return true;
                }
                finally
                {
                    DestroyTextures(finalTextureComposite, sourceTexture);
                }
            }
            catch (Exception ex)
            {
                Debug.LogException(ex);
                errorMessage = "PSD iþlenemedi: " + Path.GetFileName(sourceFilePath);
                return false;
            }
            finally
            {
                AssetDatabase.DeleteAsset(assetPath);
            }
        }

        private Texture2D ProcessTextureForOutput(Texture2D sourceTexture, bool isJpg, ImageProcessingOptions options)
        {
            if (sourceTexture == null)
            {
                return null;
            }

            Texture2D workingTexture = CreateReadableCopy(sourceTexture);
            Texture2D trimmedTexture = null;
            Texture2D finalTexture = null;

            try
            {
                if (isJpg && options.RemoveNearWhiteFromJpg)
                {
                    RemoveNearWhiteBackgroundInPlace(
                        workingTexture,
                        options.WhiteThreshold,
                        options.WhiteSoftness);
                }

                Texture2D activeTexture = workingTexture;

                if (options.TrimTransparentBounds)
                {
                    trimmedTexture = TrimTransparentBorders(activeTexture, 0);
                    activeTexture = trimmedTexture;
                }

                finalTexture = options.ResizeOutput
                    ? ResizeTextureForExport(
                        activeTexture,
                        options.TargetWidth,
                        options.TargetHeight,
                        options.KeepAspect)
                    : CreateReadableCopy(activeTexture);

                return finalTexture;
            }
            finally
            {
                DestroyTextures(trimmedTexture, workingTexture);
            }
        }

        private bool TryLoadTextureFromSourcePath(string sourceFilePath, out Texture2D texture, out string errorMessage)
        {
            texture = null;
            errorMessage = string.Empty;

            if (string.IsNullOrWhiteSpace(sourceFilePath) || !File.Exists(sourceFilePath))
            {
                errorMessage = "Kaynak dosya bulunamadý.";
                return false;
            }

            if (IsPsdFile(sourceFilePath))
            {
                texture = TryLoadTextureFromPsd(sourceFilePath);
                if (texture == null)
                {
                    errorMessage = "PSD import edilemedi. Unity PSD importer gerekli olabilir.";
                    return false;
                }

                return true;
            }

            if (!IsRasterImageFile(sourceFilePath))
            {
                errorMessage = "Desteklenmeyen dosya formatý.";
                return false;
            }

            texture = LoadTextureFromFile(sourceFilePath);
            if (texture == null)
            {
                errorMessage = "Raster görsel okunamadý: " + Path.GetFileName(sourceFilePath);
                return false;
            }

            return true;
        }

        private bool TrySelectBestSourceFileFromExtractedFolder(string extractedFolder, out string selectedFilePath, out string errorMessage)
        {
            List<string> candidates = GetOrderedSourceCandidates(extractedFolder);

            selectedFilePath = string.Empty;
            errorMessage = "Uygun PSD/PNG/JPG dosyasý bulunamadý.";

            for (int i = 0; i < candidates.Count; i++)
            {
                string candidatePath = candidates[i];

                if (IsPsdFile(candidatePath))
                {
                    Texture2D psdTexture = TryLoadTextureFromPsd(candidatePath);
                    if (psdTexture == null)
                    {
                        errorMessage = "PSD import edilemedi. PNG/JPG fallback aranýyor.";
                        continue;
                    }

                    DestroyTextures(psdTexture);
                    selectedFilePath = candidatePath;
                    errorMessage = string.Empty;
                    return true;
                }

                Texture2D texture = LoadTextureFromFile(candidatePath);
                if (texture == null)
                {
                    errorMessage = "Raster görsel okunamadý: " + Path.GetFileName(candidatePath);
                    continue;
                }

                DestroyTextures(texture);
                selectedFilePath = candidatePath;
                errorMessage = string.Empty;
                return true;
            }

            return false;
        }

        private static bool IsZipFile(string filePath)
        {
            return string.Equals(Path.GetExtension(filePath), ".zip", StringComparison.OrdinalIgnoreCase);
        }

        private static bool IsPsdFile(string filePath)
        {
            return string.Equals(Path.GetExtension(filePath), ".psd", StringComparison.OrdinalIgnoreCase);
        }

        private static bool IsJpgFile(string filePath)
        {
            string extension = Path.GetExtension(filePath);
            return string.Equals(extension, ".jpg", StringComparison.OrdinalIgnoreCase) ||
                   string.Equals(extension, ".jpeg", StringComparison.OrdinalIgnoreCase);
        }

        private static bool IsRasterImageFile(string filePath)
        {
            string extension = Path.GetExtension(filePath);
            return string.Equals(extension, ".png", StringComparison.OrdinalIgnoreCase) ||
                   string.Equals(extension, ".jpg", StringComparison.OrdinalIgnoreCase) ||
                   string.Equals(extension, ".jpeg", StringComparison.OrdinalIgnoreCase);
        }

        private static List<string> GetOrderedSourceCandidates(string rootFolder)
        {
            List<string> results = new List<string>();

            AddOrderedCandidates(results, Directory.GetFiles(rootFolder, "*.psd", SearchOption.AllDirectories));
            AddOrderedCandidates(results, Directory.GetFiles(rootFolder, "*.png", SearchOption.AllDirectories));
            AddOrderedCandidates(results, Directory.GetFiles(rootFolder, "*.jpg", SearchOption.AllDirectories));
            AddOrderedCandidates(results, Directory.GetFiles(rootFolder, "*.jpeg", SearchOption.AllDirectories));

            return results;
        }

        private static void AddOrderedCandidates(List<string> results, string[] candidates)
        {
            if (candidates == null || candidates.Length == 0)
            {
                return;
            }

            Array.Sort(candidates, CompareSourceCandidates);

            for (int i = 0; i < candidates.Length; i++)
            {
                results.Add(candidates[i]);
            }
        }

        private static int CompareSourceCandidates(string left, string right)
        {
            int leftScore = GetSourceCandidateScore(left);
            int rightScore = GetSourceCandidateScore(right);

            if (leftScore != rightScore)
            {
                return leftScore.CompareTo(rightScore);
            }

            return StringComparer.OrdinalIgnoreCase.Compare(left, right);
        }

        private static int GetSourceCandidateScore(string filePath)
        {
            if (string.IsNullOrWhiteSpace(filePath))
            {
                return int.MaxValue;
            }

            string normalized = filePath.Replace("\\", "/").ToLowerInvariant();
            string fileName = Path.GetFileNameWithoutExtension(normalized);

            int score = 0;
            score += CountDirectoryDepth(normalized) * 10;
            score += normalized.Length;

            if (fileName.Contains("preview") ||
                fileName.Contains("thumb") ||
                fileName.Contains("thumbnail") ||
                fileName.Contains("small") ||
                fileName.Contains("sample"))
            {
                score += 500;
            }

            if (normalized.Contains("/__macosx/"))
            {
                score += 5000;
            }

            return score;
        }

        private static int CountDirectoryDepth(string path)
        {
            int count = 0;
            for (int i = 0; i < path.Length; i++)
            {
                if (path[i] == '/')
                {
                    count++;
                }
            }

            return count;
        }

        private static Texture2D LoadTextureFromFile(string filePath)
        {
            if (string.IsNullOrWhiteSpace(filePath) || !File.Exists(filePath))
            {
                return null;
            }

            byte[] bytes = File.ReadAllBytes(filePath);
            if (bytes == null || bytes.Length == 0)
            {
                return null;
            }

            Texture2D texture = new Texture2D(2, 2, TextureFormat.RGBA32, false);
            bool loaded = texture.LoadImage(bytes, false);

            if (!loaded)
            {
                DestroyImmediate(texture);
                return null;
            }

            texture.name = Path.GetFileNameWithoutExtension(filePath);
            return texture;
        }

        private static Texture2D TryLoadTextureFromPsd(string absolutePsdPath)
        {
            if (!TryImportPsdAsset(absolutePsdPath, out string assetPath, out _))
            {
                return null;
            }

            try
            {
                Texture2D assetTexture = AssetDatabase.LoadAssetAtPath<Texture2D>(assetPath);
                if (assetTexture == null)
                {
                    return null;
                }

                return CreateReadableCopy(assetTexture);
            }
            finally
            {
                AssetDatabase.DeleteAsset(assetPath);
            }
        }

        private static bool TryImportPsdAsset(string absolutePsdPath, out string assetPath, out string errorMessage)
        {
            assetPath = string.Empty;
            errorMessage = string.Empty;

            if (string.IsNullOrWhiteSpace(absolutePsdPath) || !File.Exists(absolutePsdPath))
            {
                errorMessage = "PSD dosyasý bulunamadý.";
                return false;
            }

            string importFolderAbsolute = GetAbsoluteFolderPath(ZipExportTemporaryImportFolder);
            if (string.IsNullOrWhiteSpace(importFolderAbsolute))
            {
                errorMessage = "Geçici PSD import klasörü oluþturulamadý.";
                return false;
            }

            Directory.CreateDirectory(importFolderAbsolute);
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);

            string safeFileName = SanitizeFileName(Path.GetFileNameWithoutExtension(absolutePsdPath));
            string assetFileName = safeFileName + "_" + Guid.NewGuid().ToString("N") + ".psd";
            assetPath = ZipExportTemporaryImportFolder + "/" + assetFileName;
            string absoluteAssetPath = Path.Combine(importFolderAbsolute, assetFileName);

            try
            {
                File.Copy(absolutePsdPath, absoluteAssetPath, true);

                AssetDatabase.ImportAsset(
                    assetPath,
                    ImportAssetOptions.ForceSynchronousImport | ImportAssetOptions.ForceUpdate);

                TextureImporter importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
                if (importer != null)
                {
                    bool dirty = false;

                    if (!importer.isReadable)
                    {
                        importer.isReadable = true;
                        dirty = true;
                    }

                    if (!importer.alphaIsTransparency)
                    {
                        importer.alphaIsTransparency = true;
                        dirty = true;
                    }

                    if (importer.textureCompression != TextureImporterCompression.Uncompressed)
                    {
                        importer.textureCompression = TextureImporterCompression.Uncompressed;
                        dirty = true;
                    }

                    if (importer.textureType != TextureImporterType.Sprite)
                    {
                        importer.textureType = TextureImporterType.Sprite;
                        dirty = true;
                    }

                    if (importer.spriteImportMode != SpriteImportMode.Multiple)
                    {
                        importer.spriteImportMode = SpriteImportMode.Multiple;
                        dirty = true;
                    }

                    if (dirty)
                    {
                        importer.SaveAndReimport();
                    }
                }

                return true;
            }
            catch (Exception ex)
            {
                errorMessage = "PSD import baþarýsýz: " + ex.Message;

                if (!string.IsNullOrWhiteSpace(assetPath))
                {
                    AssetDatabase.DeleteAsset(assetPath);
                }

                return false;
            }
        }

        private static List<Sprite> GetPsdLayerSprites(string assetPath)
        {
            List<Sprite> sprites = new List<Sprite>();
            UnityEngine.Object[] assets = AssetDatabase.LoadAllAssetsAtPath(assetPath);

            for (int i = 0; i < assets.Length; i++)
            {
                Sprite sprite = assets[i] as Sprite;
                if (sprite != null)
                {
                    sprites.Add(sprite);
                }
            }

            return sprites;
        }

        private static List<Sprite> FilterBackgroundLikeSprites(List<Sprite> sprites, bool excludeBackgroundLike)
        {
            List<Sprite> filtered = new List<Sprite>();

            for (int i = 0; i < sprites.Count; i++)
            {
                Sprite sprite = sprites[i];
                if (sprite == null)
                {
                    continue;
                }

                bool isBackgroundLike = IsBackgroundLikeName(sprite.name);
                if (excludeBackgroundLike && isBackgroundLike)
                {
                    continue;
                }

                filtered.Add(sprite);
            }

            return filtered;
        }

        private static bool IsBackgroundLikeName(string layerName)
        {
            if (string.IsNullOrWhiteSpace(layerName))
            {
                return false;
            }

            string normalized = layerName
                .Replace(" ", string.Empty)
                .Replace("_", string.Empty)
                .Replace("-", string.Empty)
                .ToLowerInvariant();

            return normalized == "background" ||
                   normalized.StartsWith("background", StringComparison.Ordinal) ||
                   normalized.Contains("background", StringComparison.Ordinal) ||
                   normalized == "bg" ||
                   normalized.StartsWith("bg", StringComparison.Ordinal);
        }

        private static Texture2D ExtractTextureFromSprite(Sprite sprite)
        {
            if (sprite == null || sprite.texture == null)
            {
                return null;
            }

            Rect rect = sprite.textureRect;
            int x = Mathf.RoundToInt(rect.x);
            int y = Mathf.RoundToInt(rect.y);
            int width = Mathf.RoundToInt(rect.width);
            int height = Mathf.RoundToInt(rect.height);

            if (width <= 0 || height <= 0)
            {
                return null;
            }

            Color[] pixels;

            try
            {
                pixels = sprite.texture.GetPixels(x, y, width, height);
            }
            catch
            {
                return null;
            }

            Texture2D texture = new Texture2D(width, height, TextureFormat.RGBA32, false);
            texture.SetPixels(pixels);
            texture.Apply();
            texture.name = sprite.name;
            return texture;
        }

        private static Texture2D CompositeSpritesToTexture(int canvasWidth, int canvasHeight, List<Sprite> sprites)
        {
            if (canvasWidth <= 0 || canvasHeight <= 0)
            {
                return null;
            }

            Color32[] canvasPixels = new Color32[canvasWidth * canvasHeight];

            for (int i = 0; i < sprites.Count; i++)
            {
                Sprite sprite = sprites[i];
                Texture2D layerTexture = ExtractTextureFromSprite(sprite);
                if (layerTexture == null)
                {
                    continue;
                }

                try
                {
                    Color32[] layerPixels = layerTexture.GetPixels32();
                    Rect rect = sprite.rect;
                    int startX = Mathf.RoundToInt(rect.x);
                    int startY = Mathf.RoundToInt(rect.y);
                    int width = layerTexture.width;
                    int height = layerTexture.height;

                    for (int y = 0; y < height; y++)
                    {
                        for (int x = 0; x < width; x++)
                        {
                            int targetX = startX + x;
                            int targetY = startY + y;

                            if (targetX < 0 || targetY < 0 || targetX >= canvasWidth || targetY >= canvasHeight)
                            {
                                continue;
                            }

                            int sourceIndex = (y * width) + x;
                            int targetIndex = (targetY * canvasWidth) + targetX;

                            canvasPixels[targetIndex] = AlphaBlend(canvasPixels[targetIndex], layerPixels[sourceIndex]);
                        }
                    }
                }
                finally
                {
                    DestroyTextures(layerTexture);
                }
            }

            Texture2D texture = new Texture2D(canvasWidth, canvasHeight, TextureFormat.RGBA32, false);
            texture.SetPixels32(canvasPixels);
            texture.Apply();
            return texture;
        }

        private static void RemoveNearWhiteBackgroundInPlace(Texture2D texture, float threshold, float softness)
        {
            if (texture == null)
            {
                return;
            }

            threshold = Mathf.Clamp01(threshold);
            softness = Mathf.Clamp(softness, 0f, 0.25f);

            float fadeStart = Mathf.Clamp01(threshold - softness);
            Color32[] pixels = texture.GetPixels32();

            for (int i = 0; i < pixels.Length; i++)
            {
                Color32 pixel = pixels[i];

                int minChannel = Mathf.Min(pixel.r, Mathf.Min(pixel.g, pixel.b));
                int maxChannel = Mathf.Max(pixel.r, Mathf.Max(pixel.g, pixel.b));
                int chroma = maxChannel - minChannel;

                if (chroma > 35)
                {
                    continue;
                }

                float whiteLevel = minChannel / 255f;

                if (whiteLevel >= threshold)
                {
                    pixel.a = 0;
                }
                else if (softness > 0f && whiteLevel > fadeStart)
                {
                    float t = Mathf.InverseLerp(fadeStart, threshold, whiteLevel);
                    pixel.a = (byte)Mathf.Clamp(Mathf.RoundToInt(pixel.a * (1f - t)), 0, 255);
                }

                pixels[i] = pixel;
            }

            texture.SetPixels32(pixels);
            texture.Apply();
        }

        private static Texture2D TrimTransparentBorders(Texture2D source, byte alphaThreshold)
        {
            if (source == null)
            {
                return null;
            }

            int width = source.width;
            int height = source.height;
            Color32[] pixels = source.GetPixels32();

            int minX = width;
            int minY = height;
            int maxX = -1;
            int maxY = -1;

            for (int y = 0; y < height; y++)
            {
                int rowIndex = y * width;

                for (int x = 0; x < width; x++)
                {
                    Color32 pixel = pixels[rowIndex + x];
                    if (pixel.a <= alphaThreshold)
                    {
                        continue;
                    }

                    if (x < minX) minX = x;
                    if (y < minY) minY = y;
                    if (x > maxX) maxX = x;
                    if (y > maxY) maxY = y;
                }
            }

            if (maxX < minX || maxY < minY)
            {
                return CreateReadableCopy(source);
            }

            if (minX == 0 && minY == 0 && maxX == width - 1 && maxY == height - 1)
            {
                return CreateReadableCopy(source);
            }

            int trimmedWidth = maxX - minX + 1;
            int trimmedHeight = maxY - minY + 1;
            Color32[] trimmedPixels = new Color32[trimmedWidth * trimmedHeight];

            for (int y = 0; y < trimmedHeight; y++)
            {
                for (int x = 0; x < trimmedWidth; x++)
                {
                    int sourceIndex = ((minY + y) * width) + (minX + x);
                    int targetIndex = (y * trimmedWidth) + x;
                    trimmedPixels[targetIndex] = pixels[sourceIndex];
                }
            }

            Texture2D trimmedTexture = new Texture2D(trimmedWidth, trimmedHeight, TextureFormat.RGBA32, false);
            trimmedTexture.SetPixels32(trimmedPixels);
            trimmedTexture.Apply();
            return trimmedTexture;
        }

        private static Texture2D ResizeTextureForExport(Texture2D source, int targetWidth, int targetHeight, bool keepAspect)
        {
            if (source == null)
            {
                return null;
            }

            targetWidth = Mathf.Max(1, targetWidth);
            targetHeight = Mathf.Max(1, targetHeight);

            if (!keepAspect)
            {
                return ScaleTexture(source, targetWidth, targetHeight);
            }

            float widthScale = targetWidth / (float)source.width;
            float heightScale = targetHeight / (float)source.height;
            float scale = Mathf.Min(widthScale, heightScale);

            int scaledWidth = Mathf.Max(1, Mathf.RoundToInt(source.width * scale));
            int scaledHeight = Mathf.Max(1, Mathf.RoundToInt(source.height * scale));

            Texture2D scaledTexture = ScaleTexture(source, scaledWidth, scaledHeight);

            try
            {
                Texture2D canvasTexture = new Texture2D(targetWidth, targetHeight, TextureFormat.RGBA32, false);
                Color32[] canvasPixels = new Color32[targetWidth * targetHeight];
                Color32[] scaledPixels = scaledTexture.GetPixels32();

                int offsetX = (targetWidth - scaledWidth) / 2;
                int offsetY = (targetHeight - scaledHeight) / 2;

                for (int y = 0; y < scaledHeight; y++)
                {
                    for (int x = 0; x < scaledWidth; x++)
                    {
                        int sourceIndex = (y * scaledWidth) + x;
                        int targetIndex = ((y + offsetY) * targetWidth) + (x + offsetX);
                        canvasPixels[targetIndex] = scaledPixels[sourceIndex];
                    }
                }

                canvasTexture.SetPixels32(canvasPixels);
                canvasTexture.Apply();
                return canvasTexture;
            }
            finally
            {
                DestroyTextures(scaledTexture);
            }
        }

        private static string BuildUniquePngFilePath(string folderPath, string baseName)
        {
            string safeBaseName = SanitizeFileName(baseName);
            if (string.IsNullOrWhiteSpace(safeBaseName))
            {
                safeBaseName = "exported_image";
            }

            string filePath = Path.Combine(folderPath, safeBaseName + ".png");

            int counter = 1;
            while (File.Exists(filePath))
            {
                filePath = Path.Combine(folderPath, safeBaseName + "_" + counter + ".png");
                counter++;
            }

            return filePath;
        }

        private static string BuildUniqueDirectoryPathPreserveSpaces(string parentFolderPath, string baseFolderName)
        {
            string safeBaseFolderName = SanitizeFolderNamePreserveSpaces(baseFolderName);
            if (string.IsNullOrWhiteSpace(safeBaseFolderName))
            {
                safeBaseFolderName = "folder";
            }

            string folderPath = Path.Combine(parentFolderPath, safeBaseFolderName);
            int counter = 1;

            while (Directory.Exists(folderPath))
            {
                folderPath = Path.Combine(parentFolderPath, safeBaseFolderName + " (" + counter + ")");
                counter++;
            }

            return folderPath;
        }

        private async Task RemoveBackgroundWithApiAsync()
        {
            if (_backgroundRemoveSourceTexture == null)
            {
                _backgroundRemoveStatusMessage = "Önce bir görsel seç.";
                Repaint();
                return;
            }

            if (string.IsNullOrWhiteSpace(_apiKey))
            {
                _backgroundRemoveStatusMessage = "Freepik API key gerekli.";
                Repaint();
                return;
            }

            if (string.IsNullOrWhiteSpace(_backgroundRemoveImgBbApiKey))
            {
                _backgroundRemoveStatusMessage = "ImgBB API key gerekli.";
                Repaint();
                return;
            }

            _isBackgroundRemoveApiRunning = true;
            Texture2D downloadedTexture = null;
            Texture2D trimmedTexture = null;

            try
            {
                _backgroundRemoveStatusMessage = "Görsel ImgBB'ye yükleniyor...";
                Repaint();

                string uploadedImageUrl = await UploadTextureToImgBbAsync(_backgroundRemoveSourceTexture, _backgroundRemoveImgBbApiKey);

                _backgroundRemoveStatusMessage = "Freepik background removal çalýþýyor...";
                Repaint();

                FreepikRemoveBackgroundResponse apiResponse = await RequestFreepikBackgroundRemoveAsync(uploadedImageUrl, _apiKey);
                string resultUrl = GetBestFreepikBackgroundRemovedImageUrl(apiResponse);

                if (string.IsNullOrWhiteSpace(resultUrl))
                {
                    throw new InvalidOperationException("Freepik sonuç URL'i dönmedi.");
                }

                _backgroundRemoveStatusMessage = "Ýþlenen görsel indiriliyor...";
                Repaint();

                downloadedTexture = await DownloadTextureFromUrlAsync(resultUrl);
                if (downloadedTexture == null)
                {
                    throw new InvalidOperationException("Ýþlenen görsel indirilemedi.");
                }

                Texture2D resultTexture = downloadedTexture;

                if (_backgroundRemoveTrimTransparentBounds)
                {
                    trimmedTexture = TrimTransparentBorders(downloadedTexture, 0);
                    resultTexture = trimmedTexture;
                }

                DestroyTextures(_backgroundRemoveResultTexture);
                _backgroundRemoveResultTexture = ReferenceEquals(resultTexture, downloadedTexture)
                    ? CreateReadableCopy(resultTexture)
                    : resultTexture;

                if (!ReferenceEquals(_backgroundRemoveResultTexture, resultTexture))
                {
                    DestroyTextures(resultTexture);
                }

                _backgroundRemoveStatusMessage = "API ile background kaldýrýldý.";
            }
            catch (Exception ex)
            {
                Debug.LogException(ex);
                _backgroundRemoveStatusMessage = "API background remove baþarýsýz: " + ex.Message;
            }
            finally
            {
                _isBackgroundRemoveApiRunning = false;

                if (downloadedTexture != null &&
                    !ReferenceEquals(downloadedTexture, _backgroundRemoveResultTexture) &&
                    !ReferenceEquals(downloadedTexture, trimmedTexture))
                {
                    DestroyTextures(downloadedTexture);
                }

                if (trimmedTexture != null && !ReferenceEquals(trimmedTexture, _backgroundRemoveResultTexture))
                {
                    DestroyTextures(trimmedTexture);
                }

                Repaint();
            }
        }

        private async Task<string> UploadTextureToImgBbAsync(Texture2D texture, string apiKey)
        {
            if (texture == null)
            {
                throw new ArgumentNullException(nameof(texture));
            }

            byte[] imageBytes = texture.EncodeToPNG();
            if (imageBytes == null || imageBytes.Length == 0)
            {
                throw new InvalidOperationException("PNG encode baþarýsýz.");
            }

            string base64Image = Convert.ToBase64String(imageBytes);

            WWWForm form = new WWWForm();
            form.AddField("image", base64Image);

            string requestUrl = $"https://api.imgbb.com/1/upload?key={UnityWebRequest.EscapeURL(apiKey)}";

            using UnityWebRequest request = UnityWebRequest.Post(requestUrl, form);
            request.timeout = 120;

            await SendRequestAsync(request);

            if (HasRequestError(request))
            {
                string responseText = GetSafeResponseText(request);
                throw new InvalidOperationException(
                    string.IsNullOrWhiteSpace(responseText)
                        ? $"ImgBB upload baþarýsýz: {request.responseCode} - {request.error}"
                        : $"ImgBB upload baþarýsýz: {request.responseCode} - {request.error} | {responseText}");
            }

            ImgBbResponse response;
            try
            {
                response = JsonUtility.FromJson<ImgBbResponse>(request.downloadHandler.text);
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException("ImgBB response parse edilemedi: " + ex.Message, ex);
            }

            string imageUrl = response != null && response.data != null ? response.data.url : string.Empty;
            imageUrl = EnsureHttpsUrl(imageUrl);

            if (string.IsNullOrWhiteSpace(imageUrl))
            {
                throw new InvalidOperationException("ImgBB public URL dönmedi.");
            }

            return imageUrl;
        }

        private async Task<FreepikRemoveBackgroundResponse> RequestFreepikBackgroundRemoveAsync(string imageUrl, string apiKey)
        {
            if (string.IsNullOrWhiteSpace(imageUrl))
            {
                throw new ArgumentException("Image URL boþ.", nameof(imageUrl));
            }

            byte[] bodyBytes = Encoding.UTF8.GetBytes("image_url=" + UnityWebRequest.EscapeURL(imageUrl));

            using UnityWebRequest request = new UnityWebRequest(BackgroundRemoveApiEndpoint, UnityWebRequest.kHttpVerbPOST);
            request.uploadHandler = new UploadHandlerRaw(bodyBytes);
            request.downloadHandler = new DownloadHandlerBuffer();
            request.timeout = 120;
            request.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            request.SetRequestHeader("x-freepik-api-key", apiKey);

            await SendRequestAsync(request);

            if (HasRequestError(request))
            {
                string responseText = GetSafeResponseText(request);
                throw new InvalidOperationException(
                    string.IsNullOrWhiteSpace(responseText)
                        ? $"Freepik remove background baþarýsýz: {request.responseCode} - {request.error}"
                        : $"Freepik remove background baþarýsýz: {request.responseCode} - {request.error} | {responseText}");
            }

            FreepikRemoveBackgroundResponse response;
            try
            {
                response = JsonUtility.FromJson<FreepikRemoveBackgroundResponse>(request.downloadHandler.text);
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException("Freepik response parse edilemedi: " + ex.Message, ex);
            }

            if (response == null)
            {
                throw new InvalidOperationException("Freepik boþ response döndü.");
            }

            return response;
        }

        private async Task<Texture2D> DownloadTextureFromUrlAsync(string url)
        {
            string finalUrl = EnsureHttpsUrl(url);

            using UnityWebRequest request = UnityWebRequestTexture.GetTexture(finalUrl, false);
            request.timeout = 120;

            await SendRequestAsync(request);

            if (HasRequestError(request))
            {
                string responseText = GetSafeResponseText(request);
                throw new InvalidOperationException(
                    string.IsNullOrWhiteSpace(responseText)
                        ? $"Sonuç görseli indirilemedi: {request.responseCode} - {request.error}"
                        : $"Sonuç görseli indirilemedi: {request.responseCode} - {request.error} | {responseText}");
            }

            Texture2D texture = DownloadHandlerTexture.GetContent(request);
            if (texture == null)
            {
                return null;
            }

            return CreateReadableCopy(texture);
        }

        private static string GetBestFreepikBackgroundRemovedImageUrl(FreepikRemoveBackgroundResponse response)
        {
            if (response == null)
            {
                return string.Empty;
            }

            if (!string.IsNullOrWhiteSpace(response.url))
            {
                return EnsureHttpsUrl(response.url);
            }

            if (!string.IsNullOrWhiteSpace(response.high_resolution))
            {
                return EnsureHttpsUrl(response.high_resolution);
            }

            if (!string.IsNullOrWhiteSpace(response.preview))
            {
                return EnsureHttpsUrl(response.preview);
            }

            if (!string.IsNullOrWhiteSpace(response.original))
            {
                return EnsureHttpsUrl(response.original);
            }

            return string.Empty;
        }

        private static bool HasRequestError(UnityWebRequest request)
        {
#if UNITY_2020_1_OR_NEWER
            return request.result != UnityWebRequest.Result.Success;
#else
    return request.isNetworkError || request.isHttpError;
#endif
        }

        private static void DestroyTextures(params Texture2D[] textures)
        {
            HashSet<int> destroyed = new HashSet<int>();

            for (int i = 0; i < textures.Length; i++)
            {
                Texture2D texture = textures[i];
                if (texture == null)
                {
                    continue;
                }

                int instanceId = texture.GetInstanceID();
                if (!destroyed.Add(instanceId))
                {
                    continue;
                }

                DestroyImmediate(texture);
            }
        }
    }
}
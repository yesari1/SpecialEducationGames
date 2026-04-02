using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using UnityEditor;
using UnityEngine;
using UnityEngine.Networking;

namespace SpecialEducationGames
{
    public partial class FlaticonIconBrowserWindow
    {
        private const string ImageApiUrl = "https://api.freepik.com/v1/resources";
        private const string ImageDownloadApiUrlFormat = "https://api.freepik.com/v1/resources/{0}/download";

        private const string ShowImageFiltersEditorPref = "SEG_FlatImage_ShowFilters";
        private const string ImagePerPageEditorPref = "SEG_FlatImage_PerPage";
        private const string ImageAutoProcessDownloadsEditorPref = "SEG_FlatImage_AutoProcessDownloads";
        private const string ImageResizeProcessedEditorPref = "SEG_FlatImage_ResizeProcessed";
        private const string ImageProcessedWidthEditorPref = "SEG_FlatImage_ProcessedWidth";
        private const string ImageProcessedHeightEditorPref = "SEG_FlatImage_ProcessedHeight";
        private const string ImageKeepAspectEditorPref = "SEG_FlatImage_KeepAspect";
        private const string ImageTrimTransparentBoundsEditorPref = "SEG_FlatImage_TrimTransparentBounds";
        private const string ImageRemoveNearWhiteEditorPref = "SEG_FlatImage_RemoveNearWhite";
        private const string ImageWhiteThresholdEditorPref = "SEG_FlatImage_WhiteThreshold";
        private const string ImageWhiteSoftnessEditorPref = "SEG_FlatImage_WhiteSoftness";
        private const string ImagePsdLayerModeEditorPref = "SEG_FlatImage_PsdLayerMode";

        private const string ImageAiGeneratedFilterModeEditorPref = "SEG_FlatImage_AiGeneratedFilterMode";

        private enum ImageAiGeneratedFilterMode
        {
            All = 0,
            Exclude = 1,
            Only = 2
        }

        private static readonly string[] ImageAiGeneratedFilterLabels =
        {
    "All Images",
    "Exclude AI-Generated",
    "Only AI-Generated"
};

        private static readonly string[] ImageColorOptions =
        {
            AllFilterValue,
            "black",
            "blue",
            "gray",
            "green",
            "orange",
            "red",
            "white",
            "yellow",
            "purple",
            "cyan",
            "pink"
        };

        private static readonly string[] ImagePsdTypeOptions =
        {
            AllFilterValue,
            "jpg",
            "psd",
            "png"
        };

        private static readonly string[] ImageContentTypeOptions =
        {
            "photo",
            "psd",
            "vector"
        };

        private static readonly string[] ImageLicenseOptions =
        {
            "freemium",
            "premium"
        };

        private static readonly string[] ImagePsdLayerModeLabels =
        {
            "Flattened PSD",
            "Background Layer Hariç Birleþtir",
            "Her Layer'ý Ayrý PNG Export Et"
        };

        private string _imageSearchTerm = string.Empty;
        private int _imagePage = 1;
        private int _imagePerPage = 24;

        private bool _showImageFilters = true;
        private string _imageSelectedColor = AllFilterValue;
        private string _imageSelectedPsdType = AllFilterValue;

        private bool _imageAutoProcessDownloads = true;
        private bool _imageResizeProcessedImages = true;
        private int _imageProcessedWidth = 256;
        private int _imageProcessedHeight = 256;
        private bool _imageKeepAspect = true;
        private bool _imageTrimTransparentBounds = true;
        private bool _imageRemoveNearWhiteFromJpg = true;
        private float _imageWhiteThreshold = 0.94f;
        private float _imageWhiteSoftness = 0.04f;
        private PsdLayerExportMode _imagePsdLayerMode = PsdLayerExportMode.CompositeWithoutBackground;

        private ImageAiGeneratedFilterMode _imageAiGeneratedFilterMode = ImageAiGeneratedFilterMode.All;

        private readonly HashSet<string> _imageSelectedContentTypes = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        private readonly HashSet<string> _imageSelectedLicenses = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        private Vector2 _imageScrollPosition;

        private bool _isImageSearching;
        private bool _isImageSaving;
        private string _imageStatusMessage = string.Empty;
        private string _lastImageRawResponse = string.Empty;

        private ImageResourcePaginationData _imagePagination;
        private readonly List<ImageResourceViewModel> _imageResults = new List<ImageResourceViewModel>();

        private sealed class DownloadedImageFileResult
        {
            public bool Success;
            public string FilePath;
            public string ErrorMessage;
        }

        private sealed class ImageSaveResult
        {
            public bool RawSaved;
            public bool ProcessedCreated;
            public int ProcessedCount;
            public string SavedFilePath;
            public string ProcessedFilePath;
            public string ErrorMessage;
        }

        private void OnEnableImageBrowserTab()
        {
            _showImageFilters = EditorPrefs.GetBool(ShowImageFiltersEditorPref, true);
            _imagePerPage = EditorPrefs.GetInt(ImagePerPageEditorPref, 24);

            if (Array.IndexOf(PerPageOptions, _imagePerPage) < 0)
            {
                _imagePerPage = 24;
            }

            _imageAutoProcessDownloads = EditorPrefs.GetBool(ImageAutoProcessDownloadsEditorPref, true);
            _imageResizeProcessedImages = EditorPrefs.GetBool(ImageResizeProcessedEditorPref, true);
            _imageProcessedWidth = Mathf.Max(1, EditorPrefs.GetInt(ImageProcessedWidthEditorPref, 256));
            _imageProcessedHeight = Mathf.Max(1, EditorPrefs.GetInt(ImageProcessedHeightEditorPref, 256));
            _imageKeepAspect = EditorPrefs.GetBool(ImageKeepAspectEditorPref, true);
            _imageTrimTransparentBounds = EditorPrefs.GetBool(ImageTrimTransparentBoundsEditorPref, true);
            _imageRemoveNearWhiteFromJpg = EditorPrefs.GetBool(ImageRemoveNearWhiteEditorPref, true);
            _imageWhiteThreshold = Mathf.Clamp01(EditorPrefs.GetFloat(ImageWhiteThresholdEditorPref, 0.94f));
            _imageWhiteSoftness = Mathf.Clamp(EditorPrefs.GetFloat(ImageWhiteSoftnessEditorPref, 0.04f), 0f, 0.20f);
            _imagePsdLayerMode = (PsdLayerExportMode)EditorPrefs.GetInt(ImagePsdLayerModeEditorPref, (int)PsdLayerExportMode.CompositeWithoutBackground);

            _imageAiGeneratedFilterMode = (ImageAiGeneratedFilterMode)EditorPrefs.GetInt(
                ImageAiGeneratedFilterModeEditorPref,
                (int)ImageAiGeneratedFilterMode.All);
        }

        private void OnDisableImageBrowserTab()
        {
            EditorPrefs.SetBool(ShowImageFiltersEditorPref, _showImageFilters);
            EditorPrefs.SetInt(ImagePerPageEditorPref, _imagePerPage);

            EditorPrefs.SetBool(ImageAutoProcessDownloadsEditorPref, _imageAutoProcessDownloads);
            EditorPrefs.SetBool(ImageResizeProcessedEditorPref, _imageResizeProcessedImages);
            EditorPrefs.SetInt(ImageProcessedWidthEditorPref, Mathf.Max(1, _imageProcessedWidth));
            EditorPrefs.SetInt(ImageProcessedHeightEditorPref, Mathf.Max(1, _imageProcessedHeight));
            EditorPrefs.SetBool(ImageKeepAspectEditorPref, _imageKeepAspect);
            EditorPrefs.SetBool(ImageTrimTransparentBoundsEditorPref, _imageTrimTransparentBounds);
            EditorPrefs.SetBool(ImageRemoveNearWhiteEditorPref, _imageRemoveNearWhiteFromJpg);
            EditorPrefs.SetFloat(ImageWhiteThresholdEditorPref, Mathf.Clamp01(_imageWhiteThreshold));
            EditorPrefs.SetFloat(ImageWhiteSoftnessEditorPref, Mathf.Clamp(_imageWhiteSoftness, 0f, 0.20f));
            EditorPrefs.SetInt(ImagePsdLayerModeEditorPref, (int)_imagePsdLayerMode);
            EditorPrefs.SetInt(ImageAiGeneratedFilterModeEditorPref, (int)_imageAiGeneratedFilterMode);

            ClearImageResults();
        }

        private void DrawImageBrowserTab()
        {
            DrawImageSearchSection();
            GUILayout.Space(SectionSpacing);

            DrawImageSettingsSection();
            GUILayout.Space(SectionSpacing);

            DrawImageFiltersSection();
            GUILayout.Space(SectionSpacing);

            DrawImageActionsSection();
            GUILayout.Space(SectionSpacing);

            DrawImageResultsSection();
        }

        private void DrawImageSearchSection()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                GUILayout.Space(8f);

                using (new EditorGUILayout.HorizontalScope())
                {
                    GUI.SetNextControlName("FreepikImageSearchField");
                    _imageSearchTerm = EditorGUILayout.TextField(_imageSearchTerm, _searchFieldStyle, GUILayout.ExpandWidth(true));

                    bool canSearch =
                        !_isImageSearching &&
                        !_isImageSaving &&
                        !string.IsNullOrWhiteSpace(_imageSearchTerm) &&
                        !string.IsNullOrWhiteSpace(_apiKey);

                    using (new EditorGUI.DisabledScope(!canSearch))
                    {
                        if (GUILayout.Button("Search", GUILayout.Width(120f), GUILayout.Height(34f)))
                        {
                            StartFreshImageSearch();
                        }
                    }
                }

                GUILayout.Space(8f);
            }

            if (Event.current.type == EventType.KeyDown &&
                Event.current.keyCode == KeyCode.Return &&
                GUI.GetNameOfFocusedControl() == "FreepikImageSearchField" &&
                !_isImageSearching &&
                !_isImageSaving &&
                !string.IsNullOrWhiteSpace(_imageSearchTerm) &&
                !string.IsNullOrWhiteSpace(_apiKey))
            {
                StartFreshImageSearch();
                Event.current.Use();
            }
        }

        private void DrawImageSettingsSection()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                EditorGUILayout.LabelField("Image Browser Settings", _sectionTitleStyle);
                GUILayout.Space(4f);

                EditorGUI.BeginChangeCheck();
                _apiKey = EditorGUILayout.PasswordField("API Key", _apiKey);
                if (EditorGUI.EndChangeCheck())
                {
                    EditorPrefs.SetString(ApiKeyEditorPref, _apiKey ?? string.Empty);
                }

                _imagePerPage = EditorGUILayout.IntPopup("Per Page", _imagePerPage, PerPageLabels, PerPageOptions);

                GUILayout.Space(4f);

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

                GUILayout.Space(8f);
                EditorGUILayout.LabelField("Download Processing", _filterTitleStyle);

                _imageAutoProcessDownloads = EditorGUILayout.ToggleLeft("Ýndirilen dosyalarý otomatik iþle", _imageAutoProcessDownloads);

                using (new EditorGUI.DisabledScope(!_imageAutoProcessDownloads))
                {
                    _imagePsdLayerMode = (PsdLayerExportMode)EditorGUILayout.Popup(
                        "PSD Export Mode",
                        (int)_imagePsdLayerMode,
                        ImagePsdLayerModeLabels);

                    _imageResizeProcessedImages = EditorGUILayout.ToggleLeft("PNG çýktýyý yeniden boyutlandýr", _imageResizeProcessedImages);

                    using (new EditorGUI.DisabledScope(!_imageResizeProcessedImages))
                    {
                        using (new EditorGUILayout.HorizontalScope())
                        {
                            _imageProcessedWidth = Mathf.Max(1, EditorGUILayout.IntField("Width", _imageProcessedWidth));
                            GUILayout.Space(8f);
                            _imageProcessedHeight = Mathf.Max(1, EditorGUILayout.IntField("Height", _imageProcessedHeight));
                        }

                        _imageKeepAspect = EditorGUILayout.ToggleLeft("Keep Aspect Ratio ve transparan canvas içine ortala", _imageKeepAspect);
                    }

                    _imageTrimTransparentBounds = EditorGUILayout.ToggleLeft("Transparan boþluklarý trim et", _imageTrimTransparentBounds);
                    _imageRemoveNearWhiteFromJpg = EditorGUILayout.ToggleLeft("JPG/JPEG için near-white arka planý silmeye çalýþ", _imageRemoveNearWhiteFromJpg);

                    using (new EditorGUI.DisabledScope(!_imageRemoveNearWhiteFromJpg))
                    {
                        _imageWhiteThreshold = EditorGUILayout.Slider("White Threshold", _imageWhiteThreshold, 0.80f, 1.00f);
                        _imageWhiteSoftness = EditorGUILayout.Slider("White Softness", _imageWhiteSoftness, 0.00f, 0.20f);
                    }
                }

                GUILayout.Space(6f);
                EditorGUILayout.HelpBox(
                    "Her indirme arama terimine göre ayrý klasöre gider. Örn: dog, dog (1). ZIP dosyalarý ayný klasörde extract edilir.",
                    MessageType.None);

                if (string.IsNullOrWhiteSpace(_apiKey))
                {
                    EditorGUILayout.HelpBox("Arama yapabilmek için API key gir.", MessageType.Warning);
                }
            }
        }

        private void DrawImageFiltersSection()
        {
            _showImageFilters = EditorGUILayout.BeginFoldoutHeaderGroup(_showImageFilters, "Image Filters");
            if (_showImageFilters)
            {
                using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
                {
                    EditorGUILayout.LabelField("Freepik resource filtreleri.", EditorStyles.wordWrappedMiniLabel);
                    GUILayout.Space(8f);

                    float totalWidth = Mathf.Max(300f, position.width - (OuterPadding * 2f) - 32f);
                    float columnWidth = (totalWidth - FilterColumnSpacing) * 0.5f;

                    using (new EditorGUILayout.HorizontalScope())
                    {
                        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox, GUILayout.Width(columnWidth)))
                        {
                            DrawSingleSelectFilterPanel("Color", ImageColorOptions, ref _imageSelectedColor, columnWidth - 20f);
                        }

                        GUILayout.Space(FilterColumnSpacing);

                        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox, GUILayout.Width(columnWidth)))
                        {
                            DrawSingleSelectFilterPanel("PSD Type", ImagePsdTypeOptions, ref _imageSelectedPsdType, columnWidth - 20f);

                            GUILayout.Space(8f);

                            _imageAiGeneratedFilterMode = (ImageAiGeneratedFilterMode)EditorGUILayout.Popup(
                                "AI Generated",
                                (int)_imageAiGeneratedFilterMode,
                                ImageAiGeneratedFilterLabels);
                        }
                    }

                    GUILayout.Space(8f);

                    using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
                    {
                        DrawMultiSelectFilterPanel("Content Type", ImageContentTypeOptions, _imageSelectedContentTypes, totalWidth - 20f);
                    }

                    GUILayout.Space(8f);

                    using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
                    {
                        DrawMultiSelectFilterPanel("License", ImageLicenseOptions, _imageSelectedLicenses, totalWidth - 20f);
                    }
                }
            }

            EditorGUILayout.EndFoldoutHeaderGroup();
        }

        private void DrawImageActionsSection()
        {
            int selectedCount = GetSelectedImageCount();

            using (new EditorGUILayout.HorizontalScope(EditorStyles.helpBox))
            {
                using (new EditorGUI.DisabledScope(_imageResults.Count == 0 || _isImageSaving))
                {
                    if (GUILayout.Button("Select All", GUILayout.Width(100f)))
                    {
                        SetAllImageSelection(true);
                    }

                    if (GUILayout.Button("Clear Selection", GUILayout.Width(120f)))
                    {
                        SetAllImageSelection(false);
                    }
                }

                GUILayout.FlexibleSpace();

                using (new EditorGUI.DisabledScope(_isImageSaving || selectedCount == 0))
                {
                    if (GUILayout.Button($"Save Selected ({selectedCount})", GUILayout.Width(170f), GUILayout.Height(24f)))
                    {
                        SaveSelectedImagesAsync().Forget();
                    }
                }
            }
        }

        private void DrawImageResultsSection()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                EditorGUILayout.LabelField("Image Search Results", _sectionTitleStyle);

                if (!string.IsNullOrWhiteSpace(_imageStatusMessage))
                {
                    EditorGUILayout.HelpBox(_imageStatusMessage, MessageType.Info);
                }

                GUILayout.Space(4f);

                using (var scrollView = new EditorGUILayout.ScrollViewScope(_imageScrollPosition))
                {
                    _imageScrollPosition = scrollView.scrollPosition;

                    float viewWidth = Mathf.Max(1f, position.width - (OuterPadding * 2f) - 48f);
                    int columnCount = Mathf.Max(1, Mathf.FloorToInt(viewWidth / CardWidth));

                    int index = 0;
                    while (index < _imageResults.Count)
                    {
                        using (new EditorGUILayout.HorizontalScope())
                        {
                            for (int column = 0; column < columnCount && index < _imageResults.Count; column++, index++)
                            {
                                DrawImageCard(_imageResults[index]);
                            }

                            GUILayout.FlexibleSpace();
                        }

                        GUILayout.Space(8f);
                    }

                    if (_imageResults.Count == 0 && !_isImageSearching)
                    {
                        EditorGUILayout.HelpBox("Henüz sonuç yok. Yukarýdan arama yap.", MessageType.None);
                    }
                }

                GUILayout.Space(8f);
                DrawImagePaginationSection();
            }
        }

        private void DrawImagePaginationSection()
        {
            bool hasPagination = _imagePagination != null;
            int currentPage = hasPagination ? Mathf.Max(1, _imagePagination.current_page) : _imagePage;
            int lastPage = hasPagination ? Mathf.Max(1, _imagePagination.last_page) : 1;

            using (new EditorGUILayout.HorizontalScope(EditorStyles.helpBox))
            {
                using (new EditorGUI.DisabledScope(!hasPagination || _isImageSearching || _isImageSaving || currentPage <= 1))
                {
                    if (GUILayout.Button("First", GUILayout.Width(70f)))
                    {
                        ChangeImagePage(1);
                    }

                    if (GUILayout.Button("Previous", GUILayout.Width(90f)))
                    {
                        ChangeImagePage(currentPage - 1);
                    }
                }

                GUILayout.FlexibleSpace();

                if (hasPagination)
                {
                    GUILayout.Label($"Page {currentPage} / {lastPage}    Total: {_imagePagination.total}", _centeredInfoStyle);
                }
                else
                {
                    GUILayout.Label("Pagination bilgisi yok.", _centeredInfoStyle);
                }

                GUILayout.FlexibleSpace();

                using (new EditorGUI.DisabledScope(!hasPagination || _isImageSearching || _isImageSaving || currentPage >= lastPage))
                {
                    if (GUILayout.Button("Next", GUILayout.Width(70f)))
                    {
                        ChangeImagePage(currentPage + 1);
                    }

                    if (GUILayout.Button("Last", GUILayout.Width(70f)))
                    {
                        ChangeImagePage(lastPage);
                    }
                }
            }
        }

        private void DrawImageCard(ImageResourceViewModel item)
        {
            Rect cardRect = GUILayoutUtility.GetRect(CardWidth, CardHeight, GUILayout.Width(CardWidth), GUILayout.Height(CardHeight));
            GUI.Box(cardRect, GUIContent.none, EditorStyles.helpBox);

            if (item.IsSelected)
            {
                DrawBorder(cardRect, new Color(0.20f, 0.56f, 0.95f, 1f), 2f);
                EditorGUI.DrawRect(
                    new Rect(cardRect.x + 1f, cardRect.y + 1f, cardRect.width - 2f, cardRect.height - 2f),
                    new Color(0.20f, 0.56f, 0.95f, 0.06f));
            }

            Rect contentRect = new Rect(
                cardRect.x + CardInnerPadding,
                cardRect.y + CardInnerPadding,
                cardRect.width - (CardInnerPadding * 2f),
                cardRect.height - (CardInnerPadding * 2f));

            GUI.BeginGroup(contentRect);
            try
            {
                float y = 0f;

                Rect toggleRect = new Rect(0f, y, contentRect.width, 18f);
                item.IsSelected = EditorGUI.ToggleLeft(toggleRect, "Selected", item.IsSelected);
                y += 24f;

                Rect previewRect = new Rect(0f, y, contentRect.width, 150f);
                if (item.PreviewTexture != null)
                {
                    GUI.DrawTexture(previewRect, item.PreviewTexture, ScaleMode.ScaleToFit);
                }
                else
                {
                    EditorGUI.DrawRect(previewRect, new Color(0.18f, 0.18f, 0.18f));
                    GUI.Label(previewRect, item.IsLoadingPreview ? "Loading..." : "No Preview", GetCenteredMiniLabel());
                }

                if (GUI.Button(previewRect, GUIContent.none, GUIStyle.none))
                {
                    item.IsSelected = !item.IsSelected;
                    GUI.changed = true;
                }

                if (item.IsSelected)
                {
                    Rect selectedRect = new Rect(previewRect.x + 6f, previewRect.y + 6f, previewRect.width - 12f, 20f);
                    EditorGUI.DrawRect(selectedRect, new Color(0.19f, 0.56f, 0.95f, 0.9f));
                    GUI.Label(selectedRect, "SELECTED", _overlayLabelStyle);
                }

                y += 158f;

                Rect titleRect = new Rect(0f, y, contentRect.width, 34f);
                EditorGUI.LabelField(
                    titleRect,
                    string.IsNullOrWhiteSpace(item.Title) ? "(no title)" : item.Title,
                    _cardTitleStyle);
                y += 36f;

                Rect typeRect = new Rect(0f, y, contentRect.width, 18f);
                EditorGUI.LabelField(typeRect, $"Type: {ToDisplayLabel(item.ContentType)}", EditorStyles.miniLabel);
                y += 18f;

                Rect orientationRect = new Rect(0f, y, contentRect.width, 18f);
                EditorGUI.LabelField(orientationRect, $"Orientation: {ToDisplayLabel(item.Orientation)}", EditorStyles.miniLabel);
                y += 18f;

                Rect authorRect = new Rect(0f, y, contentRect.width, 18f);
                EditorGUI.LabelField(authorRect, $"Author: {item.AuthorName}", EditorStyles.miniLabel);
                y += 18f;

                Rect licenseRect = new Rect(0f, y, contentRect.width, 18f);
                EditorGUI.LabelField(licenseRect, $"License: {ToDisplayLabel(item.LicenseType)}", EditorStyles.miniLabel);

                if (!string.IsNullOrWhiteSpace(item.Error))
                {
                    Rect errorRect = new Rect(0f, contentRect.height - 54f, contentRect.width, 28f);
                    EditorGUI.HelpBox(errorRect, item.Error, MessageType.Warning);
                }

                using (new EditorGUI.DisabledScope(_isImageSaving || item.Id <= 0))
                {
                    string buttonLabel = item.IsDownloading ? "Downloading..." : "Download";
                    Rect buttonRect = new Rect(0f, contentRect.height - 24f, contentRect.width, 24f);
                    if (GUI.Button(buttonRect, buttonLabel))
                    {
                        SaveSingleImageAsync(item).Forget();
                    }
                }
            }
            finally
            {
                GUI.EndGroup();
            }
        }

        private void StartFreshImageSearch()
        {
            _imagePage = 1;
            SearchImagesAsync().Forget();
        }

        private void ChangeImagePage(int targetPage)
        {
            int lastPage = _imagePagination != null ? Mathf.Max(1, _imagePagination.last_page) : 1;
            int clampedPage = Mathf.Clamp(targetPage, 1, lastPage);

            if (clampedPage == _imagePage)
            {
                return;
            }

            _imagePage = clampedPage;
            SearchImagesAsync().Forget();
        }

        private async Task SearchImagesAsync()
        {
            _isImageSearching = true;
            _imageStatusMessage = "Searching images...";
            Repaint();

            ClearImageResults();

            string url = EnsureHttpsUrl(BuildImageSearchUrl());

            using UnityWebRequest request = UnityWebRequest.Get(url);
            request.SetRequestHeader("x-freepik-api-key", _apiKey);

            await SendRequestAsync(request);

#if UNITY_2020_1_OR_NEWER
            bool hasError = request.result != UnityWebRequest.Result.Success;
#else
            bool hasError = request.isNetworkError || request.isHttpError;
#endif

            if (hasError)
            {
                _imageStatusMessage = $"Search failed: {request.responseCode} - {request.error}";
                _imagePagination = null;
                _isImageSearching = false;
                Repaint();
                return;
            }

            _lastImageRawResponse = request.downloadHandler.text;

            ImageResourceResponse response;
            try
            {
                response = JsonUtility.FromJson<ImageResourceResponse>(_lastImageRawResponse);
            }
            catch (Exception ex)
            {
                _imageStatusMessage = $"JSON parse error: {ex.Message}";
                _imagePagination = null;
                _isImageSearching = false;
                Debug.LogWarning(_lastImageRawResponse);
                Repaint();
                return;
            }

            if (response == null || response.data == null)
            {
                _imageStatusMessage = "Sonuç parse edilemedi. Ham response Console'a yazdýrýldý.";
                _imagePagination = null;
                Debug.LogWarning(_lastImageRawResponse);
                _isImageSearching = false;
                Repaint();
                return;
            }

            _imagePagination = response.meta;
            if (_imagePagination != null)
            {
                _imagePage = Mathf.Max(1, _imagePagination.current_page);
            }

            for (int i = 0; i < response.data.Length; i++)
            {
                ImageResourceData data = response.data[i];
                if (data == null)
                {
                    continue;
                }

                string previewUrl = GetImagePreviewUrl(data);
                string licenseType = GetPrimaryLicenseType(data.licenses);

                ImageResourceViewModel item = new ImageResourceViewModel
                {
                    Id = data.id,
                    Title = data.title,
                    ResourceUrl = data.url,
                    Filename = data.filename,
                    ContentType = data.image != null ? data.image.type : string.Empty,
                    Orientation = data.image != null ? data.image.orientation : string.Empty,
                    PreviewUrl = previewUrl,
                    LicenseType = licenseType,
                    AuthorName = data.author != null ? data.author.name : string.Empty,
                    IsSelected = false,
                    IsLoadingPreview = !string.IsNullOrWhiteSpace(previewUrl)
                };

                _imageResults.Add(item);
            }

            _imageStatusMessage = $"{_imageResults.Count} sonuç bulundu.";
            _isImageSearching = false;
            Repaint();

            for (int i = 0; i < _imageResults.Count; i++)
            {
                if (!string.IsNullOrWhiteSpace(_imageResults[i].PreviewUrl))
                {
                    LoadImagePreviewAsync(_imageResults[i]).Forget();
                }
            }
        }

        private string BuildImageSearchUrl()
        {
            List<string> queryParts = new List<string>
    {
        $"order={UnityWebRequest.EscapeURL("relevance")}",
        $"term={UnityWebRequest.EscapeURL(_imageSearchTerm)}",
        $"page={_imagePage}",
        $"per_page={_imagePerPage}"
    };

            AddFilterQuery(queryParts, "filters[color]", _imageSelectedColor);
            AddFilterQuery(queryParts, "filters[psd][type]", _imageSelectedPsdType);

            AddFlagFilterQuery(queryParts, "filters[content_type][photo]", _imageSelectedContentTypes.Contains("photo"));
            AddFlagFilterQuery(queryParts, "filters[content_type][psd]", _imageSelectedContentTypes.Contains("psd"));
            AddFlagFilterQuery(queryParts, "filters[content_type][vector]", _imageSelectedContentTypes.Contains("vector"));

            AddFlagFilterQuery(queryParts, "filters[license][freemium]", _imageSelectedLicenses.Contains("freemium"));
            AddFlagFilterQuery(queryParts, "filters[license][premium]", _imageSelectedLicenses.Contains("premium"));

            switch (_imageAiGeneratedFilterMode)
            {
                case ImageAiGeneratedFilterMode.Exclude:
                    AddFlagFilterQuery(queryParts, "filters[ai-generated][excluded]", true);
                    break;

                case ImageAiGeneratedFilterMode.Only:
                    AddFlagFilterQuery(queryParts, "filters[ai-generated][only]", true);
                    break;
            }

            return $"{ImageApiUrl}?{string.Join("&", queryParts)}";
        }

        private static void AddFlagFilterQuery(List<string> queryParts, string key, bool enabled)
        {
            if (!enabled)
            {
                return;
            }

            queryParts.Add($"{UnityWebRequest.EscapeURL(key)}=1");
        }

        private async Task LoadImagePreviewAsync(ImageResourceViewModel item)
        {
            if (item == null || string.IsNullOrWhiteSpace(item.PreviewUrl))
            {
                return;
            }

            item.IsLoadingPreview = true;
            item.Error = null;

            string lastError = "Preview load failed";

            for (int attempt = 1; attempt <= PreviewMaxAttempts; attempt++)
            {
                string previewUrl = EnsureHttpsUrl(item.PreviewUrl);
                using UnityWebRequest request = UnityWebRequestTexture.GetTexture(previewUrl);
                request.timeout = 15;

                await SendRequestAsync(request);

#if UNITY_2020_1_OR_NEWER
                bool hasError = request.result != UnityWebRequest.Result.Success;
#else
                bool hasError = request.isNetworkError || request.isHttpError;
#endif

                if (!hasError)
                {
                    Texture2D texture = DownloadHandlerTexture.GetContent(request);
                    item.PreviewTexture = texture;
                    item.IsLoadingPreview = false;
                    item.Error = null;
                    Repaint();
                    return;
                }

                lastError = $"Preview load failed: {request.responseCode} - {request.error}";

                if (attempt < PreviewMaxAttempts)
                {
                    await Task.Delay(PreviewRetryDelayMs * attempt);
                }
            }

            item.IsLoadingPreview = false;
            item.Error = lastError;
            Repaint();
        }

        private async Task SaveSingleImageAsync(ImageResourceViewModel item)
        {
            if (_isImageSaving)
            {
                return;
            }

            if (!TryPrepareOutputFolder(out string outputRootFolderPath))
            {
                _imageStatusMessage = "Geçerli bir klasör seç.";
                Repaint();
                return;
            }

            string sessionFolderPath = CreateUniqueSearchDownloadFolder(outputRootFolderPath, _imageSearchTerm);

            _isImageSaving = true;
            item.IsDownloading = true;
            item.Error = null;
            _imageStatusMessage = $"Ýndiriliyor: {GetImageDisplayName(item)}";
            Repaint();

            ImageSaveResult saveResult = await SaveImageToFolderAsync(item, sessionFolderPath);

            item.IsDownloading = false;
            _isImageSaving = false;

            if (saveResult.RawSaved)
            {
                if (IsPathInsideProject(outputRootFolderPath))
                {
                    AssetDatabase.Refresh();
                }

                if (saveResult.ProcessedCreated)
                {
                    _imageStatusMessage = $"{Path.GetFileName(sessionFolderPath)} klasörüne kaydedildi. {saveResult.ProcessedCount} PNG üretildi.";
                }
                else if (!string.IsNullOrWhiteSpace(saveResult.ErrorMessage))
                {
                    _imageStatusMessage = $"Ham dosya kaydedildi fakat iþleme baþarýsýz: {saveResult.ErrorMessage}";
                }
                else
                {
                    _imageStatusMessage = $"{Path.GetFileName(sessionFolderPath)} klasörüne kaydedildi.";
                }
            }
            else
            {
                item.Error = saveResult.ErrorMessage;
                _imageStatusMessage = string.IsNullOrWhiteSpace(saveResult.ErrorMessage)
                    ? $"Kaydedilemedi: {GetImageDisplayName(item)}"
                    : saveResult.ErrorMessage;
            }

            Repaint();
        }

        private async Task SaveSelectedImagesAsync()
        {
            if (!TryPrepareOutputFolder(out string outputRootFolderPath))
            {
                _imageStatusMessage = "Geçerli bir klasör seç.";
                Repaint();
                return;
            }

            string sessionFolderPath = CreateUniqueSearchDownloadFolder(outputRootFolderPath, _imageSearchTerm);

            _isImageSaving = true;
            _imageStatusMessage = "Saving selected images...";
            Repaint();

            int savedCount = 0;
            int processedCount = 0;

            for (int i = 0; i < _imageResults.Count; i++)
            {
                ImageResourceViewModel item = _imageResults[i];
                if (!item.IsSelected || item.Id <= 0)
                {
                    continue;
                }

                item.IsDownloading = true;
                item.Error = null;
                Repaint();

                ImageSaveResult saveResult = await SaveImageToFolderAsync(item, sessionFolderPath);
                if (saveResult.RawSaved)
                {
                    savedCount++;
                }

                processedCount += Mathf.Max(0, saveResult.ProcessedCount);

                item.IsDownloading = false;
                Repaint();
            }

            if (IsPathInsideProject(outputRootFolderPath))
            {
                AssetDatabase.Refresh();
            }

            _imageStatusMessage = $"{Path.GetFileName(sessionFolderPath)} klasörüne {savedCount} dosya kaydedildi, {processedCount} iþlenmiþ PNG üretildi.";
            _isImageSaving = false;
            Repaint();
        }

        private async Task<ImageSaveResult> SaveImageToFolderAsync(ImageResourceViewModel item, string targetFolderPath)
        {
            DownloadedImageFileResult downloadResult = await TryDownloadImageResourceAsync(item, targetFolderPath);
            if (!downloadResult.Success)
            {
                return new ImageSaveResult
                {
                    RawSaved = false,
                    ErrorMessage = downloadResult.ErrorMessage
                };
            }

            item.DownloadedFilePath = downloadResult.FilePath;
            item.ProcessedFilePath = string.Empty;

            ImageSaveResult saveResult = new ImageSaveResult
            {
                RawSaved = true,
                SavedFilePath = downloadResult.FilePath
            };

            if (!ShouldCreateProcessedOutputForDownloadedFile(downloadResult.FilePath))
            {
                item.Error = null;
                return saveResult;
            }

            bool processed = TryProcessInputFileToPng(
                downloadResult.FilePath,
                targetFolderPath,
                Path.GetFileNameWithoutExtension(downloadResult.FilePath),
                CreateCurrentImageProcessingOptions(),
                out string processedFilePath,
                out int processedCount,
                out string processingError);

            if (processed)
            {
                saveResult.ProcessedCreated = processedCount > 0;
                saveResult.ProcessedCount = processedCount;
                saveResult.ProcessedFilePath = processedFilePath;
                item.ProcessedFilePath = processedFilePath;
                item.Error = null;
            }
            else
            {
                saveResult.ErrorMessage = processingError;
                item.Error = processingError;
            }

            return saveResult;
        }

        private ImageProcessingOptions CreateCurrentImageProcessingOptions()
        {
            return new ImageProcessingOptions
            {
                ResizeOutput = _imageResizeProcessedImages,
                TargetWidth = Mathf.Max(1, _imageProcessedWidth),
                TargetHeight = Mathf.Max(1, _imageProcessedHeight),
                KeepAspect = _imageKeepAspect,
                TrimTransparentBounds = _imageTrimTransparentBounds,
                RemoveNearWhiteFromJpg = _imageRemoveNearWhiteFromJpg,
                WhiteThreshold = _imageWhiteThreshold,
                WhiteSoftness = _imageWhiteSoftness,
                PsdLayerMode = _imagePsdLayerMode
            };
        }

        private bool ShouldCreateProcessedOutputForDownloadedFile(string filePath)
        {
            if (!_imageAutoProcessDownloads || string.IsNullOrWhiteSpace(filePath))
            {
                return false;
            }

            string extension = Path.GetExtension(filePath).ToLowerInvariant();

            if (extension == ".zip" || extension == ".psd")
            {
                return true;
            }

            if (extension == ".jpg" || extension == ".jpeg")
            {
                return _imageResizeProcessedImages || _imageTrimTransparentBounds || _imageRemoveNearWhiteFromJpg;
            }

            if (extension == ".png")
            {
                return _imageResizeProcessedImages || _imageTrimTransparentBounds;
            }

            return false;
        }

        private async Task<DownloadedImageFileResult> TryDownloadImageResourceAsync(ImageResourceViewModel item, string targetFolderPath)
        {
            string downloadUrl = EnsureHttpsUrl(string.Format(ImageDownloadApiUrlFormat, item.Id));

            using UnityWebRequest request = UnityWebRequest.Get(downloadUrl);
            request.SetRequestHeader("x-freepik-api-key", _apiKey);
            request.SetRequestHeader("Accept", "application/json");
            request.timeout = 30;

            await SendRequestAsync(request);

#if UNITY_2020_1_OR_NEWER
            bool hasError = request.result != UnityWebRequest.Result.Success;
#else
            bool hasError = request.isNetworkError || request.isHttpError;
#endif

            if (hasError)
            {
                string responseText = GetSafeResponseText(request);
                string errorMessage = string.IsNullOrWhiteSpace(responseText)
                    ? $"Download endpoint failed: {request.responseCode} - {request.error}"
                    : $"Download endpoint failed: {request.responseCode} - {request.error} | {responseText}";

                Debug.LogWarning("Download URL: " + downloadUrl + "\n" + errorMessage);

                return new DownloadedImageFileResult
                {
                    Success = false,
                    ErrorMessage = errorMessage
                };
            }

            string contentType = request.GetResponseHeader("Content-Type") ?? string.Empty;
            byte[] bytes = request.downloadHandler.data;
            string text = request.downloadHandler.text;

            bool looksLikeJson =
                contentType.IndexOf("application/json", StringComparison.OrdinalIgnoreCase) >= 0 ||
                (!string.IsNullOrWhiteSpace(text) && text.TrimStart().StartsWith("{", StringComparison.Ordinal));

            if (looksLikeJson)
            {
                ImageResourceDownloadEnvelope envelope = null;

                try
                {
                    envelope = JsonUtility.FromJson<ImageResourceDownloadEnvelope>(text);
                }
                catch
                {
                    envelope = null;
                }

                string resolvedUrl = envelope != null
                    ? !string.IsNullOrWhiteSpace(envelope.url)
                        ? envelope.url
                        : envelope.data != null ? envelope.data.url : string.Empty
                    : string.Empty;

                if (string.IsNullOrWhiteSpace(resolvedUrl))
                {
                    string errorMessage = "Download endpoint URL dönmedi.";
                    Debug.LogWarning(errorMessage + "\nRaw: " + text);

                    return new DownloadedImageFileResult
                    {
                        Success = false,
                        ErrorMessage = errorMessage
                    };
                }

                resolvedUrl = EnsureHttpsUrl(resolvedUrl);

                using UnityWebRequest resolvedRequest = UnityWebRequest.Get(resolvedUrl);
                resolvedRequest.SetRequestHeader("x-freepik-api-key", _apiKey);
                resolvedRequest.SetRequestHeader("Accept", "*/*");
                resolvedRequest.timeout = 60;

                await SendRequestAsync(resolvedRequest);

#if UNITY_2020_1_OR_NEWER
                bool resolvedHasError = resolvedRequest.result != UnityWebRequest.Result.Success;
#else
                bool resolvedHasError = resolvedRequest.isNetworkError || resolvedRequest.isHttpError;
#endif

                if (resolvedHasError)
                {
                    string responseText = GetSafeResponseText(resolvedRequest);
                    string errorMessage = string.IsNullOrWhiteSpace(responseText)
                        ? $"Resolved download failed: {resolvedRequest.responseCode} - {resolvedRequest.error}"
                        : $"Resolved download failed: {resolvedRequest.responseCode} - {resolvedRequest.error} | {responseText}";

                    Debug.LogWarning("Resolved URL: " + resolvedUrl + "\n" + errorMessage);

                    return new DownloadedImageFileResult
                    {
                        Success = false,
                        ErrorMessage = errorMessage
                    };
                }

                byte[] resolvedBytes = resolvedRequest.downloadHandler.data;
                if (resolvedBytes == null || resolvedBytes.Length == 0)
                {
                    return new DownloadedImageFileResult
                    {
                        Success = false,
                        ErrorMessage = "Downloaded file boþ geldi."
                    };
                }

                string suggestedFileName = GetDownloadEnvelopeFileName(envelope, item);
                string extensionFromResolvedUrl = GetExtensionFromUrl(resolvedUrl);

                if (string.IsNullOrWhiteSpace(extensionFromResolvedUrl))
                {
                    extensionFromResolvedUrl = GetImageDownloadExtension(
                        item,
                        resolvedRequest.GetResponseHeader("Content-Type") ?? string.Empty);
                }

                string filePathFromResolvedUrl = BuildUniqueImageFilePath(
                    targetFolderPath,
                    item,
                    extensionFromResolvedUrl,
                    suggestedFileName);

                File.WriteAllBytes(filePathFromResolvedUrl, resolvedBytes);

                return new DownloadedImageFileResult
                {
                    Success = true,
                    FilePath = filePathFromResolvedUrl
                };
            }

            if (bytes == null || bytes.Length == 0)
            {
                return new DownloadedImageFileResult
                {
                    Success = false,
                    ErrorMessage = "Download endpoint boþ veri döndü."
                };
            }

            string extension = GetImageDownloadExtension(item, contentType);
            string filePath = BuildUniqueImageFilePath(targetFolderPath, item, extension, item.Filename);
            File.WriteAllBytes(filePath, bytes);

            return new DownloadedImageFileResult
            {
                Success = true,
                FilePath = filePath
            };
        }

        private static string GetSafeResponseText(UnityWebRequest request)
        {
            if (request == null || request.downloadHandler == null)
            {
                return string.Empty;
            }

            try
            {
                string text = request.downloadHandler.text;
                if (string.IsNullOrWhiteSpace(text))
                {
                    return string.Empty;
                }

                return text.Length > 500 ? text.Substring(0, 500) : text;
            }
            catch
            {
                return string.Empty;
            }
        }

        private void ClearImageResults()
        {
            for (int i = 0; i < _imageResults.Count; i++)
            {
                if (_imageResults[i].PreviewTexture != null)
                {
                    DestroyImmediate(_imageResults[i].PreviewTexture);
                    _imageResults[i].PreviewTexture = null;
                }
            }

            _imageResults.Clear();
        }

        private int GetSelectedImageCount()
        {
            int count = 0;
            for (int i = 0; i < _imageResults.Count; i++)
            {
                if (_imageResults[i].IsSelected)
                {
                    count++;
                }
            }

            return count;
        }

        private void SetAllImageSelection(bool isSelected)
        {
            for (int i = 0; i < _imageResults.Count; i++)
            {
                _imageResults[i].IsSelected = isSelected;
            }
        }

        private string CreateUniqueSearchDownloadFolder(string outputRootFolderPath, string searchTerm)
        {
            string normalizedSearchTerm = SanitizeFolderNamePreserveSpaces(searchTerm);
            if (string.IsNullOrWhiteSpace(normalizedSearchTerm))
            {
                normalizedSearchTerm = "download";
            }

            string uniqueFolderPath = BuildUniqueDirectoryPath(outputRootFolderPath, normalizedSearchTerm);
            Directory.CreateDirectory(uniqueFolderPath);
            return uniqueFolderPath;
        }

        private static string BuildUniqueDirectoryPath(string parentFolderPath, string baseFolderName)
        {
            string safeBaseFolderName = SanitizeFolderNamePreserveSpaces(baseFolderName);
            if (string.IsNullOrWhiteSpace(safeBaseFolderName))
            {
                safeBaseFolderName = "download";
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

        private static string SanitizeFolderNamePreserveSpaces(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return string.Empty;
            }

            char[] invalidChars = Path.GetInvalidFileNameChars();
            for (int i = 0; i < invalidChars.Length; i++)
            {
                value = value.Replace(invalidChars[i], '_');
            }

            value = value.Trim().TrimEnd('.');
            return value;
        }

        private static string GetImagePreviewUrl(ImageResourceData data)
        {
            if (data == null || data.image == null || data.image.source == null)
            {
                return string.Empty;
            }

            return data.image.source.url ?? string.Empty;
        }

        private static string GetPrimaryLicenseType(ImageResourceLicense[] licenses)
        {
            if (licenses == null || licenses.Length == 0 || licenses[0] == null)
            {
                return string.Empty;
            }

            return licenses[0].type ?? string.Empty;
        }

        private static string GetImageDisplayName(ImageResourceViewModel item)
        {
            if (!string.IsNullOrWhiteSpace(item.Title))
            {
                return item.Title;
            }

            if (!string.IsNullOrWhiteSpace(item.Filename))
            {
                return item.Filename;
            }

            return $"resource_{item.Id}";
        }

        private static string BuildUniqueImageFilePath(string folderPath, ImageResourceViewModel item, string extension, string suggestedFileName)
        {
            string baseName;
            string finalExtension = extension;

            if (!string.IsNullOrWhiteSpace(suggestedFileName))
            {
                string fileNameWithoutExtension = Path.GetFileNameWithoutExtension(suggestedFileName);
                string suggestedExtension = Path.GetExtension(suggestedFileName);

                baseName = string.IsNullOrWhiteSpace(fileNameWithoutExtension)
                    ? $"resource_{item.Id}"
                    : fileNameWithoutExtension;

                if (string.IsNullOrWhiteSpace(finalExtension) && !string.IsNullOrWhiteSpace(suggestedExtension))
                {
                    finalExtension = suggestedExtension;
                }
            }
            else
            {
                string rawName = !string.IsNullOrWhiteSpace(item.Title) ? item.Title : item.Filename;
                baseName = string.IsNullOrWhiteSpace(rawName) ? $"resource_{item.Id}" : rawName;
            }

            baseName = SanitizeFileName(baseName);
            finalExtension = string.IsNullOrWhiteSpace(finalExtension) ? ".jpg" : finalExtension;

            string filePath = Path.Combine(folderPath, $"{baseName}_{item.Id}{finalExtension}");

            int counter = 1;
            while (File.Exists(filePath))
            {
                filePath = Path.Combine(folderPath, $"{baseName}_{item.Id}_{counter}{finalExtension}");
                counter++;
            }

            return filePath;
        }

        private static string GetDownloadEnvelopeFileName(ImageResourceDownloadEnvelope envelope, ImageResourceViewModel item)
        {
            if (envelope != null)
            {
                if (!string.IsNullOrWhiteSpace(envelope.filename))
                {
                    return envelope.filename;
                }

                if (envelope.data != null && !string.IsNullOrWhiteSpace(envelope.data.filename))
                {
                    return envelope.data.filename;
                }
            }

            return item != null ? item.Filename : string.Empty;
        }

        private static string GetImageDownloadExtension(ImageResourceViewModel item, string contentType)
        {
            if (!string.IsNullOrWhiteSpace(item.Filename))
            {
                string filenameExtension = Path.GetExtension(item.Filename);
                if (!string.IsNullOrWhiteSpace(filenameExtension))
                {
                    return filenameExtension;
                }
            }

            if (!string.IsNullOrWhiteSpace(contentType))
            {
                string normalized = contentType.Trim().ToLowerInvariant();

                if (normalized.Contains("zip"))
                {
                    return ".zip";
                }

                if (normalized.Contains("png"))
                {
                    return ".png";
                }

                if (normalized.Contains("jpeg") || normalized.Contains("jpg"))
                {
                    return ".jpg";
                }

                if (normalized.Contains("psd"))
                {
                    return ".psd";
                }

                if (normalized.Contains("svg"))
                {
                    return ".svg";
                }
            }

            return ".jpg";
        }

        [Serializable]
        private sealed class ImageResourceResponse
        {
            public ImageResourceData[] data;
            public ImageResourcePaginationData meta;
        }

        [Serializable]
        private sealed class ImageResourceData
        {
            public int id;
            public string title;
            public string url;
            public string filename;
            public ImageResourceLicense[] licenses;
            public ImageResourceImage image;
            public ImageResourceAuthor author;
        }

        [Serializable]
        private sealed class ImageResourceLicense
        {
            public string type;
            public string url;
        }

        [Serializable]
        private sealed class ImageResourceImage
        {
            public string type;
            public string orientation;
            public ImageResourceImageSource source;
        }

        [Serializable]
        private sealed class ImageResourceImageSource
        {
            public string url;
            public string key;
            public string size;
        }

        [Serializable]
        private sealed class ImageResourceAuthor
        {
            public int id;
            public string name;
            public string avatar;
            public string slug;
        }

        [Serializable]
        private sealed class ImageResourcePaginationData
        {
            public int current_page;
            public int last_page;
            public int per_page;
            public int total;
        }

        [Serializable]
        private sealed class ImageResourceDownloadEnvelope
        {
            public string url;
            public string filename;
            public ImageResourceDownloadData data;
        }

        [Serializable]
        private sealed class ImageResourceDownloadData
        {
            public string url;
            public string filename;
        }

        private sealed class ImageResourceViewModel
        {
            public int Id;
            public string Title;
            public string ResourceUrl;
            public string Filename;
            public string ContentType;
            public string Orientation;
            public string PreviewUrl;
            public string LicenseType;
            public string AuthorName;
            public bool IsSelected;
            public bool IsLoadingPreview;
            public bool IsDownloading;
            public string Error;
            public string DownloadedFilePath;
            public string ProcessedFilePath;
            public Texture2D PreviewTexture;
        }
    }
}
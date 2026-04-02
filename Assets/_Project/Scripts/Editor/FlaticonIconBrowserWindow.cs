using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using UnityEditor;
using UnityEngine;
using UnityEngine.Networking;

namespace SpecialEducationGames
{
    public partial class FlaticonIconBrowserWindow : EditorWindow
    {
        private const string WindowTitle = "Flaticon Browser";
        private const string ApiUrl = "https://api.freepik.com/v1/icons";
        private const string AllFilterValue = "all";

        private const string ApiKeyEditorPref = "SEG_FlatIcon_ApiKey";
        private const string OutputFolderEditorPref = "SEG_FlatIcon_OutputFolder";
        private const string ShowFiltersEditorPref = "SEG_FlatIcon_ShowFilters";

        private const float OuterPadding = 12f;
        private const float SectionSpacing = 10f;
        private const float FilterColumnSpacing = 8f;
        private const float CardWidth = 205f;
        private const float CardHeight = 355f;
        private const float CardInnerPadding = 8f;

        private static readonly int[] PerPageOptions = { 12, 24, 48, 96 };
        private static readonly string[] PerPageLabels = { "12", "24", "48", "96" };

        private static readonly int[] ThumbnailSizeOptions = { 64, 128, 256, 512 };
        private static readonly string[] ThumbnailSizeLabels = { "64", "128", "256", "512" };

        private static readonly string[] ColorOptions =
        {
            AllFilterValue,
            "gradient",
            "solid-black",
            "multicolor",
            "azure",
            "black",
            "blue",
            "chartreuse",
            "cyan",
            "gray",
            "green",
            "orange",
            "red",
            "rose",
            "spring-green",
            "violet",
            "white",
            "yellow"
        };

        private static readonly string[] ShapeOptions =
        {
            AllFilterValue,
            "outline",
            "fill",
            "lineal-color",
            "hand-drawn"
        };

        private static readonly string[] PeriodOptions =
        {
            AllFilterValue,
            "three-months",
            "six-months",
            "one-year"
        };

        private static readonly string[] FreeSvgOptions =
        {
            AllFilterValue,
            "free",
            "premium"
        };

        private static readonly string[] IconTypeOptions =
        {
            "standard",
            "animated",
            "sticker",
            "uicon"
        };

        private enum WindowTab
        {
            Browser,
            Outline
        }

        private WindowTab _activeTab = WindowTab.Browser;

        private string _apiKey;
        private string _searchTerm = string.Empty;
        private string _outputFolder = "Assets/_Project/DownloadedIcons";

        private int _page = 1;
        private int _perPage = 24;
        private int _thumbnailSize = 256;

        private bool _showFilters = true;

        private string _selectedColor = AllFilterValue;
        private string _selectedShape = AllFilterValue;
        private string _selectedPeriod = AllFilterValue;
        private string _selectedFreeSvg = AllFilterValue;
        private readonly HashSet<string> _selectedIconTypes = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        private Vector2 _scrollPosition;

        private bool _isSearching;
        private bool _isSaving;
        private string _statusMessage = string.Empty;
        private string _lastRawResponse = string.Empty;

        private PaginationData _pagination;
        private readonly List<IconViewModel> _results = new List<IconViewModel>();

        private GUIStyle _titleStyle;
        private GUIStyle _subtitleStyle;
        private GUIStyle _sectionTitleStyle;
        private GUIStyle _filterTitleStyle;
        private GUIStyle _searchFieldStyle;
        private GUIStyle _chipStyle;
        private GUIStyle _chipSelectedStyle;
        private GUIStyle _cardTitleStyle;
        private GUIStyle _cardTextStyle;
        private GUIStyle _overlayLabelStyle;
        private GUIStyle _centeredInfoStyle;

        [MenuItem("SEG/Flaticon Icon Browser")]
        public static void ShowWindow()
        {
            FlaticonIconBrowserWindow window = GetWindow<FlaticonIconBrowserWindow>();
            window.titleContent = new GUIContent(WindowTitle);
            window.minSize = new Vector2(960f, 680f);
            window.Show();
        }

        private void OnEnable()
        {
            _apiKey = EditorPrefs.GetString(ApiKeyEditorPref, string.Empty);
            _outputFolder = EditorPrefs.GetString(OutputFolderEditorPref, _outputFolder);
            _showFilters = EditorPrefs.GetBool(ShowFiltersEditorPref, true);
            OnEnableOutlineTab();
        }

        private void OnDisable()
        {
            EditorPrefs.SetString(ApiKeyEditorPref, _apiKey ?? string.Empty);
            EditorPrefs.SetString(OutputFolderEditorPref, _outputFolder ?? string.Empty);
            EditorPrefs.SetBool(ShowFiltersEditorPref, _showFilters);
            ClearResults();
            OnDisableOutlineTab();
        }

        private void OnGUI()
        {
            EnsureStyles();

            try
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    GUILayout.Space(OuterPadding);

                    using (new EditorGUILayout.VerticalScope())
                    {
                        GUILayout.Space(OuterPadding);

                        DrawHeader();
                        GUILayout.Space(SectionSpacing);

                        DrawTabToolbar();
                        GUILayout.Space(SectionSpacing);

                        if (_activeTab == WindowTab.Browser)
                        {
                            DrawBrowserTab();
                        }
                        else
                        {
                            DrawOutlineTab();
                        }

                        GUILayout.Space(OuterPadding);
                    }

                    GUILayout.Space(OuterPadding);
                }
            }
            catch (Exception ex)
            {
                Debug.LogException(ex);
                EditorGUILayout.HelpBox($"Editor hata verdi: {ex.Message}", MessageType.Error);
            }
        }
        private void DrawTabToolbar()
        {
            string[] tabs = { "Icon Browser", "Outline Creator" };
            _activeTab = (WindowTab)GUILayout.Toolbar((int)_activeTab, tabs, GUILayout.Height(30f));
        }

        private void DrawBrowserTab()
        {
            DrawSearchSection();
            GUILayout.Space(SectionSpacing);

            DrawSettingsSection();
            GUILayout.Space(SectionSpacing);

            DrawFiltersSection();
            GUILayout.Space(SectionSpacing);

            DrawActionsSection();
            GUILayout.Space(SectionSpacing);

            DrawResultsSection();
        }
        private void DrawHeader()
        {
            EditorGUILayout.LabelField("Search & Outline Icons", _titleStyle);
            EditorGUILayout.LabelField("Flaticon sonuçlarýný ara, filtrele, seç, kaydet ve outline üret.", _subtitleStyle);
        }

        private void EnsureStyles()
        {
            if (_titleStyle != null)
            {
                return;
            }

            _titleStyle = new GUIStyle(EditorStyles.boldLabel)
            {
                fontSize = 22,
                wordWrap = true
            };

            _subtitleStyle = new GUIStyle(EditorStyles.label)
            {
                fontSize = 11,
                wordWrap = true
            };

            _sectionTitleStyle = new GUIStyle(EditorStyles.boldLabel)
            {
                fontSize = 13,
                wordWrap = true
            };

            _filterTitleStyle = new GUIStyle(EditorStyles.boldLabel)
            {
                fontSize = 12,
                wordWrap = true
            };

            _searchFieldStyle = new GUIStyle(EditorStyles.textField)
            {
                fontSize = 13,
                fixedHeight = 34f
            };

            _chipStyle = new GUIStyle(EditorStyles.miniButton)
            {
                padding = new RectOffset(10, 10, 5, 5),
                margin = new RectOffset(2, 2, 2, 2),
                fixedHeight = 24f
            };

            _chipSelectedStyle = new GUIStyle(_chipStyle)
            {
                fontStyle = FontStyle.Bold
            };

            _cardTitleStyle = new GUIStyle(EditorStyles.boldLabel)
            {
                wordWrap = true
            };

            _cardTextStyle = new GUIStyle(EditorStyles.wordWrappedMiniLabel)
            {
                wordWrap = true
            };

            _overlayLabelStyle = new GUIStyle(EditorStyles.whiteMiniLabel)
            {
                alignment = TextAnchor.MiddleCenter,
                fontStyle = FontStyle.Bold
            };

            _centeredInfoStyle = new GUIStyle(EditorStyles.miniLabel)
            {
                alignment = TextAnchor.MiddleCenter
            };
        }

        private void DrawSearchSection()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                GUILayout.Space(8f);

                using (new EditorGUILayout.HorizontalScope())
                {
                    GUI.SetNextControlName("FlaticonSearchField");
                    _searchTerm = EditorGUILayout.TextField(_searchTerm, _searchFieldStyle, GUILayout.ExpandWidth(true));

                    bool canSearch =
                        !_isSearching &&
                        !_isSaving &&
                        !string.IsNullOrWhiteSpace(_searchTerm) &&
                        !string.IsNullOrWhiteSpace(_apiKey);

                    using (new EditorGUI.DisabledScope(!canSearch))
                    {
                        if (GUILayout.Button("Search", GUILayout.Width(120f), GUILayout.Height(34f)))
                        {
                            StartFreshSearch();
                        }
                    }
                }

                GUILayout.Space(8f);
            }

            if (Event.current.type == EventType.KeyDown &&
                Event.current.keyCode == KeyCode.Return &&
                GUI.GetNameOfFocusedControl() == "FlaticonSearchField" &&
                !_isSearching &&
                !_isSaving &&
                !string.IsNullOrWhiteSpace(_searchTerm) &&
                !string.IsNullOrWhiteSpace(_apiKey))
            {
                StartFreshSearch();
                Event.current.Use();
            }
        }

        private void DrawSettingsSection()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                EditorGUILayout.LabelField("Settings", _sectionTitleStyle);
                GUILayout.Space(4f);

                EditorGUI.BeginChangeCheck();
                _apiKey = EditorGUILayout.PasswordField("API Key", _apiKey);
                if (EditorGUI.EndChangeCheck())
                {
                    EditorPrefs.SetString(ApiKeyEditorPref, _apiKey ?? string.Empty);
                }

                _perPage = EditorGUILayout.IntPopup("Per Page", _perPage, PerPageLabels, PerPageOptions);
                _thumbnailSize = EditorGUILayout.IntPopup("Thumbnail Size", _thumbnailSize, ThumbnailSizeLabels, ThumbnailSizeOptions);

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

                if (string.IsNullOrWhiteSpace(_apiKey))
                {
                    EditorGUILayout.HelpBox("Arama yapabilmek için API key gir.", MessageType.Warning);
                }
            }
        }

        private void DrawFiltersSection()
        {
            _showFilters = EditorGUILayout.BeginFoldoutHeaderGroup(_showFilters, "Filters");
            if (_showFilters)
            {
                using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
                {
                    EditorGUILayout.LabelField("Filtreleri seç. Seçilmeyen alanlar otomatik olarak All gider.", EditorStyles.wordWrappedMiniLabel);
                    GUILayout.Space(8f);

                    float totalWidth = Mathf.Max(300f, position.width - (OuterPadding * 2f) - 32f);
                    float columnWidth = (totalWidth - FilterColumnSpacing) * 0.5f;

                    using (new EditorGUILayout.HorizontalScope())
                    {
                        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox, GUILayout.Width(columnWidth)))
                        {
                            DrawSingleSelectFilterPanel("Color", ColorOptions, ref _selectedColor, columnWidth - 20f);
                            GUILayout.Space(8f);
                            DrawSingleSelectFilterPanel("Period", PeriodOptions, ref _selectedPeriod, columnWidth - 20f);
                        }

                        GUILayout.Space(FilterColumnSpacing);

                        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox, GUILayout.Width(columnWidth)))
                        {
                            DrawSingleSelectFilterPanel("Shape", ShapeOptions, ref _selectedShape, columnWidth - 20f);
                            GUILayout.Space(8f);
                            DrawSingleSelectFilterPanel("Free SVG", FreeSvgOptions, ref _selectedFreeSvg, columnWidth - 20f);
                        }
                    }

                    GUILayout.Space(8f);

                    using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
                    {
                        DrawMultiSelectFilterPanel("Icon Type", IconTypeOptions, _selectedIconTypes, totalWidth - 20f);
                    }
                }
            }

            EditorGUILayout.EndFoldoutHeaderGroup();
        }

        private void DrawActionsSection()
        {
            int selectedCount = GetSelectedCount();

            using (new EditorGUILayout.HorizontalScope(EditorStyles.helpBox))
            {
                using (new EditorGUI.DisabledScope(_results.Count == 0 || _isSaving))
                {
                    if (GUILayout.Button("Select All", GUILayout.Width(100f)))
                    {
                        SetAllSelection(true);
                    }

                    if (GUILayout.Button("Clear Selection", GUILayout.Width(120f)))
                    {
                        SetAllSelection(false);
                    }
                }

                GUILayout.FlexibleSpace();

                using (new EditorGUI.DisabledScope(_isSaving || selectedCount == 0))
                {
                    if (GUILayout.Button($"Save Selected ({selectedCount})", GUILayout.Width(170f), GUILayout.Height(24f)))
                    {
                        SaveSelectedAsync().Forget();
                    }
                }
            }
        }

        private void DrawResultsSection()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                EditorGUILayout.LabelField("Search Results", _sectionTitleStyle);

                if (!string.IsNullOrWhiteSpace(_statusMessage))
                {
                    EditorGUILayout.HelpBox(_statusMessage, MessageType.Info);
                }

                GUILayout.Space(4f);

                using (var scrollView = new EditorGUILayout.ScrollViewScope(_scrollPosition))
                {
                    _scrollPosition = scrollView.scrollPosition;

                    float viewWidth = Mathf.Max(1f, position.width - (OuterPadding * 2f) - 48f);
                    int columnCount = Mathf.Max(1, Mathf.FloorToInt(viewWidth / CardWidth));

                    int index = 0;
                    while (index < _results.Count)
                    {
                        using (new EditorGUILayout.HorizontalScope())
                        {
                            for (int column = 0; column < columnCount && index < _results.Count; column++, index++)
                            {
                                DrawCard(_results[index]);
                            }

                            GUILayout.FlexibleSpace();
                        }

                        GUILayout.Space(8f);
                    }

                    if (_results.Count == 0 && !_isSearching)
                    {
                        EditorGUILayout.HelpBox("Henüz sonuç yok. Yukarýdan arama yap.", MessageType.None);
                    }
                }

                GUILayout.Space(8f);
                DrawPaginationSection();
            }
        }

        private void DrawPaginationSection()
        {
            bool hasPagination = _pagination != null;
            int currentPage = hasPagination ? Mathf.Max(1, _pagination.current_page) : _page;
            int lastPage = hasPagination ? Mathf.Max(1, _pagination.last_page) : 1;

            using (new EditorGUILayout.HorizontalScope(EditorStyles.helpBox))
            {
                using (new EditorGUI.DisabledScope(!hasPagination || _isSearching || _isSaving || currentPage <= 1))
                {
                    if (GUILayout.Button("First", GUILayout.Width(70f)))
                    {
                        ChangePage(1);
                    }

                    if (GUILayout.Button("Previous", GUILayout.Width(90f)))
                    {
                        ChangePage(currentPage - 1);
                    }
                }

                GUILayout.FlexibleSpace();

                if (hasPagination)
                {
                    GUILayout.Label($"Page {currentPage} / {lastPage}    Total: {_pagination.total}", _centeredInfoStyle);
                }
                else
                {
                    GUILayout.Label("Pagination bilgisi yok.", _centeredInfoStyle);
                }

                GUILayout.FlexibleSpace();

                using (new EditorGUI.DisabledScope(!hasPagination || _isSearching || _isSaving || currentPage >= lastPage))
                {
                    if (GUILayout.Button("Next", GUILayout.Width(70f)))
                    {
                        ChangePage(currentPage + 1);
                    }

                    if (GUILayout.Button("Last", GUILayout.Width(70f)))
                    {
                        ChangePage(lastPage);
                    }
                }
            }
        }

        private void DrawCard(IconViewModel icon)
        {
            Rect cardRect = GUILayoutUtility.GetRect(CardWidth, CardHeight, GUILayout.Width(CardWidth), GUILayout.Height(CardHeight));
            GUI.Box(cardRect, GUIContent.none, EditorStyles.helpBox);

            if (icon.IsSelected)
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
                icon.IsSelected = EditorGUI.ToggleLeft(toggleRect, "Selected", icon.IsSelected);
                y += 24f;

                Rect previewRect = new Rect(0f, y, contentRect.width, 150f);
                if (icon.PreviewTexture != null)
                {
                    GUI.DrawTexture(previewRect, icon.PreviewTexture, ScaleMode.ScaleToFit);
                }
                else
                {
                    EditorGUI.DrawRect(previewRect, new Color(0.18f, 0.18f, 0.18f));
                    GUI.Label(previewRect, icon.IsLoadingPreview ? "Loading..." : "No Preview", GetCenteredMiniLabel());
                }

                if (GUI.Button(previewRect, GUIContent.none, GUIStyle.none))
                {
                    icon.IsSelected = !icon.IsSelected;
                    GUI.changed = true;
                }

                if (icon.IsSelected)
                {
                    Rect selectedRect = new Rect(previewRect.x + 6f, previewRect.y + 6f, previewRect.width - 12f, 20f);
                    EditorGUI.DrawRect(selectedRect, new Color(0.19f, 0.56f, 0.95f, 0.9f));
                    GUI.Label(selectedRect, "SELECTED", _overlayLabelStyle);
                }

                y += 158f;

                Rect slugRect = new Rect(0f, y, contentRect.width, 32f);
                EditorGUI.LabelField(slugRect, string.IsNullOrWhiteSpace(icon.Slug) ? "(no slug)" : icon.Slug, _cardTitleStyle);
                y += 34f;

                Rect nameRect = new Rect(0f, y, contentRect.width, 34f);
                EditorGUI.LabelField(nameRect, string.IsNullOrWhiteSpace(icon.Name) ? "(no name)" : icon.Name, _cardTextStyle);
                y += 36f;

                Rect idRect = new Rect(0f, y, contentRect.width, 18f);
                EditorGUI.LabelField(idRect, $"Id: {icon.Id}", EditorStyles.miniLabel);
                y += 18f;

                Rect freeSvgRect = new Rect(0f, y, contentRect.width, 18f);
                EditorGUI.LabelField(freeSvgRect, $"Free SVG: {(icon.FreeSvg ? "Yes" : "No")}", EditorStyles.miniLabel);

                if (!string.IsNullOrWhiteSpace(icon.Error))
                {
                    Rect errorRect = new Rect(0f, contentRect.height - 54f, contentRect.width, 28f);
                    EditorGUI.HelpBox(errorRect, icon.Error, MessageType.Warning);
                }

                using (new EditorGUI.DisabledScope(_isSaving || string.IsNullOrWhiteSpace(icon.ThumbnailUrl)))
                {
                    string buttonLabel = icon.IsDownloading ? "Downloading..." : "Download";
                    Rect buttonRect = new Rect(0f, contentRect.height - 24f, contentRect.width, 24f);
                    if (GUI.Button(buttonRect, buttonLabel))
                    {
                        SaveSingleAsync(icon).Forget();
                    }
                }
            }
            finally
            {
                GUI.EndGroup();
            }
        }
        private void DrawSingleSelectFilterPanel(string title, string[] options, ref string selectedValue, float availableWidth)
        {
            EditorGUILayout.LabelField(title, _filterTitleStyle);
            GUILayout.Space(4f);
            DrawSingleSelectFilterOptions(options, ref selectedValue, availableWidth);
        }

        private void DrawMultiSelectFilterPanel(string title, string[] options, HashSet<string> selectedValues, float availableWidth)
        {
            EditorGUILayout.LabelField(title, _filterTitleStyle);
            GUILayout.Space(4f);
            DrawMultiSelectFilterOptions(options, selectedValues, availableWidth);
        }

        private void DrawSingleSelectFilterOptions(string[] options, ref string selectedValue, float availableWidth)
        {
            int index = 0;
            while (index < options.Length)
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    float lineWidth = availableWidth;

                    while (index < options.Length)
                    {
                        string option = options[index];
                        string label = ToDisplayLabel(option);
                        GUIContent content = new GUIContent(label);
                        float chipWidth = Mathf.Clamp(_chipStyle.CalcSize(content).x + 12f, 70f, Mathf.Max(90f, availableWidth));

                        if (lineWidth < chipWidth && lineWidth < availableWidth)
                        {
                            break;
                        }

                        bool isSelected = string.Equals(selectedValue, option, StringComparison.OrdinalIgnoreCase);
                        Color oldColor = GUI.backgroundColor;
                        GUI.backgroundColor = isSelected ? new Color(0.24f, 0.55f, 0.95f) : oldColor;

                        if (GUILayout.Button(label, isSelected ? _chipSelectedStyle : _chipStyle, GUILayout.Width(chipWidth)))
                        {
                            selectedValue = option;
                        }

                        GUI.backgroundColor = oldColor;
                        lineWidth -= chipWidth + 6f;
                        index++;
                    }

                    GUILayout.FlexibleSpace();
                }

                GUILayout.Space(2f);
            }
        }

        private void DrawMultiSelectFilterOptions(string[] options, HashSet<string> selectedValues, float availableWidth)
        {
            int index = 0;
            while (index < options.Length)
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    float lineWidth = availableWidth;

                    while (index < options.Length)
                    {
                        string option = options[index];
                        string label = ToDisplayLabel(option);
                        GUIContent content = new GUIContent(label);
                        float chipWidth = Mathf.Clamp(_chipStyle.CalcSize(content).x + 12f, 70f, Mathf.Max(90f, availableWidth));

                        if (lineWidth < chipWidth && lineWidth < availableWidth)
                        {
                            break;
                        }

                        bool isSelected = selectedValues.Contains(option);
                        Color oldColor = GUI.backgroundColor;
                        GUI.backgroundColor = isSelected ? new Color(0.24f, 0.55f, 0.95f) : oldColor;

                        if (GUILayout.Button(label, isSelected ? _chipSelectedStyle : _chipStyle, GUILayout.Width(chipWidth)))
                        {
                            if (isSelected)
                            {
                                selectedValues.Remove(option);
                            }
                            else
                            {
                                selectedValues.Add(option);
                            }
                        }

                        GUI.backgroundColor = oldColor;
                        lineWidth -= chipWidth + 6f;
                        index++;
                    }

                    GUILayout.FlexibleSpace();
                }

                GUILayout.Space(2f);
            }
        }

        private void StartFreshSearch()
        {
            _page = 1;
            SearchAsync().Forget();
        }

        private void ChangePage(int targetPage)
        {
            int lastPage = _pagination != null ? Mathf.Max(1, _pagination.last_page) : 1;
            int clampedPage = Mathf.Clamp(targetPage, 1, lastPage);

            if (clampedPage == _page)
            {
                return;
            }

            _page = clampedPage;
            SearchAsync().Forget();
        }

        private async Task SearchAsync()
        {
            _isSearching = true;
            _statusMessage = "Searching...";
            Repaint();

            ClearResults();

            string url = BuildSearchUrl();

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
                _statusMessage = $"Search failed: {request.responseCode} - {request.error}";
                _pagination = null;
                _isSearching = false;
                Repaint();
                return;
            }

            _lastRawResponse = request.downloadHandler.text;

            FlaticonSearchResponse response;
            try
            {
                response = JsonUtility.FromJson<FlaticonSearchResponse>(_lastRawResponse);
            }
            catch (Exception ex)
            {
                _statusMessage = $"JSON parse error: {ex.Message}";
                _pagination = null;
                _isSearching = false;
                Debug.LogWarning(_lastRawResponse);
                Repaint();
                return;
            }

            if (response == null || response.data == null)
            {
                _statusMessage = "Sonuç parse edilemedi. Ham response Console'a yazdýrýldý.";
                _pagination = null;
                Debug.LogWarning(_lastRawResponse);
                _isSearching = false;
                Repaint();
                return;
            }

            _pagination = response.meta != null ? response.meta.pagination : null;
            if (_pagination != null)
            {
                _page = Mathf.Max(1, _pagination.current_page);
            }

            for (int i = 0; i < response.data.Length; i++)
            {
                FlaticonIconData data = response.data[i];
                if (data == null)
                {
                    continue;
                }

                string thumbnailUrl = GetBestThumbnailUrl(data);

                IconViewModel item = new IconViewModel
                {
                    Id = data.id,
                    Name = data.name,
                    Slug = data.slug,
                    FreeSvg = data.free_svg,
                    ThumbnailUrl = thumbnailUrl,
                    IsSelected = false,
                    IsLoadingPreview = !string.IsNullOrWhiteSpace(thumbnailUrl)
                };

                _results.Add(item);
            }

            _statusMessage = $"{_results.Count} sonuç bulundu.";
            _isSearching = false;
            Repaint();

            for (int i = 0; i < _results.Count; i++)
            {
                if (!string.IsNullOrWhiteSpace(_results[i].ThumbnailUrl))
                {
                    LoadPreviewAsync(_results[i]).Forget();
                }
            }
        }

        private string BuildSearchUrl()
        {
            List<string> queryParts = new List<string>
            {
                $"order={UnityWebRequest.EscapeURL("relevance")}",
                $"term={UnityWebRequest.EscapeURL(_searchTerm)}",
                $"page={_page}",
                $"per_page={_perPage}",
                $"thumbnail_size={_thumbnailSize}"
            };

            AddFilterQuery(queryParts, "filters[color]", _selectedColor);
            AddFilterQuery(queryParts, "filters[shape]", _selectedShape);
            AddFilterQuery(queryParts, "filters[period]", _selectedPeriod);
            AddFilterQuery(queryParts, "filters[free_svg]", _selectedFreeSvg);

            foreach (string iconType in _selectedIconTypes)
            {
                queryParts.Add($"{UnityWebRequest.EscapeURL("filters[icon_type][]")}={UnityWebRequest.EscapeURL(iconType)}");
            }

            return $"{ApiUrl}?{string.Join("&", queryParts)}";
        }

        private static void AddFilterQuery(List<string> queryParts, string key, string value)
        {
            if (string.IsNullOrWhiteSpace(value) || string.Equals(value, AllFilterValue, StringComparison.OrdinalIgnoreCase))
            {
                return;
            }

            queryParts.Add($"{UnityWebRequest.EscapeURL(key)}={UnityWebRequest.EscapeURL(value)}");
        }

        private async Task LoadPreviewAsync(IconViewModel icon)
        {
            using UnityWebRequest request = UnityWebRequestTexture.GetTexture(icon.ThumbnailUrl);
            await SendRequestAsync(request);

#if UNITY_2020_1_OR_NEWER
            bool hasError = request.result != UnityWebRequest.Result.Success;
#else
            bool hasError = request.isNetworkError || request.isHttpError;
#endif

            if (hasError)
            {
                icon.IsLoadingPreview = false;
                icon.Error = "Preview load failed";
                Repaint();
                return;
            }

            Texture2D texture = DownloadHandlerTexture.GetContent(request);
            icon.PreviewTexture = texture;
            icon.IsLoadingPreview = false;
            Repaint();
        }

        private async Task SaveSingleAsync(IconViewModel item)
        {
            if (_isSaving)
            {
                return;
            }

            if (!TryPrepareOutputFolder(out string fullFolderPath))
            {
                _statusMessage = "Geçerli bir klasör seç.";
                Repaint();
                return;
            }

            _isSaving = true;
            item.IsDownloading = true;
            item.Error = null;
            _statusMessage = $"Ýndiriliyor: {GetDisplayName(item)}";
            Repaint();

            bool success = await SaveIconToFolderAsync(item, fullFolderPath);

            item.IsDownloading = false;
            _isSaving = false;

            if (success)
            {
                if (IsPathInsideProject(fullFolderPath))
                {
                    AssetDatabase.Refresh();
                }

                _statusMessage = $"Kaydedildi: {GetDisplayName(item)}";
            }
            else if (string.IsNullOrWhiteSpace(item.Error))
            {
                _statusMessage = $"Kaydedilemedi: {GetDisplayName(item)}";
            }

            Repaint();
        }

        private async Task SaveSelectedAsync()
        {
            if (!TryPrepareOutputFolder(out string fullFolderPath))
            {
                _statusMessage = "Geçerli bir klasör seç.";
                Repaint();
                return;
            }

            _isSaving = true;
            _statusMessage = "Saving selected icons...";
            Repaint();

            int savedCount = 0;

            for (int i = 0; i < _results.Count; i++)
            {
                IconViewModel item = _results[i];
                if (!item.IsSelected || string.IsNullOrWhiteSpace(item.ThumbnailUrl))
                {
                    continue;
                }

                item.IsDownloading = true;
                item.Error = null;
                Repaint();

                bool success = await SaveIconToFolderAsync(item, fullFolderPath);
                if (success)
                {
                    savedCount++;
                }

                item.IsDownloading = false;
                Repaint();
            }

            if (IsPathInsideProject(fullFolderPath))
            {
                AssetDatabase.Refresh();
            }

            _statusMessage = $"{savedCount} ikon kaydedildi.";
            _isSaving = false;
            Repaint();
        }

        private async Task<bool> SaveIconToFolderAsync(IconViewModel item, string fullFolderPath)
        {
            using UnityWebRequest request = UnityWebRequest.Get(item.ThumbnailUrl);
            await SendRequestAsync(request);

#if UNITY_2020_1_OR_NEWER
            bool hasError = request.result != UnityWebRequest.Result.Success;
#else
            bool hasError = request.isNetworkError || request.isHttpError;
#endif

            if (hasError)
            {
                item.Error = $"Save failed: {request.error}";
                return false;
            }

            byte[] bytes = request.downloadHandler.data;
            string filePath = BuildUniqueFilePath(fullFolderPath, item);
            File.WriteAllBytes(filePath, bytes);
            item.Error = null;
            return true;
        }

        private bool TryPrepareOutputFolder(out string fullFolderPath)
        {
            fullFolderPath = GetAbsoluteFolderPath(_outputFolder);
            if (string.IsNullOrWhiteSpace(fullFolderPath))
            {
                return false;
            }

            if (!Directory.Exists(fullFolderPath))
            {
                Directory.CreateDirectory(fullFolderPath);
            }

            return true;
        }

        private void ClearResults()
        {
            for (int i = 0; i < _results.Count; i++)
            {
                if (_results[i].PreviewTexture != null)
                {
                    DestroyImmediate(_results[i].PreviewTexture);
                    _results[i].PreviewTexture = null;
                }
            }

            _results.Clear();
        }

        private int GetSelectedCount()
        {
            int count = 0;
            for (int i = 0; i < _results.Count; i++)
            {
                if (_results[i].IsSelected)
                {
                    count++;
                }
            }

            return count;
        }

        private void SetAllSelection(bool isSelected)
        {
            for (int i = 0; i < _results.Count; i++)
            {
                _results[i].IsSelected = isSelected;
            }
        }

        private static async Task SendRequestAsync(UnityWebRequest request)
        {
            UnityWebRequestAsyncOperation operation = request.SendWebRequest();
            TaskCompletionSource<bool> taskCompletionSource = new TaskCompletionSource<bool>();
            operation.completed += _ => taskCompletionSource.TrySetResult(true);
            await taskCompletionSource.Task;
        }

        private static string GetBestThumbnailUrl(FlaticonIconData data)
        {
            if (data.thumbnails == null || data.thumbnails.Length == 0)
            {
                return string.Empty;
            }

            FlaticonThumbnailData best = data.thumbnails[0];
            for (int i = 1; i < data.thumbnails.Length; i++)
            {
                FlaticonThumbnailData current = data.thumbnails[i];
                if (current != null && best != null && current.width > best.width)
                {
                    best = current;
                }
            }

            return best != null ? best.url : string.Empty;
        }

        private static string BuildUniqueFilePath(string folderPath, IconViewModel item)
        {
            string rawName = !string.IsNullOrWhiteSpace(item.Slug) ? item.Slug : item.Name;
            string baseName = string.IsNullOrWhiteSpace(rawName) ? $"icon_{item.Id}" : rawName;
            baseName = SanitizeFileName(baseName);

            string extension = GetExtensionFromUrl(item.ThumbnailUrl);
            string filePath = Path.Combine(folderPath, $"{baseName}_{item.Id}{extension}");

            int counter = 1;
            while (File.Exists(filePath))
            {
                filePath = Path.Combine(folderPath, $"{baseName}_{item.Id}_{counter}{extension}");
                counter++;
            }

            return filePath;
        }

        private static string GetExtensionFromUrl(string url)
        {
            if (string.IsNullOrWhiteSpace(url))
            {
                return ".png";
            }

            try
            {
                string path = new Uri(url).AbsolutePath;
                string extension = Path.GetExtension(path);
                return string.IsNullOrWhiteSpace(extension) ? ".png" : extension;
            }
            catch
            {
                return ".png";
            }
        }

        private static string SanitizeFileName(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return "icon";
            }

            char[] invalidChars = Path.GetInvalidFileNameChars();
            for (int i = 0; i < invalidChars.Length; i++)
            {
                value = value.Replace(invalidChars[i], '_');
            }

            value = value.Replace(" ", "_");
            return value.Trim();
        }

        private static string ToDisplayLabel(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return string.Empty;
            }

            string normalized = value.Replace("-", " ").Replace("_", " ");
            string[] parts = normalized.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);

            for (int i = 0; i < parts.Length; i++)
            {
                string part = parts[i];
                if (part.Length == 1)
                {
                    parts[i] = part.ToUpperInvariant();
                }
                else
                {
                    parts[i] = char.ToUpperInvariant(part[0]) + part.Substring(1);
                }
            }

            return string.Join(" ", parts);
        }

        private static string GetDisplayName(IconViewModel item)
        {
            if (!string.IsNullOrWhiteSpace(item.Name))
            {
                return item.Name;
            }

            if (!string.IsNullOrWhiteSpace(item.Slug))
            {
                return item.Slug;
            }

            return $"icon_{item.Id}";
        }

        private static GUIStyle GetCenteredMiniLabel()
        {
            return new GUIStyle(EditorStyles.miniLabel)
            {
                alignment = TextAnchor.MiddleCenter,
                normal = { textColor = Color.white }
            };
        }

        private static void DrawBorder(Rect rect, Color color, float thickness)
        {
            EditorGUI.DrawRect(new Rect(rect.x, rect.y, rect.width, thickness), color);
            EditorGUI.DrawRect(new Rect(rect.x, rect.yMax - thickness, rect.width, thickness), color);
            EditorGUI.DrawRect(new Rect(rect.x, rect.y, thickness, rect.height), color);
            EditorGUI.DrawRect(new Rect(rect.xMax - thickness, rect.y, thickness, rect.height), color);
        }

        private static string GetAbsoluteFolderPath(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                return string.Empty;
            }

            if (Path.IsPathRooted(path))
            {
                return path;
            }

            string projectRoot = Directory.GetParent(Application.dataPath)?.FullName;
            if (string.IsNullOrWhiteSpace(projectRoot))
            {
                return string.Empty;
            }

            return Path.Combine(projectRoot, path);
        }

        private static bool IsPathInsideProject(string absolutePath)
        {
            string projectRoot = Directory.GetParent(Application.dataPath)?.FullName;
            if (string.IsNullOrWhiteSpace(projectRoot) || string.IsNullOrWhiteSpace(absolutePath))
            {
                return false;
            }

            string normalizedProjectRoot = Path.GetFullPath(projectRoot).Replace("\\", "/");
            string normalizedAbsolutePath = Path.GetFullPath(absolutePath).Replace("\\", "/");
            return normalizedAbsolutePath.StartsWith(normalizedProjectRoot, StringComparison.OrdinalIgnoreCase);
        }

        private static string MakeProjectRelativePath(string selectedFolder)
        {
            if (string.IsNullOrWhiteSpace(selectedFolder))
            {
                return string.Empty;
            }

            string dataPath = Application.dataPath.Replace("\\", "/");
            string normalizedSelected = selectedFolder.Replace("\\", "/");

            if (normalizedSelected.StartsWith(dataPath, StringComparison.OrdinalIgnoreCase))
            {
                return "Assets" + normalizedSelected.Substring(dataPath.Length);
            }

            return selectedFolder;
        }

        [Serializable]
        private sealed class FlaticonSearchResponse
        {
            public FlaticonIconData[] data;
            public MetaData meta;
        }

        [Serializable]
        private sealed class FlaticonIconData
        {
            public bool free_svg;
            public string created;
            public string name;
            public int id;
            public string slug;
            public FlaticonThumbnailData[] thumbnails;
        }

        [Serializable]
        private sealed class FlaticonThumbnailData
        {
            public string url;
            public int width;
            public int height;
        }

        [Serializable]
        private sealed class MetaData
        {
            public PaginationData pagination;
        }

        [Serializable]
        private sealed class PaginationData
        {
            public int per_page;
            public int total;
            public int last_page;
            public int current_page;
        }

        private sealed class IconViewModel
        {
            public int Id;
            public string Name;
            public string Slug;
            public bool FreeSvg;
            public string ThumbnailUrl;
            public bool IsSelected;
            public bool IsLoadingPreview;
            public bool IsDownloading;
            public string Error;
            public Texture2D PreviewTexture;
        }
    }

    internal static class TaskExtensions
    {
        public static async void Forget(this Task task)
        {
            try
            {
                await task;
            }
            catch (Exception ex)
            {
                Debug.LogException(ex);
            }
        }
    }
}
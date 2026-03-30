using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace SpecialEducationGames
{
    public static class EffectTypePickerPopup
    {
        private const float PopupPadding = 8f;
        private const float PopupSearchHeight = 20f;
        private const float PopupSearchBottomSpacing = 8f;
        private const float PopupButtonHeight = 22f;
        private const float PopupRowSpacing = 2f;
        private const float PopupColumnWidth = 210f;
        private const float PopupColumnSpacing = 6f;
        private const int PopupButtonPaddingHorizontal = 8;
        private const int PopupButtonPaddingVertical = 2;
        private const int PopupMaxRowsPerColumn = 24;
        private const int PopupMinVisibleColumnCount = 2;
        private const int PopupMaxVisibleColumnCount = 4;
        private const float PopupScrollbarReserveWidth = 16f;
        private const float PopupMaxWindowWidth = 900f;
        private const float PopupMaxWindowHeight = 730f;
        private const bool KeepPopupWidthStableWhileSearching = true;

        private static readonly Color HighlightedItemColor = new Color(0.30f, 0.55f, 0.95f, 1f);
        private static readonly Color CurrentValueColor = new Color(0.24f, 0.67f, 0.38f, 1f);

        public static void Show(Rect buttonRect, SerializedProperty property)
        {
            if (property == null || property.propertyType != SerializedPropertyType.Enum)
            {
                return;
            }

            SerializedObject serializedObject = property.serializedObject;
            string propertyPath = property.propertyPath;

            EffectType? currentValue = null;
            if (!property.hasMultipleDifferentValues)
            {
                Array values = Enum.GetValues(typeof(EffectType));
                if (property.enumValueIndex >= 0 && property.enumValueIndex < values.Length)
                {
                    currentValue = (EffectType)values.GetValue(property.enumValueIndex);
                }
            }

            PopupWindow.Show(
                buttonRect,
                new PopupContent(
                    selectedValue =>
                    {
                        if (serializedObject == null)
                        {
                            return;
                        }

                        serializedObject.Update();

                        SerializedProperty targetProperty = serializedObject.FindProperty(propertyPath);
                        if (targetProperty == null || targetProperty.propertyType != SerializedPropertyType.Enum)
                        {
                            return;
                        }

                        int enumIndex = Array.IndexOf(targetProperty.enumNames, selectedValue.ToString());
                        if (enumIndex < 0)
                        {
                            return;
                        }

                        targetProperty.enumValueIndex = enumIndex;
                        serializedObject.ApplyModifiedProperties();

                        UnityEngine.Object[] targets = serializedObject.targetObjects;
                        for (int i = 0; i < targets.Length; i++)
                        {
                            EditorUtility.SetDirty(targets[i]);
                        }
                    },
                    currentValue));
        }

        private sealed class PopupContent : PopupWindowContent
        {
            private const string SearchControlName = "EffectTypePopup_SearchField";

            private readonly Action<EffectType> _onSelected;
            private readonly EffectType? _currentValue;
            private readonly List<ItemData> _allItems = new List<ItemData>();

            private Vector2 _scrollPosition;
            private string _searchText = string.Empty;
            private int _highlightedIndex = -1;
            private EffectType? _highlightedValue;
            private bool _focusSearchFieldOnNextGui = true;
            private bool _isNavigatingList;
            private bool _resetHighlightToFirstOnNextGui;
            private int _forceCaretToEndFrameCount;

            public PopupContent(Action<EffectType> onSelected, EffectType? currentValue)
            {
                _onSelected = onSelected;
                _currentValue = currentValue;
                _highlightedValue = currentValue;

                Array values = Enum.GetValues(typeof(EffectType));
                foreach (object value in values)
                {
                    EffectType enumValue = (EffectType)value;
                    _allItems.Add(new ItemData(enumValue, ObjectNames.NicifyVariableName(enumValue.ToString())));
                }
            }

            public override Vector2 GetWindowSize()
            {
                int widthReferenceItemCount = KeepPopupWidthStableWhileSearching
                    ? _allItems.Count
                    : GetFilteredItems().Count;

                int visibleColumnCount = GetVisibleColumnCount(widthReferenceItemCount);

                int heightReferenceItemCount = _allItems.Count;
                int visibleRowCount = Mathf.Clamp(heightReferenceItemCount, 1, PopupMaxRowsPerColumn);

                float width = GetContentWidth(visibleColumnCount) + (PopupPadding * 2f) + PopupScrollbarReserveWidth;
                width = Mathf.Min(PopupMaxWindowWidth, width);

                float height = PopupPadding
                               + PopupSearchHeight
                               + PopupSearchBottomSpacing
                               + GetContentHeight(visibleRowCount)
                               + PopupPadding
                               + 8f;

                height = Mathf.Min(PopupMaxWindowHeight, height);

                return new Vector2(width, height);
            }

            public override void OnGUI(Rect rect)
            {
                Rect searchRect = new Rect(
                    PopupPadding,
                    PopupPadding,
                    rect.width - (PopupPadding * 2f),
                    PopupSearchHeight);

                Rect listRect = new Rect(
                    PopupPadding,
                    searchRect.yMax + PopupSearchBottomSpacing,
                    rect.width - (PopupPadding * 2f),
                    rect.height - searchRect.yMax - PopupPadding - PopupSearchBottomSpacing);

                List<ItemData> filteredItemsBeforeSearchDraw = GetFilteredItems();

                HandleMoveFromSearchFieldToList(filteredItemsBeforeSearchDraw, listRect);

                string newSearchText = DrawSearchField(searchRect, _searchText);

                if (_focusSearchFieldOnNextGui)
                {
                    FocusSearchFieldImmediate();
                    _focusSearchFieldOnNextGui = false;
                }

                EnsureSearchCaretAtEnd();

                bool searchChanged = !string.Equals(_searchText, newSearchText, StringComparison.Ordinal);
                if (searchChanged)
                {
                    _searchText = newSearchText;
                    _isNavigatingList = false;
                    _resetHighlightToFirstOnNextGui = true;
                }

                HandleMoveFromListToSearchField();

                List<ItemData> filteredItems = GetFilteredItems();

                if (_resetHighlightToFirstOnNextGui)
                {
                    ResetHighlightedItemToFirst(filteredItems);
                    _resetHighlightToFirstOnNextGui = false;
                }

                SyncHighlightedIndex(filteredItems);

                if (filteredItems.Count == 0)
                {
                    EditorGUI.HelpBox(listRect, "Sonuç bulunamadý.", MessageType.Info);
                    HandleCloseKeys();
                    return;
                }

                HandleListKeyboardNavigation(filteredItems, listRect);

                int contentColumnCount = GetActualColumnCount(filteredItems.Count);
                int contentRowCount = Mathf.Min(PopupMaxRowsPerColumn, filteredItems.Count);

                float contentWidth = GetContentWidth(contentColumnCount);
                float contentHeight = GetContentHeight(contentRowCount);

                Rect viewRect = new Rect(0f, 0f, contentWidth, contentHeight);
                _scrollPosition = GUI.BeginScrollView(listRect, _scrollPosition, viewRect);

                for (int i = 0; i < filteredItems.Count; i++)
                {
                    Rect itemRect = GetItemRect(i);
                    DrawItem(itemRect, filteredItems[i], i == _highlightedIndex);
                }

                GUI.EndScrollView();
            }

            private void DrawItem(Rect rect, ItemData item, bool isHighlighted)
            {
                bool showCurrentValue = string.IsNullOrWhiteSpace(_searchText);
                bool isCurrentValue = showCurrentValue && _currentValue.HasValue && _currentValue.Value.Equals(item.Value);

                Color previousColor = GUI.backgroundColor;

                if (isHighlighted)
                {
                    GUI.backgroundColor = HighlightedItemColor;
                }
                else if (isCurrentValue)
                {
                    GUI.backgroundColor = CurrentValueColor;
                }

                GUIStyle style = new GUIStyle(EditorStyles.miniButton)
                {
                    alignment = TextAnchor.MiddleLeft,
                    padding = new RectOffset(
                        PopupButtonPaddingHorizontal,
                        PopupButtonPaddingHorizontal,
                        PopupButtonPaddingVertical,
                        PopupButtonPaddingVertical)
                };

                if (GUI.Button(rect, item.Label, style))
                {
                    SelectItem(item.Value);
                }

                GUI.backgroundColor = previousColor;
            }

            private void HandleMoveFromSearchFieldToList(List<ItemData> filteredItems, Rect listRect)
            {
                Event currentEvent = Event.current;
                if (currentEvent.type != EventType.KeyDown)
                {
                    return;
                }

                if (filteredItems.Count == 0)
                {
                    return;
                }

                bool isSearchFocused = GUI.GetNameOfFocusedControl() == SearchControlName || EditorGUIUtility.editingTextField;
                if (!isSearchFocused)
                {
                    return;
                }

                if (currentEvent.keyCode != KeyCode.DownArrow && currentEvent.keyCode != KeyCode.UpArrow)
                {
                    return;
                }

                _isNavigatingList = true;
                GUI.FocusControl(string.Empty);

                if (_highlightedIndex < 0 || _highlightedIndex >= filteredItems.Count)
                {
                    int startIndex = currentEvent.keyCode == KeyCode.UpArrow
                        ? filteredItems.Count - 1
                        : 0;

                    SetHighlightedIndex(filteredItems, startIndex);
                }

                EnsureHighlightedItemVisible(listRect, filteredItems);
                editorWindow.Repaint();
                currentEvent.Use();
            }

            private void HandleMoveFromListToSearchField()
            {
                Event currentEvent = Event.current;
                if (!_isNavigatingList || currentEvent.type != EventType.KeyDown)
                {
                    return;
                }

                if (currentEvent.keyCode == KeyCode.Backspace)
                {
                    if (!string.IsNullOrEmpty(_searchText))
                    {
                        _searchText = _searchText.Substring(0, _searchText.Length - 1);
                    }

                    ReturnFocusToSearchField(true);
                    currentEvent.Use();
                    return;
                }

                if (IsTypingCharacter(currentEvent))
                {
                    _searchText += currentEvent.character;
                    ReturnFocusToSearchField(true);
                    currentEvent.Use();
                }
            }

            private void ReturnFocusToSearchField(bool resetHighlightToFirst)
            {
                _isNavigatingList = false;
                _focusSearchFieldOnNextGui = true;
                _resetHighlightToFirstOnNextGui = resetHighlightToFirst;
                _forceCaretToEndFrameCount = 3;

                editorWindow.Repaint();
            }

            private void FocusSearchFieldImmediate()
            {
                if (editorWindow == null)
                {
                    return;
                }

                editorWindow.Focus();
                GUI.FocusControl(SearchControlName);
                EditorGUI.FocusTextInControl(SearchControlName);
                EditorGUIUtility.editingTextField = true;

                ForceSearchCaretToEnd();
            }

            private void ResetHighlightedItemToFirst(List<ItemData> filteredItems)
            {
                if (filteredItems == null || filteredItems.Count == 0)
                {
                    _highlightedIndex = -1;
                    _highlightedValue = null;
                    return;
                }

                _highlightedIndex = 0;
                _highlightedValue = filteredItems[0].Value;
            }

            private void EnsureSearchCaretAtEnd()
            {
                if (_forceCaretToEndFrameCount <= 0)
                {
                    return;
                }

                if (GUI.GetNameOfFocusedControl() != SearchControlName)
                {
                    return;
                }

                ForceSearchCaretToEnd();
                _forceCaretToEndFrameCount--;
            }

            private void ForceSearchCaretToEnd()
            {
                if (GUIUtility.keyboardControl == 0)
                {
                    return;
                }

                TextEditor textEditor = GUIUtility.GetStateObject(typeof(TextEditor), GUIUtility.keyboardControl) as TextEditor;
                if (textEditor == null)
                {
                    return;
                }

                int textLength = string.IsNullOrEmpty(_searchText) ? 0 : _searchText.Length;
                textEditor.cursorIndex = textLength;
                textEditor.selectIndex = textLength;
            }

            private string DrawSearchField(Rect rect, string value)
            {
                GUI.SetNextControlName(SearchControlName);

                Rect textRect = rect;
                Rect clearButtonRect = new Rect(rect.xMax - 18f, rect.y, 18f, rect.height);

                if (!string.IsNullOrEmpty(value))
                {
                    textRect.width -= 20f;
                }

                value = EditorGUI.TextField(textRect, value, GetSearchTextFieldStyle());

                if (!string.IsNullOrEmpty(value))
                {
                    if (GUI.Button(clearButtonRect, "×", EditorStyles.miniButton))
                    {
                        value = string.Empty;
                        _focusSearchFieldOnNextGui = true;
                        _forceCaretToEndFrameCount = 3;
                        _resetHighlightToFirstOnNextGui = true;
                    }
                }

                return value;
            }

            private static GUIStyle GetSearchTextFieldStyle()
            {
                GUIStyle style = GUI.skin.FindStyle("ToolbarSeachTextField");
                if (style != null)
                {
                    return style;
                }

                style = GUI.skin.FindStyle("ToolbarSearchTextField");
                if (style != null)
                {
                    return style;
                }

                return EditorStyles.textField;
            }

            private static bool IsTypingCharacter(Event currentEvent)
            {
                if (currentEvent.alt || currentEvent.control || currentEvent.command)
                {
                    return false;
                }

                char character = currentEvent.character;
                return character != '\0' && !char.IsControl(character);
            }

            private void HandleListKeyboardNavigation(List<ItemData> filteredItems, Rect listRect)
            {
                Event currentEvent = Event.current;
                if (currentEvent.type != EventType.KeyDown)
                {
                    return;
                }

                if (!_isNavigatingList)
                {
                    if (currentEvent.keyCode == KeyCode.Escape)
                    {
                        editorWindow.Close();
                        currentEvent.Use();
                    }

                    return;
                }

                int nextIndex = _highlightedIndex;

                switch (currentEvent.keyCode)
                {
                    case KeyCode.DownArrow:
                        nextIndex = Mathf.Min(_highlightedIndex + 1, filteredItems.Count - 1);
                        currentEvent.Use();
                        break;

                    case KeyCode.UpArrow:
                        if (_highlightedIndex <= 0)
                        {
                            ReturnFocusToSearchField(false);
                            currentEvent.Use();
                            return;
                        }

                        nextIndex = Mathf.Max(_highlightedIndex - 1, 0);
                        currentEvent.Use();
                        break;

                    case KeyCode.RightArrow:
                        nextIndex = Mathf.Min(_highlightedIndex + PopupMaxRowsPerColumn, filteredItems.Count - 1);
                        currentEvent.Use();
                        break;

                    case KeyCode.LeftArrow:
                        nextIndex = Mathf.Max(_highlightedIndex - PopupMaxRowsPerColumn, 0);
                        currentEvent.Use();
                        break;

                    case KeyCode.Return:
                    case KeyCode.KeypadEnter:
                        if (_highlightedIndex >= 0 && _highlightedIndex < filteredItems.Count)
                        {
                            SelectItem(filteredItems[_highlightedIndex].Value);
                        }

                        currentEvent.Use();
                        return;

                    case KeyCode.Escape:
                        editorWindow.Close();
                        currentEvent.Use();
                        return;
                }

                if (nextIndex != _highlightedIndex)
                {
                    SetHighlightedIndex(filteredItems, nextIndex);
                    EnsureHighlightedItemVisible(listRect, filteredItems);
                    editorWindow.Repaint();
                }
            }

            private void HandleCloseKeys()
            {
                Event currentEvent = Event.current;
                if (currentEvent.type != EventType.KeyDown)
                {
                    return;
                }

                if (currentEvent.keyCode == KeyCode.Escape)
                {
                    editorWindow.Close();
                    currentEvent.Use();
                }
            }

            private void EnsureHighlightedItemVisible(Rect listRect, List<ItemData> filteredItems)
            {
                if (_highlightedIndex < 0 || _highlightedIndex >= filteredItems.Count)
                {
                    return;
                }

                Rect itemRect = GetItemRect(_highlightedIndex);

                float visibleLeft = _scrollPosition.x;
                float visibleRight = _scrollPosition.x + listRect.width;
                float visibleTop = _scrollPosition.y;
                float visibleBottom = _scrollPosition.y + listRect.height;

                if (itemRect.xMin < visibleLeft)
                {
                    _scrollPosition.x = itemRect.xMin;
                }
                else if (itemRect.xMax > visibleRight)
                {
                    _scrollPosition.x = itemRect.xMax - listRect.width;
                }

                if (itemRect.yMin < visibleTop)
                {
                    _scrollPosition.y = itemRect.yMin;
                }
                else if (itemRect.yMax > visibleBottom)
                {
                    _scrollPosition.y = itemRect.yMax - listRect.height;
                }

                _scrollPosition.x = Mathf.Max(0f, _scrollPosition.x);
                _scrollPosition.y = Mathf.Max(0f, _scrollPosition.y);
            }

            private void SyncHighlightedIndex(List<ItemData> filteredItems)
            {
                if (filteredItems.Count == 0)
                {
                    _highlightedIndex = -1;
                    _highlightedValue = null;
                    return;
                }

                if (_highlightedValue.HasValue)
                {
                    for (int i = 0; i < filteredItems.Count; i++)
                    {
                        if (filteredItems[i].Value.Equals(_highlightedValue.Value))
                        {
                            _highlightedIndex = i;
                            return;
                        }
                    }
                }

                if (_currentValue.HasValue)
                {
                    for (int i = 0; i < filteredItems.Count; i++)
                    {
                        if (filteredItems[i].Value.Equals(_currentValue.Value))
                        {
                            _highlightedIndex = i;
                            _highlightedValue = filteredItems[i].Value;
                            return;
                        }
                    }
                }

                _highlightedIndex = 0;
                _highlightedValue = filteredItems[0].Value;
            }

            private void SetHighlightedIndex(List<ItemData> filteredItems, int index)
            {
                if (filteredItems.Count == 0)
                {
                    _highlightedIndex = -1;
                    _highlightedValue = null;
                    return;
                }

                _highlightedIndex = Mathf.Clamp(index, 0, filteredItems.Count - 1);
                _highlightedValue = filteredItems[_highlightedIndex].Value;
            }

            private void SelectItem(EffectType value)
            {
                _onSelected?.Invoke(value);
                editorWindow.Close();
            }

            private List<ItemData> GetFilteredItems()
            {
                if (string.IsNullOrWhiteSpace(_searchText))
                {
                    return _allItems;
                }

                string search = _searchText.Trim();

                List<ItemData> filteredItems = new List<ItemData>();
                for (int i = 0; i < _allItems.Count; i++)
                {
                    ItemData item = _allItems[i];

                    if (item.Label.IndexOf(search, StringComparison.OrdinalIgnoreCase) >= 0 ||
                        item.RawName.IndexOf(search, StringComparison.OrdinalIgnoreCase) >= 0)
                    {
                        filteredItems.Add(item);
                    }
                }

                return filteredItems;
            }

            private static int GetActualColumnCount(int itemCount)
            {
                if (itemCount <= 0)
                {
                    return 1;
                }

                return Mathf.Max(1, Mathf.CeilToInt(itemCount / (float)PopupMaxRowsPerColumn));
            }

            private static int GetVisibleColumnCount(int itemCount)
            {
                int actualColumnCount = GetActualColumnCount(itemCount);
                return Mathf.Clamp(actualColumnCount, PopupMinVisibleColumnCount, PopupMaxVisibleColumnCount);
            }

            private static float GetContentWidth(int columnCount)
            {
                return (columnCount * PopupColumnWidth) + ((columnCount - 1) * PopupColumnSpacing);
            }

            private static float GetContentHeight(int rowCount)
            {
                if (rowCount <= 0)
                {
                    return PopupButtonHeight;
                }

                return (rowCount * PopupButtonHeight) + ((rowCount - 1) * PopupRowSpacing);
            }

            private static Rect GetItemRect(int index)
            {
                int column = index / PopupMaxRowsPerColumn;
                int row = index % PopupMaxRowsPerColumn;

                return new Rect(
                    column * (PopupColumnWidth + PopupColumnSpacing),
                    row * (PopupButtonHeight + PopupRowSpacing),
                    PopupColumnWidth,
                    PopupButtonHeight);
            }

            private readonly struct ItemData
            {
                public readonly EffectType Value;
                public readonly string Label;
                public readonly string RawName;

                public ItemData(EffectType value, string label)
                {
                    Value = value;
                    Label = label;
                    RawName = value.ToString();
                }
            }
        }
    }
}
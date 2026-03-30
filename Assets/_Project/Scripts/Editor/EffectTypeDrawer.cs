using UnityEditor;
using UnityEngine;

namespace SpecialEducationGames
{
    [CustomPropertyDrawer(typeof(EffectType))]
    public sealed class EffectTypeDrawer : PropertyDrawer
    {
        public override float GetPropertyHeight(SerializedProperty property, GUIContent label)
        {
            return EditorGUIUtility.singleLineHeight;
        }

        public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
        {
            if (property.propertyType != SerializedPropertyType.Enum)
            {
                EditorGUI.PropertyField(position, property, label, true);
                return;
            }

            EditorGUI.BeginProperty(position, label, property);

            Rect buttonRect = EditorGUI.PrefixLabel(position, label);

            string currentLabel = property.hasMultipleDifferentValues
                ? "—"
                : property.enumDisplayNames[property.enumValueIndex];

            if (GUI.Button(buttonRect, currentLabel, EditorStyles.popup))
            {
                EffectTypePickerPopup.Show(buttonRect, property);
            }

            EditorGUI.EndProperty();
        }
    }
}
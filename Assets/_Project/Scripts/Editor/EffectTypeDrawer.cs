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

            string currentLabel;
            if (property.hasMultipleDifferentValues)
            {
                currentLabel = "—";
            }
            else
            {
                int index = property.enumValueIndex;
                string[] displayNames = property.enumDisplayNames;

                currentLabel = index >= 0 && index < displayNames.Length
                    ? displayNames[index]
                    : $"Invalid ({property.intValue})";
            }

            if (GUI.Button(buttonRect, currentLabel, EditorStyles.popup))
            {
                EffectTypePickerPopup.Show(buttonRect, property);
            }

            EditorGUI.EndProperty();
        }
    }
}
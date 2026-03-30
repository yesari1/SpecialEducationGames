using UnityEditor;
using UnityEngine;

namespace SpecialEducationGames
{
    [CustomEditor(typeof(SoundData))]
    [CanEditMultipleObjects]
    public class SoundDataEditor : Editor
    {
        private const float InspectorBottomSpacing = 4f;

        private SerializedProperty _effectType;

        private void OnEnable()
        {
            _effectType = serializedObject.FindProperty("GameSound");
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            DrawScriptField();
            EditorGUILayout.PropertyField(_effectType);

            EditorGUILayout.Space(InspectorBottomSpacing);
            DrawPropertiesExcluding(serializedObject, "m_Script", "GameSound");

            serializedObject.ApplyModifiedProperties();
        }

        private void DrawScriptField()
        {
            using (new EditorGUI.DisabledScope(true))
            {
                EditorGUILayout.ObjectField(
                    "Script",
                    MonoScript.FromScriptableObject((SoundData)target),
                    typeof(SoundData),
                    false);
            }
        }
    }
}
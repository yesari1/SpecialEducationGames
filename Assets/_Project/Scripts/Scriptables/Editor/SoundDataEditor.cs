using UnityEditor;
using UnityEngine;

namespace SpecialEducationGames
{
    [CustomEditor(typeof(SoundData))]
    [CanEditMultipleObjects]
    public class SoundDataEditor : Editor
    {
        private const float InspectorBottomSpacing = 4f;

        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            DrawScriptField();

            EditorGUILayout.Space(InspectorBottomSpacing);
            DrawPropertiesExcluding(serializedObject, "m_Script");

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
using UnityEditor;
using UnityEngine;
using SpecialEducationGames;
using System.IO;

[CustomEditor(typeof(SoundSettingsData))]
public class SoundSettingsDataEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        if (GUILayout.Button("GameSoundTuples'ý SoundData ScriptableObject'lerine dönüþtür"))
        {
            var soundSettings = (SoundSettingsData)target;
            string assetPath = AssetDatabase.GetAssetPath(soundSettings);
            string fileName = Path.GetFileNameWithoutExtension(assetPath);
            string folderPath = $"Assets/_Project/ScriptableObjects/SoundData_{fileName}";

            if (!AssetDatabase.IsValidFolder(folderPath))
            {
                string parent = "Assets/_Project/ScriptableObjects";
                if (!AssetDatabase.IsValidFolder(parent))
                    AssetDatabase.CreateFolder("Assets/_Project", "ScriptableObjects");
                AssetDatabase.CreateFolder(parent, $"SoundData_{fileName}");
            }

            foreach (var tuple in soundSettings.GameSoundTuples)
            {
                var asset = ScriptableObject.CreateInstance<SoundData>();
                asset.GameSound = tuple.GameSound;
                // asset.LocalizedAudioClip = ... // Elle atama yapýlmalý, AudioClip'ten otomatik çevrim yok

                string tupleAssetPath = $"{folderPath}/{tuple.AudioClip.name}_SoundData.asset";
                AssetDatabase.CreateAsset(asset, tupleAssetPath);
            }

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            Debug.Log($"{fileName} içindeki GameSoundTuples baþarýyla SoundData ScriptableObject'lerine dönüþtürüldü.");
        }
    }
}
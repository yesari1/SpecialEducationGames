using UnityEditor;
using UnityEngine;
using SpecialEducationGames;

[CustomEditor(typeof(ChoosableData))]
public class ChoosableDataEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        if (GUILayout.Button("Tuples listesini ItemTupleData ScriptableObject'lerine dönüþtür"))
        {
            var choosableData = (ChoosableData)target;
            string assetFolder = "Assets/_Project/Scriptables/ChoosableDataItems";
            if (!AssetDatabase.IsValidFolder(assetFolder))
                AssetDatabase.CreateFolder("Assets/_Project/Scriptables", "ChoosableDataItems");

            foreach (var tuple in choosableData.ChoosableTuples)
            {
                var asset = ScriptableObject.CreateInstance<ItemTupleData>();
                asset.Name = tuple.Name;
                asset.Sprite = tuple.Sprite;
                asset.Audio = tuple.Audio;

                string assetPath = $"{assetFolder}/{tuple.Audio}_ItemTupleData.asset";
                AssetDatabase.CreateAsset(asset, assetPath);
            }
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            Debug.Log("ChoosableData Tuples baþarýyla ItemTupleData ScriptableObject'lerine dönüþtürüldü.");
        }
    }
}
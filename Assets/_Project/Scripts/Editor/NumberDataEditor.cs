using UnityEditor;
using UnityEngine;
using SpecialEducationGames;

[CustomEditor(typeof(NumberData))]
public class NumberDataEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        if (GUILayout.Button("Tuples listesini ItemTupleData ScriptableObject'lerine dönüþtür"))
        {
            var numberData = (NumberData)target;
            string assetFolder = "Assets/_Project/Scriptables/NumberDataItems";
            if (!AssetDatabase.IsValidFolder(assetFolder))
                AssetDatabase.CreateFolder("Assets/_Project/Scriptables", "NumberDataItems");

            foreach (var tuple in numberData.NumberTuples)
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
            Debug.Log("NumberData Tuples baþarýyla ItemTupleData ScriptableObject'lerine dönüþtürüldü.");
        }
    }
}
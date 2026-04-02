using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace SpecialEducationGames
{
    public static class ItemDataSoundAutoAssigner
    {
        private const string ItemDataFolder = "Assets/_Project/Scriptables/ItemDatas";
        private const string MenuPath = "Tools/SEG/Assign SoundData To ItemData";

        [MenuItem(MenuPath)]
        public static void Assign()
        {
            string[] itemGuids = AssetDatabase.FindAssets("t:ItemData", new[] { ItemDataFolder });
            string[] soundGuids = AssetDatabase.FindAssets("t:SoundData");

            Dictionary<string, SoundData> soundMap = new Dictionary<string, SoundData>();

            for (int i = 0; i < soundGuids.Length; i++)
            {
                string path = AssetDatabase.GUIDToAssetPath(soundGuids[i]);
                SoundData soundData = AssetDatabase.LoadAssetAtPath<SoundData>(path);
                if (soundData == null)
                {
                    continue;
                }

                string key = NormalizeSoundDataName(soundData.name);
                if (!soundMap.ContainsKey(key))
                {
                    soundMap.Add(key, soundData);
                }
                else
                {
                    Debug.LogWarning($"Ayný isim köküyle birden fazla SoundData bulundu: {key}");
                }
            }

            int assignedCount = 0;
            int missingCount = 0;

            for (int i = 0; i < itemGuids.Length; i++)
            {
                string path = AssetDatabase.GUIDToAssetPath(itemGuids[i]);
                ItemData itemData = AssetDatabase.LoadAssetAtPath<ItemData>(path);
                if (itemData == null)
                {
                    continue;
                }

                string key = NormalizeItemDataName(itemData.name);

                if (!soundMap.TryGetValue(key, out SoundData soundData))
                {
                    missingCount++;
                    Debug.LogWarning($"SoundData bulunamadý. ItemData: {itemData.name}, Aranan anahtar: {key}", itemData);
                    continue;
                }

                if (itemData.Audio == soundData)
                {
                    continue;
                }

                itemData.Audio = soundData;
                EditorUtility.SetDirty(itemData);
                assignedCount++;

                Debug.Log($"SoundData atandý: {itemData.name} -> {soundData.name}", itemData);
            }

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            EditorUtility.DisplayDialog(
                "Ýþlem Tamamlandý",
                $"Atanan: {assignedCount}\nBulunamayan: {missingCount}",
                "Tamam");
        }

        private static string NormalizeItemDataName(string assetName)
        {
            return Normalize(assetName, "_ItemTupleData");
        }

        private static string NormalizeSoundDataName(string assetName)
        {
            return Normalize(assetName, "_SoundData");
        }

        private static string Normalize(string assetName, string suffix)
        {
            if (string.IsNullOrWhiteSpace(assetName))
            {
                return string.Empty;
            }

            string value = assetName.Trim();

            if (value.EndsWith(suffix))
            {
                value = value.Substring(0, value.Length - suffix.Length);
            }

            return value.Trim().ToLowerInvariant();
        }
    }
}
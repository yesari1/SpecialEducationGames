using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.Localization;
using UnityEngine;
using UnityEngine.Localization;
using UnityEngine.Localization.Tables;

namespace SpecialEducationGames
{
    public static class AnimalSoundDataBatchTool
    {
        private const string AudioFolder = "Assets/_Project/Audio/Animals";
        private const string SoundDataFolder = "Assets/_Project/Scriptables/SoundDatas/Animals";
        private const string ItemDataFolder = "Assets/_Project/Scriptables/ItemDatas/Animals";
        private const string AudioTableName = "AudioTable";
        private const string MenuPath = "Tools/SEG/Generate Animal SoundDatas And Assign ItemData Audio";

        [MenuItem(MenuPath)]
        public static void Generate()
        {
            EnsureFolderHierarchy(SoundDataFolder);

            AssetTableCollection audioTableCollection = LocalizationEditorSettings.GetAssetTableCollection(AudioTableName);
            if (audioTableCollection == null || audioTableCollection.SharedData == null)
            {
                EditorUtility.DisplayDialog(
                    "Hata",
                    AudioTableName + " bulunamadý.",
                    "Tamam");
                return;
            }

            string[] audioGuids = AssetDatabase.FindAssets("t:AudioClip", new[] { AudioFolder });
            Dictionary<string, SoundData> soundDataMap = new Dictionary<string, SoundData>();

            int createdSoundDataCount = 0;
            int updatedSoundDataCount = 0;
            int createdAudioKeyCount = 0;
            int assignedItemAudioCount = 0;
            int missingItemAudioCount = 0;

            for (int i = 0; i < audioGuids.Length; i++)
            {
                string audioPath = AssetDatabase.GUIDToAssetPath(audioGuids[i]);
                AudioClip audioClip = AssetDatabase.LoadAssetAtPath<AudioClip>(audioPath);
                if (audioClip == null)
                {
                    continue;
                }

                string audioGuid = AssetDatabase.AssetPathToGUID(audioPath);
                if (string.IsNullOrWhiteSpace(audioGuid))
                {
                    continue;
                }

                string key = Path.GetFileNameWithoutExtension(audioPath);
                if (string.IsNullOrWhiteSpace(key))
                {
                    continue;
                }

                SharedTableData.SharedTableEntry sharedEntry = audioTableCollection.SharedData.GetEntry(key);
                if (sharedEntry == null)
                {
                    sharedEntry = audioTableCollection.SharedData.AddKey(key);
                    EditorUtility.SetDirty(audioTableCollection.SharedData);
                    createdAudioKeyCount++;
                }

                AssignClipToAllAudioTables(audioTableCollection, key, audioGuid);

                string soundDataAssetPath = SoundDataFolder + "/" + key + "_SoundData.asset";
                SoundData soundData = AssetDatabase.LoadAssetAtPath<SoundData>(soundDataAssetPath);

                if (soundData == null)
                {
                    soundData = ScriptableObject.CreateInstance<SoundData>();
                    soundData.name = Path.GetFileNameWithoutExtension(soundDataAssetPath);
                    AssetDatabase.CreateAsset(soundData, soundDataAssetPath);
                    createdSoundDataCount++;
                }
                else
                {
                    updatedSoundDataCount++;
                }

                soundData.LocalizedAudioClip = new LocalizedAudioClip
                {
                    TableReference = AudioTableName,
                    TableEntryReference = sharedEntry.Id
                };

                EditorUtility.SetDirty(soundData);

                string normalizedKey = NormalizeKey(key);
                if (!soundDataMap.ContainsKey(normalizedKey))
                {
                    soundDataMap.Add(normalizedKey, soundData);
                }

                Debug.Log("SoundData hazýrlandý: " + soundData.name + " -> " + key, soundData);
            }

            string[] itemGuids = AssetDatabase.FindAssets("t:ItemData", new[] { ItemDataFolder });

            for (int i = 0; i < itemGuids.Length; i++)
            {
                string itemPath = AssetDatabase.GUIDToAssetPath(itemGuids[i]);
                ItemData itemData = AssetDatabase.LoadAssetAtPath<ItemData>(itemPath);
                if (itemData == null)
                {
                    continue;
                }

                string itemKey = ExtractItemKey(itemData.name);
                string normalizedItemKey = NormalizeKey(itemKey);

                if (!soundDataMap.TryGetValue(normalizedItemKey, out SoundData soundData))
                {
                    missingItemAudioCount++;
                    Debug.LogWarning("SoundData eþleþmedi: " + itemData.name + " | Key: " + itemKey, itemData);
                    continue;
                }

                if (itemData.Audio != soundData)
                {
                    itemData.Audio = soundData;
                    EditorUtility.SetDirty(itemData);
                    assignedItemAudioCount++;
                }

                Debug.Log("ItemData audio atandý: " + itemData.name + " -> " + soundData.name, itemData);
            }

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            EditorUtility.DisplayDialog(
                "Ýþlem Tamamlandý",
                "Audio Clip: " + audioGuids.Length + "\n" +
                "SoundData Created: " + createdSoundDataCount + "\n" +
                "SoundData Updated: " + updatedSoundDataCount + "\n" +
                "AudioTable New Key: " + createdAudioKeyCount + "\n" +
                "ItemData Audio Assigned: " + assignedItemAudioCount + "\n" +
                "ItemData Audio Missing: " + missingItemAudioCount,
                "Tamam");
        }

        private static void AssignClipToAllAudioTables(AssetTableCollection collection, string key, string audioGuid)
        {
            if (collection.AssetTables == null)
            {
                return;
            }

            for (int i = 0; i < collection.AssetTables.Count; i++)
            {
                AssetTable table = collection.AssetTables[i];
                if (table == null)
                {
                    continue;
                }

                table.AddEntry(key, audioGuid);
                EditorUtility.SetDirty(table);
            }
        }

        private static string ExtractItemKey(string itemDataName)
        {
            if (string.IsNullOrWhiteSpace(itemDataName))
            {
                return string.Empty;
            }

            const string suffix = "_ItemTupleData";
            if (itemDataName.EndsWith(suffix))
            {
                return itemDataName.Substring(0, itemDataName.Length - suffix.Length);
            }

            return itemDataName.Trim();
        }

        private static string NormalizeKey(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return string.Empty;
            }

            string normalized = value.Trim();
            normalized = normalized.Replace("_ItemTupleData", string.Empty);
            normalized = normalized.Replace("_SoundData", string.Empty);
            return normalized.ToLowerInvariant();
        }

        private static void EnsureFolderHierarchy(string folderPath)
        {
            string[] parts = folderPath.Split('/');
            if (parts.Length == 0)
            {
                return;
            }

            string currentPath = parts[0];

            for (int i = 1; i < parts.Length; i++)
            {
                string nextPath = currentPath + "/" + parts[i];
                if (!AssetDatabase.IsValidFolder(nextPath))
                {
                    AssetDatabase.CreateFolder(currentPath, parts[i]);
                }

                currentPath = nextPath;
            }
        }
    }
}
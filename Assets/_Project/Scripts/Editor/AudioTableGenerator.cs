using System.Collections.Generic;
using UnityEditor;
using UnityEditor.Localization;
using UnityEngine;
using UnityEngine.Localization;
using UnityEngine.Localization.Tables;

namespace SpecialEducationGames
{
    public static class AudioTableGenerator
    {
        private const string AudioRootPath = "Assets/_Project/Audio";
        private const string LocalizationRootPath = "Assets/_Project/Localization";
        private const string AudioTableName = "AudioTable";

        [MenuItem("SEG/Generate AudioTable From Audio Folder")]
        public static void Generate()
        {
            if (!AssetDatabase.IsValidFolder(AudioRootPath))
            {
                Debug.LogError($"Audio klasörü bulunamadý: {AudioRootPath}");
                return;
            }

            EnsureFolder(LocalizationRootPath);

            AssetTableCollection collection = GetOrCreateAudioTableCollection();
            if (collection == null)
            {
                Debug.LogError("AudioTable oluþturulamadý.");
                return;
            }

            LocalePair localePair = GetLocalePair();
            if (localePair.EnglishLocale == null && localePair.TurkishLocale == null)
            {
                Debug.LogError("Ne English ne de Turkish locale bulundu.");
                return;
            }

            string[] guids = AssetDatabase.FindAssets("t:AudioClip", new[] { AudioRootPath });

            int addedCount = 0;
            int skippedDuplicateCount = 0;

            Dictionary<string, string> usedKeys = new Dictionary<string, string>(System.StringComparer.OrdinalIgnoreCase);

            for (int i = 0; i < guids.Length; i++)
            {
                string assetPath = AssetDatabase.GUIDToAssetPath(guids[i]);
                AudioClip clip = AssetDatabase.LoadAssetAtPath<AudioClip>(assetPath);
                if (clip == null)
                {
                    continue;
                }

                string key = clip.name;

                if (usedKeys.TryGetValue(key, out string existingPath))
                {
                    skippedDuplicateCount++;
                    Debug.LogWarning($"Ayný key zaten var, atlandý. Key: {key}, Ýlk Path: {existingPath}, Atlanan Path: {assetPath}");
                    continue;
                }

                usedKeys.Add(key, assetPath);

                if (localePair.EnglishLocale != null)
                {
                    collection.AddAssetToTable(localePair.EnglishLocale.Identifier, key, clip);
                }

                if (localePair.TurkishLocale != null)
                {
                    collection.AddAssetToTable(localePair.TurkishLocale.Identifier, key, clip);
                }

                addedCount++;
            }

            if (collection.SharedData != null)
            {
                EditorUtility.SetDirty(collection.SharedData);
            }

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            Debug.Log($"AudioTable tamamlandý. Eklenen: {addedCount}, Çakýþma nedeniyle atlanan: {skippedDuplicateCount}");
        }

        private static AssetTableCollection GetOrCreateAudioTableCollection()
        {
            AssetTableCollection collection = LocalizationEditorSettings.GetAssetTableCollection(AudioTableName);
            if (collection != null)
            {
                return collection;
            }

            return LocalizationEditorSettings.CreateAssetTableCollection(AudioTableName, LocalizationRootPath);
        }

        private static LocalePair GetLocalePair()
        {
            LocalePair pair = new LocalePair();

            var locales = LocalizationEditorSettings.GetLocales();
            if (locales == null)
            {
                return pair;
            }

            for (int i = 0; i < locales.Count; i++)
            {
                Locale locale = locales[i];
                if (locale == null)
                {
                    continue;
                }

                string code = locale.Identifier.Code;

                if (pair.EnglishLocale == null && code.StartsWith("en"))
                {
                    pair.EnglishLocale = locale;
                }

                if (pair.TurkishLocale == null && code.StartsWith("tr"))
                {
                    pair.TurkishLocale = locale;
                }
            }

            if (pair.EnglishLocale == null)
            {
                Debug.LogWarning("English locale bulunamadý.");
            }

            if (pair.TurkishLocale == null)
            {
                Debug.LogWarning("Turkish locale bulunamadý.");
            }

            return pair;
        }

        private static void EnsureFolder(string folderPath)
        {
            if (AssetDatabase.IsValidFolder(folderPath))
            {
                return;
            }

            string normalizedPath = folderPath.Replace("\\", "/");
            string[] parts = normalizedPath.Split('/');

            string currentPath = parts[0];
            for (int i = 1; i < parts.Length; i++)
            {
                string nextPath = $"{currentPath}/{parts[i]}";
                if (!AssetDatabase.IsValidFolder(nextPath))
                {
                    AssetDatabase.CreateFolder(currentPath, parts[i]);
                }

                currentPath = nextPath;
            }
        }

        private sealed class LocalePair
        {
            public Locale EnglishLocale;
            public Locale TurkishLocale;
        }
    }
}
using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Localization;

namespace SpecialEducationGames
{
    public static class SoundDataGenerator
    {
        private const string AudioRootPath = "Assets/_Project/Audio";
        private const string OutputRootPath = "Assets/_Project/Scriptables/SoundDatas";
        private const string AudioTableName = "AudioTable";

        private static readonly HashSet<EffectType> Colors = new HashSet<EffectType>
        {
            EffectType.Black,
            EffectType.Blue,
            EffectType.Brown,
            EffectType.Gray,
            EffectType.Green,
            EffectType.Pink,
            EffectType.Purple,
            EffectType.Red,
            EffectType.White,
            EffectType.Yellow,
            EffectType.Orange
        };

        private static readonly HashSet<EffectType> Numbers = new HashSet<EffectType>
        {
            EffectType.One,
            EffectType.Two,
            EffectType.Three,
            EffectType.Four,
            EffectType.Five,
            EffectType.Six,
            EffectType.Seven,
            EffectType.Eight,
            EffectType.Nine,
            EffectType.GuessNextNumber,
            EffectType.TryOneMore,
            EffectType.CompareNumbers,
            EffectType.And,
            EffectType.Greater,
            EffectType.Equal,
            EffectType.Less,
            EffectType.StartCompareNumbers,
            EffectType.StartGuessNextNumber
        };

        private static readonly HashSet<EffectType> Fruits01 = new HashSet<EffectType>
        {
            EffectType.Banana,
            EffectType.Pear,
            EffectType.Grape
        };

        private static readonly HashSet<EffectType> Fruits02 = new HashSet<EffectType>
        {
            EffectType.Cherry,
            EffectType.Strawberry,
            EffectType.Tomato
        };

        private static readonly HashSet<EffectType> Fruits03 = new HashSet<EffectType>
        {
            EffectType.Potato,
            EffectType.Cabbage,
            EffectType.Eggplant
        };

        private static readonly HashSet<EffectType> Animals = new HashSet<EffectType>
        {
            EffectType.Bear,
            EffectType.Cat,
            EffectType.Chicken,
            EffectType.Cock,
            EffectType.Cow,
            EffectType.Dog,
            EffectType.Frog,
            EffectType.Giraffe,
            EffectType.Horse,
            EffectType.Rabbit,
            EffectType.Sheep
        };

        [MenuItem("SEG/Generate SoundData Assets From Audio Folder")]
        public static void Generate()
        {
            if (!AssetDatabase.IsValidFolder(AudioRootPath))
            {
                Debug.LogError($"Audio klasörü bulunamadý: {AudioRootPath}");
                return;
            }

            EnsureFolder(OutputRootPath);

            Dictionary<string, EffectType> normalizedEffectMap = CreateEffectTypeMap();

            string[] guids = AssetDatabase.FindAssets("t:AudioClip", new[] { AudioRootPath });

            int createdCount = 0;
            int updatedCount = 0;
            int skippedCount = 0;

            for (int i = 0; i < guids.Length; i++)
            {
                string audioPath = AssetDatabase.GUIDToAssetPath(guids[i]);
                AudioClip clip = AssetDatabase.LoadAssetAtPath<AudioClip>(audioPath);
                if (clip == null)
                {
                    continue;
                }

                string key = clip.name;
                string normalizedKey = Normalize(key);

                if (!normalizedEffectMap.TryGetValue(normalizedKey, out EffectType effectType))
                {
                    skippedCount++;
                    Debug.LogWarning($"EffectType eþleþmesi bulunamadý. Audio: {audioPath}");
                    continue;
                }

                string groupName = GetGroupName(effectType);
                if (string.IsNullOrEmpty(groupName))
                {
                    skippedCount++;
                    Debug.LogWarning($"Grup bulunamadý. EffectType: {effectType}, Audio: {audioPath}");
                    continue;
                }

                string groupFolder = $"{OutputRootPath}/{groupName}";
                EnsureFolder(groupFolder);

                string assetPath = $"{groupFolder}/{effectType}_SoundData.asset";
                SoundData soundData = AssetDatabase.LoadAssetAtPath<SoundData>(assetPath);
                bool isNew = soundData == null;

                if (isNew)
                {
                    soundData = ScriptableObject.CreateInstance<SoundData>();
                }

                soundData.GameSound = effectType;
                soundData.LocalizedAudioClip = new LocalizedAudioClip
                {
                    TableReference = AudioTableName,
                    TableEntryReference = key
                };

                if (isNew)
                {
                    AssetDatabase.CreateAsset(soundData, assetPath);
                    createdCount++;
                }
                else
                {
                    EditorUtility.SetDirty(soundData);
                    updatedCount++;
                }
            }

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            Debug.Log($"SoundData üretimi tamamlandý. Oluþturulan: {createdCount}, Güncellenen: {updatedCount}, Atlanan: {skippedCount}");
        }

        private static Dictionary<string, EffectType> CreateEffectTypeMap()
        {
            Dictionary<string, EffectType> map = new Dictionary<string, EffectType>(StringComparer.OrdinalIgnoreCase);

            Array values = Enum.GetValues(typeof(EffectType));
            for (int i = 0; i < values.Length; i++)
            {
                EffectType effectType = (EffectType)values.GetValue(i);
                if (effectType == EffectType.None)
                {
                    continue;
                }

                string normalizedName = Normalize(effectType.ToString());
                if (!map.ContainsKey(normalizedName))
                {
                    map.Add(normalizedName, effectType);
                }
            }

            return map;
        }

        private static string GetGroupName(EffectType effectType)
        {
            if (Colors.Contains(effectType))
            {
                return "Colors";
            }

            if (Numbers.Contains(effectType))
            {
                return "Numbers";
            }

            if (Fruits01.Contains(effectType))
            {
                return "Fruits_01";
            }

            if (Fruits02.Contains(effectType))
            {
                return "Fruits_02";
            }

            if (Fruits03.Contains(effectType))
            {
                return "Fruits_03";
            }

            if (Animals.Contains(effectType))
            {
                return "Animals";
            }

            return null;
        }

        private static string Normalize(string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return string.Empty;
            }

            char[] buffer = new char[value.Length];
            int index = 0;

            for (int i = 0; i < value.Length; i++)
            {
                char c = value[i];
                if (char.IsLetterOrDigit(c))
                {
                    buffer[index] = char.ToLowerInvariant(c);
                    index++;
                }
            }

            return new string(buffer, 0, index);
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
    }
}
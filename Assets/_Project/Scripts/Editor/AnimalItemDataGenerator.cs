using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEditor.Localization;
using UnityEngine;
using UnityEngine.Localization;
using UnityEngine.Localization.Tables;

namespace SpecialEducationGames
{
    public static class AnimalItemDataGenerator
    {
        private const string RootFolder = "Assets/_Project/Scriptables/ItemDatas";
        private const string SpriteFolder = "Assets/_Project/UI/Animals";
        private const string SoundFolder = "Assets/_Project/Scriptables/SoundDatas/Animals";
        private const string LocalizationTableName = "ItemTable";
        private const string MenuPath = "Tools/SEG/Generate Animal ItemDatas";

        private static readonly AnimalDefinition[] Animals =
        {
            // Level 1
            new AnimalDefinition("Level01_HomeAndNearby", "Cat", "Kitten"),
            new AnimalDefinition("Level01_HomeAndNearby", "Dog", "Puppy"),
            new AnimalDefinition("Level01_HomeAndNearby", "Bird", "Budgie", "Budgerigar", "Canary"),
            new AnimalDefinition("Level01_HomeAndNearby", "Fish", "Goldfish"),
            new AnimalDefinition("Level01_HomeAndNearby", "Rabbit", "Bunny"),
            new AnimalDefinition("Level01_HomeAndNearby", "Turtle", "Tortoise"),
            new AnimalDefinition("Level01_HomeAndNearby", "Hamster"),
            new AnimalDefinition("Level01_HomeAndNearby", "Chick", "ChickenBaby"),
            new AnimalDefinition("Level01_HomeAndNearby", "Duck", "Duckling"),
            new AnimalDefinition("Level01_HomeAndNearby", "Butterfly"),

            // Level 2
            new AnimalDefinition("Level02_FarmLife", "Cow"),
            new AnimalDefinition("Level02_FarmLife", "Sheep", "Lamb"),
            new AnimalDefinition("Level02_FarmLife", "Goat"),
            new AnimalDefinition("Level02_FarmLife", "Horse"),
            new AnimalDefinition("Level02_FarmLife", "Donkey"),
            new AnimalDefinition("Level02_FarmLife", "Chicken", "Hen"),
            new AnimalDefinition("Level02_FarmLife", "Rooster", "Cock"),
            new AnimalDefinition("Level02_FarmLife", "Turkey"),
            new AnimalDefinition("Level02_FarmLife", "Goose", "Geese"),
            new AnimalDefinition("Level02_FarmLife", "Bull", "Ox", "Oxen"),

            // Level 3
            new AnimalDefinition("Level03_WildAndIconic", "Lion"),
            new AnimalDefinition("Level03_WildAndIconic", "Elephant"),
            new AnimalDefinition("Level03_WildAndIconic", "Giraffe"),
            new AnimalDefinition("Level03_WildAndIconic", "Monkey", "Chimp"),
            new AnimalDefinition("Level03_WildAndIconic", "Bear"),
            new AnimalDefinition("Level03_WildAndIconic", "Tiger"),
            new AnimalDefinition("Level03_WildAndIconic", "Hippopotamus", "Hippo"),
            new AnimalDefinition("Level03_WildAndIconic", "Wolf"),
            new AnimalDefinition("Level03_WildAndIconic", "Zebra"),
            new AnimalDefinition("Level03_WildAndIconic", "Deer", "Stag"),

            // Level 4
            new AnimalDefinition("Level04_SeaForestAndSmallFriends", "Dolphin"),
            new AnimalDefinition("Level04_SeaForestAndSmallFriends", "Shark"),
            new AnimalDefinition("Level04_SeaForestAndSmallFriends", "Whale"),
            new AnimalDefinition("Level04_SeaForestAndSmallFriends", "Octopus"),
            new AnimalDefinition("Level04_SeaForestAndSmallFriends", "Bee"),
            new AnimalDefinition("Level04_SeaForestAndSmallFriends", "Ladybug", "Ladybird"),
            new AnimalDefinition("Level04_SeaForestAndSmallFriends", "Ant"),
            new AnimalDefinition("Level04_SeaForestAndSmallFriends", "Squirrel"),
            new AnimalDefinition("Level04_SeaForestAndSmallFriends", "Hedgehog"),
            new AnimalDefinition("Level04_SeaForestAndSmallFriends", "Owl"),

            // Level 5
            new AnimalDefinition("Level05_ExoticAndComparative", "Kangaroo"),
            new AnimalDefinition("Level05_ExoticAndComparative", "Penguin"),
            new AnimalDefinition("Level05_ExoticAndComparative", "Camel"),
            new AnimalDefinition("Level05_ExoticAndComparative", "Crocodile"),
            new AnimalDefinition("Level05_ExoticAndComparative", "Chameleon"),
            new AnimalDefinition("Level05_ExoticAndComparative", "Gorilla"),
            new AnimalDefinition("Level05_ExoticAndComparative", "Rhinoceros", "Rhino"),
            new AnimalDefinition("Level05_ExoticAndComparative", "Ostrich"),
            new AnimalDefinition("Level05_ExoticAndComparative", "Flamingo"),
            new AnimalDefinition("Level05_ExoticAndComparative", "Bat")
        };

        [MenuItem(MenuPath)]
        public static void Generate()
        {
            EnsureFolderHierarchy(RootFolder);

            Dictionary<string, Sprite> spriteMap = BuildSpriteMap();
            Dictionary<string, SoundData> soundMap = BuildSoundMap();
            Dictionary<string, long> localizationEntryMap = BuildLocalizationEntryMap();

            int createdCount = 0;
            int updatedCount = 0;
            int spriteAssignedCount = 0;
            int soundAssignedCount = 0;
            int localizedAssignedCount = 0;
            int spriteMissingCount = 0;
            int soundMissingCount = 0;
            int localizedMissingCount = 0;

            for (int i = 0; i < Animals.Length; i++)
            {
                AnimalDefinition animal = Animals[i];
                string levelFolder = RootFolder + "/" + animal.LevelFolder;
                EnsureFolderHierarchy(levelFolder);

                string assetFileName = animal.EnglishName + "_ItemTupleData.asset";
                string assetPath = levelFolder + "/" + assetFileName;

                ItemData itemData = AssetDatabase.LoadAssetAtPath<ItemData>(assetPath);
                bool isNew = itemData == null;

                if (isNew)
                {
                    itemData = ScriptableObject.CreateInstance<ItemData>();
                    itemData.name = Path.GetFileNameWithoutExtension(assetPath);
                    AssetDatabase.CreateAsset(itemData, assetPath);
                    createdCount++;
                }
                else
                {
                    updatedCount++;
                }

                itemData.Name = animal.EnglishName;
                itemData.Sprite = FindBestMatch(spriteMap, animal.SearchKeys);
                itemData.Audio = FindBestMatch(soundMap, animal.SearchKeys);
                itemData.LocalizedName = CreateLocalizedString(localizationEntryMap, animal.SearchKeys);

                if (itemData.Sprite != null)
                {
                    spriteAssignedCount++;
                }
                else
                {
                    spriteMissingCount++;
                    Debug.LogWarning("Sprite bulunamadý: " + animal.EnglishName, itemData);
                }

                if (itemData.Audio != null)
                {
                    soundAssignedCount++;
                }
                else
                {
                    soundMissingCount++;
                    Debug.LogWarning("SoundData bulunamadý: " + animal.EnglishName, itemData);
                }

                if (itemData.LocalizedName != null)
                {
                    localizedAssignedCount++;
                }
                else
                {
                    localizedMissingCount++;
                    Debug.LogWarning("Localization entry bulunamadý: " + animal.EnglishName + " | Table: " + LocalizationTableName, itemData);
                }

                EditorUtility.SetDirty(itemData);
            }

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            EditorUtility.DisplayDialog(
                "Animal ItemData Generator",
                "Ýþlem tamamlandý.\n\n" +
                "Created: " + createdCount + "\n" +
                "Updated: " + updatedCount + "\n\n" +
                "Sprite Assigned: " + spriteAssignedCount + "\n" +
                "Sprite Missing: " + spriteMissingCount + "\n\n" +
                "Sound Assigned: " + soundAssignedCount + "\n" +
                "Sound Missing: " + soundMissingCount + "\n\n" +
                "Localized Assigned: " + localizedAssignedCount + "\n" +
                "Localized Missing: " + localizedMissingCount,
                "OK");
        }

        private static Dictionary<string, Sprite> BuildSpriteMap()
        {
            Dictionary<string, Sprite> map = new Dictionary<string, Sprite>();
            string[] guids = AssetDatabase.FindAssets("t:Sprite", new[] { SpriteFolder });

            for (int i = 0; i < guids.Length; i++)
            {
                string path = AssetDatabase.GUIDToAssetPath(guids[i]);
                Object[] assetsAtPath = AssetDatabase.LoadAllAssetsAtPath(path);

                for (int j = 0; j < assetsAtPath.Length; j++)
                {
                    Sprite sprite = assetsAtPath[j] as Sprite;
                    if (sprite == null)
                    {
                        continue;
                    }

                    AddIfMissing(map, sprite.name, sprite);
                    AddIfMissing(map, Path.GetFileNameWithoutExtension(path), sprite);
                }
            }

            return map;
        }

        private static Dictionary<string, SoundData> BuildSoundMap()
        {
            Dictionary<string, SoundData> map = new Dictionary<string, SoundData>();
            string[] guids = AssetDatabase.FindAssets("t:SoundData", new[] { SoundFolder });

            for (int i = 0; i < guids.Length; i++)
            {
                string path = AssetDatabase.GUIDToAssetPath(guids[i]);
                SoundData soundData = AssetDatabase.LoadAssetAtPath<SoundData>(path);
                if (soundData == null)
                {
                    continue;
                }

                AddIfMissing(map, soundData.name, soundData);
                AddIfMissing(map, Path.GetFileNameWithoutExtension(path), soundData);
            }

            return map;
        }

        private static Dictionary<string, long> BuildLocalizationEntryMap()
        {
            Dictionary<string, long> map = new Dictionary<string, long>();
            StringTableCollection collection = LocalizationEditorSettings.GetStringTableCollection(LocalizationTableName);

            if (collection == null || collection.SharedData == null || collection.SharedData.Entries == null)
            {
                Debug.LogWarning("Localization table bulunamadý: " + LocalizationTableName);
                return map;
            }

            for (int i = 0; i < collection.SharedData.Entries.Count; i++)
            {
                SharedTableData.SharedTableEntry entry = collection.SharedData.Entries[i];
                if (entry == null || string.IsNullOrWhiteSpace(entry.Key))
                {
                    continue;
                }

                string normalizedKey = Normalize(entry.Key);
                if (!map.ContainsKey(normalizedKey))
                {
                    map.Add(normalizedKey, entry.Id);
                }
            }

            return map;
        }

        private static LocalizedString CreateLocalizedString(Dictionary<string, long> localizationEntryMap, string[] searchKeys)
        {
            for (int i = 0; i < searchKeys.Length; i++)
            {
                string normalizedKey = Normalize(searchKeys[i]);
                if (localizationEntryMap.TryGetValue(normalizedKey, out long entryId))
                {
                    LocalizedString localizedString = new LocalizedString();
                    localizedString.TableReference = LocalizationTableName;
                    localizedString.TableEntryReference = entryId;
                    return localizedString;
                }
            }

            return null;
        }

        private static T FindBestMatch<T>(Dictionary<string, T> map, string[] searchKeys) where T : Object
        {
            for (int i = 0; i < searchKeys.Length; i++)
            {
                string normalizedKey = Normalize(searchKeys[i]);
                if (map.TryGetValue(normalizedKey, out T value))
                {
                    return value;
                }
            }

            return null;
        }

        private static void AddIfMissing<T>(Dictionary<string, T> map, string rawKey, T value)
        {
            string normalizedKey = Normalize(rawKey);
            if (string.IsNullOrEmpty(normalizedKey))
            {
                return;
            }

            if (!map.ContainsKey(normalizedKey))
            {
                map.Add(normalizedKey, value);
            }
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

        private static string Normalize(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return string.Empty;
            }

            string lower = value.Trim().ToLowerInvariant();
            lower = lower.Replace("_itemtupledata", string.Empty);
            lower = lower.Replace("_sounddata", string.Empty);
            lower = lower.Replace("itemtupledata", string.Empty);
            lower = lower.Replace("sounddata", string.Empty);

            StringBuilder builder = new StringBuilder(lower.Length);
            for (int i = 0; i < lower.Length; i++)
            {
                char c = lower[i];
                if (char.IsLetterOrDigit(c))
                {
                    builder.Append(c);
                }
            }

            return builder.ToString();
        }

        private sealed class AnimalDefinition
        {
            public readonly string LevelFolder;
            public readonly string EnglishName;
            public readonly string[] SearchKeys;

            public AnimalDefinition(string levelFolder, string englishName, params string[] aliases)
            {
                LevelFolder = levelFolder;
                EnglishName = englishName;

                int aliasCount = aliases == null ? 0 : aliases.Length;
                SearchKeys = new string[aliasCount + 1];
                SearchKeys[0] = englishName;

                for (int i = 0; i < aliasCount; i++)
                {
                    SearchKeys[i + 1] = aliases[i];
                }
            }
        }
    }
}
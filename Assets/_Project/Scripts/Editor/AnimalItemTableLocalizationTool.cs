using System.Collections.Generic;
using UnityEditor;
using UnityEditor.Localization;
using UnityEngine;
using UnityEngine.Localization;
using UnityEngine.Localization.Tables;

namespace SpecialEducationGames
{
    public static class AnimalItemTableLocalizationTool
    {
        private const string ItemDataFolder = "Assets/_Project/Scriptables/ItemDatas/Animals";
        private const string LocalizationTableName = "ItemTable";
        private const string MenuPath = "Tools/SEG/Fix Animal ItemData Localization";

        private static readonly Dictionary<string, string> TurkishMap = new Dictionary<string, string>
        {
            { "Cat", "Kedi" },
            { "Dog", "Köpek" },
            { "Bird", "Kuþ" },
            { "Fish", "Balýk" },
            { "Rabbit", "Tavþan" },
            { "Turtle", "Kaplumbaða" },
            { "Hamster", "Hamster" },
            { "Chick", "Civciv" },
            { "Duck", "Ördek" },
            { "Butterfly", "Kelebek" },

            { "Cow", "Ýnek" },
            { "Sheep", "Koyun" },
            { "Goat", "Keçi" },
            { "Horse", "At" },
            { "Donkey", "Eþek" },
            { "Chicken", "Tavuk" },
            { "Rooster", "Horoz" },
            { "Turkey", "Hindi" },
            { "Goose", "Kaz" },
            { "Bull", "Boða" },

            { "Lion", "Aslan" },
            { "Elephant", "Fil" },
            { "Giraffe", "Zürafa" },
            { "Monkey", "Maymun" },
            { "Bear", "Ayý" },
            { "Tiger", "Kaplan" },
            { "Hippopotamus", "Su Aygýrý" },
            { "Wolf", "Kurt" },
            { "Zebra", "Zebra" },
            { "Deer", "Geyik" },

            { "Dolphin", "Yunus" },
            { "Shark", "Köpek Balýðý" },
            { "Whale", "Balina" },
            { "Octopus", "Ahtapot" },
            { "Bee", "Arý" },
            { "Ladybug", "Uður Böceði" },
            { "Ant", "Karýnca" },
            { "Squirrel", "Sincap" },
            { "Hedgehog", "Kirpi" },
            { "Owl", "Baykuþ" },

            { "Kangaroo", "Kanguru" },
            { "Penguin", "Penguen" },
            { "Camel", "Deve" },
            { "Crocodile", "Timsah" },
            { "Chameleon", "Bukalemun" },
            { "Gorilla", "Goril" },
            { "Rhinoceros", "Gergedan" },
            { "Ostrich", "Devekuþu" },
            { "Flamingo", "Flamingo" },
            { "Bat", "Yarasa" }
        };

        [MenuItem(MenuPath)]
        public static void FixLocalization()
        {
            StringTableCollection collection = LocalizationEditorSettings.GetStringTableCollection(LocalizationTableName);
            if (collection == null || collection.SharedData == null)
            {
                EditorUtility.DisplayDialog(
                    "Hata",
                    LocalizationTableName + " localization table bulunamadý.",
                    "Tamam");
                return;
            }

            StringTable englishTable = FindTableByLanguageCode(collection, "en");
            StringTable turkishTable = FindTableByLanguageCode(collection, "tr");

            if (englishTable == null || turkishTable == null)
            {
                EditorUtility.DisplayDialog(
                    "Hata",
                    "English veya Turkish StringTable bulunamadý.",
                    "Tamam");
                return;
            }

            string[] itemGuids = AssetDatabase.FindAssets("t:ItemData", new[] { ItemDataFolder });

            int scannedCount = 0;
            int fixedCount = 0;
            int skippedCount = 0;
            int missingTranslationCount = 0;

            for (int i = 0; i < itemGuids.Length; i++)
            {
                string assetPath = AssetDatabase.GUIDToAssetPath(itemGuids[i]);
                ItemData itemData = AssetDatabase.LoadAssetAtPath<ItemData>(assetPath);
                if (itemData == null)
                {
                    continue;
                }

                scannedCount++;

                if (!IsLocalizedNameMissing(itemData))
                {
                    skippedCount++;
                    continue;
                }

                string key = ExtractKey(itemData.name);
                if (string.IsNullOrWhiteSpace(key))
                {
                    Debug.LogWarning("Key üretilemedi: " + assetPath, itemData);
                    continue;
                }

                if (!TurkishMap.TryGetValue(key, out string turkishValue))
                {
                    missingTranslationCount++;
                    Debug.LogWarning("Türkçe karþýlýk tanýmlý deðil: " + key, itemData);
                    continue;
                }

                SharedTableData.SharedTableEntry sharedEntry = collection.SharedData.GetEntry(key);
                if (sharedEntry == null)
                {
                    sharedEntry = collection.SharedData.AddKey(key);
                    EditorUtility.SetDirty(collection.SharedData);
                }

                SetTableValue(englishTable, sharedEntry.Id, key);
                SetTableValue(turkishTable, sharedEntry.Id, turkishValue);

                itemData.Name = key;
                itemData.LocalizedName = new LocalizedString
                {
                    TableReference = LocalizationTableName,
                    TableEntryReference = sharedEntry.Id
                };

                EditorUtility.SetDirty(itemData);
                fixedCount++;

                Debug.Log("Localization atandý: " + itemData.name + " -> " + key, itemData);
            }

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            EditorUtility.DisplayDialog(
                "Ýþlem Tamamlandý",
                "Taranan: " + scannedCount + "\n" +
                "Düzeltilen: " + fixedCount + "\n" +
                "Atlanan: " + skippedCount + "\n" +
                "Çevirisi Eksik: " + missingTranslationCount,
                "Tamam");
        }

        private static bool IsLocalizedNameMissing(ItemData itemData)
        {
            return itemData.LocalizedName == null || itemData.LocalizedName.IsEmpty;
        }

        private static string ExtractKey(string assetName)
        {
            if (string.IsNullOrWhiteSpace(assetName))
            {
                return string.Empty;
            }

            const string suffix = "_ItemTupleData";
            if (assetName.EndsWith(suffix))
            {
                return assetName.Substring(0, assetName.Length - suffix.Length);
            }

            return assetName;
        }

        private static void SetTableValue(StringTable table, long entryId, string value)
        {
            StringTableEntry entry = table.GetEntry(entryId);
            if (entry == null)
            {
                table.AddEntry(entryId, value);
            }
            else
            {
                entry.Value = value;
            }

            EditorUtility.SetDirty(table);
        }

        private static StringTable FindTableByLanguageCode(StringTableCollection collection, string languageCode)
        {
            for (int i = 0; i < collection.StringTables.Count; i++)
            {
                StringTable table = collection.StringTables[i];
                if (table == null)
                {
                    continue;
                }

                string code = table.LocaleIdentifier.Code;
                if (MatchesLanguageCode(code, languageCode))
                {
                    return table;
                }
            }

            return null;
        }

        private static bool MatchesLanguageCode(string localeCode, string languageCode)
        {
            if (string.IsNullOrWhiteSpace(localeCode) || string.IsNullOrWhiteSpace(languageCode))
            {
                return false;
            }

            return localeCode == languageCode || localeCode.StartsWith(languageCode + "-");
        }
    }
}

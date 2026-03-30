using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.Localization;
using UnityEngine;
using UnityEngine.Localization;
using UnityEngine.Localization.Tables;

namespace SpecialEducationGames
{
    public static class EffectTypeItemTupleDataGenerator
    {
        private const string OutputRootPath = "Assets/_Project/Scriptables";
        private const string SpriteSearchRootPath = "Assets/_Project/UI";
        private const string LocalizationRootPath = "Assets/_Project/Localization";
        private const string ItemTableName = "ItemTable";

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

        [MenuItem("SEG/Generate ItemTupleData Assets From EffectType")]
        public static void Generate()
        {
            EnsureFolder(OutputRootPath);
            EnsureFolder(LocalizationRootPath);

            StringTableCollection collection = GetOrCreateItemTableCollection();
            LocaleTablePair localePair = GetLocalePair();

            int createdCount = 0;
            int updatedCount = 0;
            int missingSpriteCount = 0;
            List<string> skippedEffects = new List<string>();

            foreach (EffectType effectType in System.Enum.GetValues(typeof(EffectType)))
            {
                if (effectType == EffectType.None)
                {
                    continue;
                }

                string groupName = GetGroupName(effectType);
                if (string.IsNullOrEmpty(groupName))
                {
                    skippedEffects.Add(effectType.ToString());
                    continue;
                }

                string groupFolder = $"{OutputRootPath}/{groupName}";
                EnsureFolder(groupFolder);

                string itemName = effectType.ToString();
                string assetPath = $"{groupFolder}/{itemName}_ItemTupleData.asset";

                ItemTupleData asset = AssetDatabase.LoadAssetAtPath<ItemTupleData>(assetPath);
                bool isNewAsset = asset == null;

                if (isNewAsset)
                {
                    asset = ScriptableObject.CreateInstance<ItemTupleData>();
                }

                LocalizedTexts texts = GetLocalizedTexts(effectType);
                EnsureLocalizationEntry(collection, localePair, itemName, texts);

                Sprite sprite = FindSprite(itemName);
                if (sprite == null)
                {
                    missingSpriteCount++;
                }

                asset.Name = itemName;
                asset.Sprite = sprite;
                asset.Audio = effectType;
                asset.LocalizedName = new LocalizedString
                {
                    TableReference = ItemTableName,
                    TableEntryReference = itemName
                };

                if (isNewAsset)
                {
                    AssetDatabase.CreateAsset(asset, assetPath);
                    createdCount++;
                }
                else
                {
                    EditorUtility.SetDirty(asset);
                    updatedCount++;
                }
            }

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            Debug.Log(
                $"ItemTupleData üretimi tamamlandý. " +
                $"Oluþturulan: {createdCount}, Güncellenen: {updatedCount}, Sprite bulunamayan: {missingSpriteCount}, " +
                $"Atlanan: {skippedEffects.Count}" +
                (skippedEffects.Count > 0 ? $" -> {string.Join(", ", skippedEffects)}" : string.Empty));
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

        private static Sprite FindSprite(string spriteName)
        {
            if (!AssetDatabase.IsValidFolder(SpriteSearchRootPath))
            {
                return null;
            }

            string[] guids = AssetDatabase.FindAssets($"t:Sprite {spriteName}", new[] { SpriteSearchRootPath });
            for (int i = 0; i < guids.Length; i++)
            {
                string path = AssetDatabase.GUIDToAssetPath(guids[i]);
                Sprite sprite = AssetDatabase.LoadAssetAtPath<Sprite>(path);
                if (sprite != null && string.Equals(sprite.name, spriteName, System.StringComparison.OrdinalIgnoreCase))
                {
                    return sprite;
                }
            }

            guids = AssetDatabase.FindAssets("t:Sprite", new[] { SpriteSearchRootPath });
            for (int i = 0; i < guids.Length; i++)
            {
                string path = AssetDatabase.GUIDToAssetPath(guids[i]);
                Sprite sprite = AssetDatabase.LoadAssetAtPath<Sprite>(path);
                if (sprite != null && string.Equals(sprite.name, spriteName, System.StringComparison.OrdinalIgnoreCase))
                {
                    return sprite;
                }
            }

            return null;
        }

        private static StringTableCollection GetOrCreateItemTableCollection()
        {
            StringTableCollection collection = LocalizationEditorSettings.GetStringTableCollection(ItemTableName);
            if (collection != null)
            {
                return collection;
            }

            collection = LocalizationEditorSettings.CreateStringTableCollection(ItemTableName, LocalizationRootPath);
            return collection;
        }

        private static void EnsureLocalizationEntry(
            StringTableCollection collection,
            LocaleTablePair localePair,
            string key,
            LocalizedTexts texts)
        {
            if (collection == null)
            {
                return;
            }

            if (localePair.EnglishTable != null && localePair.EnglishTable.GetEntry(key) == null)
            {
                localePair.EnglishTable.AddEntry(key, texts.English);
                EditorUtility.SetDirty(localePair.EnglishTable);
            }

            if (localePair.TurkishTable != null && localePair.TurkishTable.GetEntry(key) == null)
            {
                localePair.TurkishTable.AddEntry(key, texts.Turkish);
                EditorUtility.SetDirty(localePair.TurkishTable);
            }

            if (collection.SharedData != null)
            {
                EditorUtility.SetDirty(collection.SharedData);
            }
        }

        private static LocaleTablePair GetLocalePair()
        {
            LocaleTablePair pair = new LocaleTablePair();

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

            StringTableCollection collection = LocalizationEditorSettings.GetStringTableCollection(ItemTableName);
            if (collection != null)
            {
                if (pair.EnglishLocale != null)
                {
                    pair.EnglishTable = collection.GetTable(pair.EnglishLocale.Identifier) as StringTable;
                }

                if (pair.TurkishLocale != null)
                {
                    pair.TurkishTable = collection.GetTable(pair.TurkishLocale.Identifier) as StringTable;
                }
            }

            if (pair.EnglishLocale == null)
            {
                Debug.LogWarning("English locale bulunamadý. ItemTable English entry'leri oluþturulamadý.");
            }

            if (pair.TurkishLocale == null)
            {
                Debug.LogWarning("Turkish locale bulunamadý. ItemTable Turkish entry'leri oluþturulamadý.");
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

        private static LocalizedTexts GetLocalizedTexts(EffectType effectType)
        {
            switch (effectType)
            {
                case EffectType.One: return new LocalizedTexts("One", "Bir");
                case EffectType.Two: return new LocalizedTexts("Two", "Ýki");
                case EffectType.Three: return new LocalizedTexts("Three", "Üç");
                case EffectType.Four: return new LocalizedTexts("Four", "Dört");
                case EffectType.Five: return new LocalizedTexts("Five", "Beþ");
                case EffectType.Six: return new LocalizedTexts("Six", "Altý");
                case EffectType.Seven: return new LocalizedTexts("Seven", "Yedi");
                case EffectType.Eight: return new LocalizedTexts("Eight", "Sekiz");
                case EffectType.Nine: return new LocalizedTexts("Nine", "Dokuz");

                case EffectType.GuessNextNumber: return new LocalizedTexts("Guess Next Number", "Sonraki Sayýyý Tahmin Et");
                case EffectType.TryOneMore: return new LocalizedTexts("Try One More", "Bir Kez Daha Dene");
                case EffectType.CompareNumbers: return new LocalizedTexts("Compare Numbers", "Sayýlarý Karþýlaþtýr");
                case EffectType.And: return new LocalizedTexts("And", "Ve");
                case EffectType.Greater: return new LocalizedTexts("Greater", "Büyüktür");
                case EffectType.Equal: return new LocalizedTexts("Equal", "Eþittir");
                case EffectType.Less: return new LocalizedTexts("Less", "Küçüktür");
                case EffectType.StartCompareNumbers: return new LocalizedTexts("Start Compare Numbers", "Sayýlarý Karþýlaþtýrmayý Baþlat");
                case EffectType.StartGuessNextNumber: return new LocalizedTexts("Start Guess Next Number", "Sonraki Sayýyý Tahmin Etmeyi Baþlat");

                case EffectType.Bear: return new LocalizedTexts("Bear", "Ayý");
                case EffectType.Cat: return new LocalizedTexts("Cat", "Kedi");
                case EffectType.Chicken: return new LocalizedTexts("Chicken", "Tavuk");
                case EffectType.Cock: return new LocalizedTexts("Cock", "Horoz");
                case EffectType.Cow: return new LocalizedTexts("Cow", "Ýnek");
                case EffectType.Dog: return new LocalizedTexts("Dog", "Köpek");
                case EffectType.Frog: return new LocalizedTexts("Frog", "Kurbaða");
                case EffectType.Giraffe: return new LocalizedTexts("Giraffe", "Zürafa");
                case EffectType.Horse: return new LocalizedTexts("Horse", "At");
                case EffectType.Rabbit: return new LocalizedTexts("Rabbit", "Tavþan");
                case EffectType.Sheep: return new LocalizedTexts("Sheep", "Koyun");

                case EffectType.Black: return new LocalizedTexts("Black", "Siyah");
                case EffectType.Blue: return new LocalizedTexts("Blue", "Mavi");
                case EffectType.Brown: return new LocalizedTexts("Brown", "Kahverengi");
                case EffectType.Gray: return new LocalizedTexts("Gray", "Gri");
                case EffectType.Green: return new LocalizedTexts("Green", "Yeþil");
                case EffectType.Pink: return new LocalizedTexts("Pink", "Pembe");
                case EffectType.Purple: return new LocalizedTexts("Purple", "Mor");
                case EffectType.Red: return new LocalizedTexts("Red", "Kýrmýzý");
                case EffectType.White: return new LocalizedTexts("White", "Beyaz");
                case EffectType.Yellow: return new LocalizedTexts("Yellow", "Sarý");
                case EffectType.Orange: return new LocalizedTexts("Orange", "Turuncu");

                case EffectType.Pear: return new LocalizedTexts("Pear", "Armut");
                case EffectType.Banana: return new LocalizedTexts("Banana", "Muz");
                case EffectType.Strawberry: return new LocalizedTexts("Strawberry", "Çilek");
                case EffectType.Cabbage: return new LocalizedTexts("Cabbage", "Lahana");
                case EffectType.Eggplant: return new LocalizedTexts("Eggplant", "Patlýcan");
                case EffectType.Tomato: return new LocalizedTexts("Tomato", "Domates");
                case EffectType.Potato: return new LocalizedTexts("Potato", "Patates");
                case EffectType.Cherry: return new LocalizedTexts("Cherry", "Kiraz");
                case EffectType.Grape: return new LocalizedTexts("Grape", "Üzüm");

                default: return new LocalizedTexts(effectType.ToString(), effectType.ToString());
            }
        }

        private readonly struct LocalizedTexts
        {
            public readonly string English;
            public readonly string Turkish;

            public LocalizedTexts(string english, string turkish)
            {
                English = english;
                Turkish = turkish;
            }
        }

        private sealed class LocaleTablePair
        {
            public Locale EnglishLocale;
            public Locale TurkishLocale;
            public StringTable EnglishTable;
            public StringTable TurkishTable;
        }
    }
}
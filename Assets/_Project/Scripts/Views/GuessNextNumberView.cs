using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    public class GuessNextNumberView : UIView<GuessNextNumberPresenter>
    {
        private const int VisualItemCount = 4;
        private const int ChoosableCount = 3;

        private List<ItemData> _itemTuples;

        private List<VisualItem> _visualItems;

        private List<Choosable> _choosables;

        private int _correctChoosableIndex;

        private Choosable _correctChoosable;

        public override void InitializeView()
        {
            _visualItems = new List<VisualItem>();
            _choosables = new List<Choosable>();
            _itemTuples = new List<ItemData>();

            if (GuessNextNumberManager.ItemTuples != null)
            {
                for (int i = 0; i < GuessNextNumberManager.ItemTuples.Count; i++)
                {
                    ItemData itemTuple = GuessNextNumberManager.ItemTuples[i];
                    if (itemTuple != null)
                    {
                        _itemTuples.Add(itemTuple);
                    }
                }
            }

            if (_itemTuples.Count < VisualItemCount)
            {
                Debug.LogError($"GuessNextNumberView baþlatýlamadý. En az {VisualItemCount} adet sýralý ItemTupleData atanmalý.");
                return;
            }

            StartCreating();
        }

        public void StartCreating()
        {
            if (_itemTuples.Count < VisualItemCount)
            {
                Debug.LogError($"Yeni tur oluþturulamadý. En az {VisualItemCount} adet sýralý ItemTupleData gerekli.");
                return;
            }

            CreateVisuals();
            CreateChoosables();
        }

        private void CreateVisuals()
        {
            _visualItems.Clear();

            int maxStartIndexExclusive = _itemTuples.Count - VisualItemCount + 1;
            int startIndex = Random.Range(0, maxStartIndexExclusive);

            _correctChoosableIndex = startIndex + (VisualItemCount - 1);

            for (int i = startIndex; i < startIndex + VisualItemCount; i++)
            {
                VisualItem visualItem = GuessNextNumberManager.VisualItemFactory.Create();
                visualItem.Initialize(_itemTuples[i], _itemTuples[i].Sprite, _itemTuples[i].Name);
                _visualItems.Add(visualItem);
            }

            _visualItems[^1].SetHidden();

            Presenter.OnCreateVisuals(_visualItems);
        }

        private void CreateChoosables()
        {
            _choosables.Clear();

            List<ItemData> tempItemTuples = new List<ItemData>(_itemTuples);

            _correctChoosable = GuessNextNumberManager.ChoosableFactory.Create();
            _correctChoosable.Initialize(null, tempItemTuples[_correctChoosableIndex].Name);
            _correctChoosable.SetCorrectAnswer(tempItemTuples[_correctChoosableIndex]);
            _choosables.Add(_correctChoosable);

            tempItemTuples.RemoveAt(_correctChoosableIndex);

            for (int i = 0; i < ChoosableCount - 1; i++)
            {
                int rnd = Random.Range(0, tempItemTuples.Count);

                Choosable choosable = GuessNextNumberManager.ChoosableFactory.Create();
                choosable.Initialize(null, tempItemTuples[rnd].Name);
                choosable.transform.localScale = Vector3.zero;

                _choosables.Add(choosable);
                tempItemTuples.RemoveAt(rnd);
            }

            Helper.Shuffle(_choosables);

            Presenter.OnCreateChoosables(_choosables);
        }
    }
}
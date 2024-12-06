using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    public class GuessNextNumberView : UIView<GuessNextNumberPresenter>
    {
        private List<ItemTuple> _itemTuples;

        private List<VisualItem> _visualItems;

        private List<Choosable> _choosables;

        private int _correctChoosableIndex;

        private Choosable _correctChoosable;

        public override void InitializeView()
        {
            _visualItems = new List<VisualItem>();
            _choosables = new List<Choosable>();

            _itemTuples = new List<ItemTuple>(GuessNextNumberManager.NumberData.NumberTuples);

            StartCreating();
        }

        public void StartCreating()
        {
            CreateVisuals();
            CreateChoosables();
        }

        private void CreateVisuals()
        {
            _visualItems.Clear();

            int start = Random.Range(1, 7);

            _correctChoosableIndex = start + 2;

            for (int i = start - 1; i < start + 3; i++)
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

            List<ItemTuple> tempItemTuples = new List<ItemTuple>(_itemTuples);

            _correctChoosable = GuessNextNumberManager.ChoosableFactory.Create();
            _correctChoosable.Initialize(null, tempItemTuples[_correctChoosableIndex].Name);
            _correctChoosable.SetCorrectAnswer(tempItemTuples[_correctChoosableIndex]);
            _choosables.Add(_correctChoosable);

            tempItemTuples.RemoveAt(_correctChoosableIndex);

            for (int i = 0; i < 2; i++)
            {
                int rnd = Random.Range(0, tempItemTuples.Count);

                Choosable choosable = GuessNextNumberManager.ChoosableFactory.Create();
                choosable.Initialize( null, tempItemTuples[rnd].Name);
                choosable.transform.localScale = Vector3.zero;

                _choosables.Add(choosable);
                tempItemTuples.RemoveAt(rnd);
            }

            Helper.Shuffle(_choosables);

            Presenter.OnCreateChoosables(_choosables);
        }

    }
}

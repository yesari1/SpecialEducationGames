using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    public class CompareNumbersView : UIView<CompareNumbersPresenter>
    {
        private List<ItemTuple> _itemTuples;

        private List<VisualItem> _visualItems;

        private List<Choosable> _choosables;

        private ItemTuple _firstNumberTuple;

        private ItemTuple _secondNumberTuple;

        private int _correctChoosableIndex;

        private Choosable _correctChoosable;

        public CompareState _compareState;

        public override void InitializeView()
        {
            _visualItems = new List<VisualItem>();
            _choosables = new List<Choosable>();

            _itemTuples = new List<ItemTuple>(CompareNumbersManager.NumberData.NumberTuples);

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

            int firstRnd = Random.Range(0, _itemTuples.Count - 3);
            int secondRnd = Random.Range(0, _itemTuples.Count - 3);

            _firstNumberTuple = _itemTuples[firstRnd];
            _secondNumberTuple = _itemTuples[secondRnd];

            VisualItem visualItem = CompareNumbersManager.VisualItemFactory.Create();
            visualItem.Initialize(_firstNumberTuple, _firstNumberTuple.Sprite, _firstNumberTuple.Name);
            _visualItems.Add(visualItem);

            _compareState = CreateCompareState(firstRnd,secondRnd);

            visualItem = CompareNumbersManager.VisualItemFactory.Create();
            ItemTuple itemTuple = GetCompareState(_compareState);

            visualItem.Initialize(itemTuple, _firstNumberTuple.Sprite, itemTuple.Name);
            visualItem.SetHidden();
            _visualItems.Add(visualItem);

            visualItem = CompareNumbersManager.VisualItemFactory.Create();
            visualItem.Initialize(_secondNumberTuple,_secondNumberTuple.Sprite, _secondNumberTuple.Name);
            _visualItems.Add(visualItem);

            Presenter.OnCreateVisuals(_visualItems);
        }

        private CompareState CreateCompareState(int firstRnd,int secondRnd)
        {
            if (firstRnd + 1 > secondRnd + 1)
                return CompareState.Greater;
            else if (secondRnd + 1 > firstRnd + 1)
                return CompareState.Less;
            else
                return CompareState.Equals;
        }

        private void CreateChoosables()
        {
            _choosables.Clear();

            _correctChoosable = CompareNumbersManager.ChoosableFactory.Create();
            ItemTuple itemTuple = GetCompareState(_compareState);
            _correctChoosable.Initialize(null, itemTuple.Name);
            _correctChoosable.SetCorrectAnswer(itemTuple);
            _choosables.Add(_correctChoosable);

            List<ItemTuple> otherStates = GetOtherStatesRandomly(_compareState);

            for (int i = 0; i < otherStates.Count; i++)
            {
                Choosable choosable = CompareNumbersManager.ChoosableFactory.Create();
                choosable.Initialize(null, otherStates[i].Name);
                choosable.transform.localScale = Vector3.zero;

                _choosables.Add(choosable);
            }

            Helper.Shuffle(_choosables);

            Presenter.OnCreateChoosables(_choosables);
        }

        private ItemTuple GetCompareState(CompareState compareState)
        {
            switch (compareState)
            {
                case CompareState.None:
                case CompareState.Equals:
                    return _itemTuples[10];
                case CompareState.Greater:
                    return _itemTuples[9];
                case CompareState.Less:
                    return _itemTuples[11];
                default:
                    return _itemTuples[9];
            }
        }

        private List<ItemTuple> GetOtherStatesRandomly(CompareState compareState)
        {
            List<ItemTuple> states = new List<ItemTuple>
            {
                _itemTuples[9],
                _itemTuples[10],
                _itemTuples[11],
            };

            for (int i = 0; i < states.Count; i++)
                if (states[i].Name == GetCompareState(compareState).Name)
                    states.RemoveAt(i);

            Helper.Shuffle(states);

            return states;
        }

    }

    public enum CompareState
    {
        None,
        Equals,
        Greater,
        Less
    }

}

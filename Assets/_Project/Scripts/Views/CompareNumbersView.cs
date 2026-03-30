using System;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    public class CompareNumbersView : UIView<CompareNumbersPresenter>
    {
        private List<ItemTupleData> _numberTuples;

        private List<VisualItem> _visualItems;

        private List<Choosable> _choosables;

        private ItemTupleData _firstNumberTuple;

        private ItemTupleData _secondNumberTuple;

        private ItemTupleData _greaterTuple;

        private ItemTupleData _equalTuple;

        private ItemTupleData _lessTuple;

        private Choosable _correctChoosable;

        public CompareState _compareState;

        public override void InitializeView()
        {
            _visualItems = new List<VisualItem>();
            _choosables = new List<Choosable>();
            _numberTuples = new List<ItemTupleData>();

            CacheItemTuples();

            if (_numberTuples.Count < 2)
            {
                Debug.LogError("CompareNumbersView baþlatýlamadý. En az 2 adet geçerli sayý ItemTupleData atanmalý.");
                return;
            }

            if (_greaterTuple == null || _equalTuple == null || _lessTuple == null)
            {
                Debug.LogError("CompareNumbersView baþlatýlamadý. Greater, Equal ve Less ItemTupleData atanmýþ olmalý.");
                return;
            }

            StartCreating();
        }

        public void StartCreating()
        {
            CreateVisuals();
            CreateChoosables();
        }

        private void CacheItemTuples()
        {
            if (CompareNumbersManager.ItemTuples == null)
            {
                return;
            }

            for (int i = 0; i < CompareNumbersManager.ItemTuples.Count; i++)
            {
                ItemTupleData itemTuple = CompareNumbersManager.ItemTuples[i];
                if (itemTuple == null)
                {
                    continue;
                }

                switch (itemTuple.Audio)
                {
                    case EffectType.Greater:
                        _greaterTuple = itemTuple;
                        break;

                    case EffectType.Equal:
                        _equalTuple = itemTuple;
                        break;

                    case EffectType.Less:
                        _lessTuple = itemTuple;
                        break;

                    default:
                        if (TryGetNumberValue(itemTuple, out _))
                        {
                            _numberTuples.Add(itemTuple);
                        }
                        else
                        {
                            Debug.LogError($"Sayý parse edilemedi. ItemTupleData: {itemTuple.name}, Name: {itemTuple.Name}");
                        }
                        break;
                }
            }
        }

        private void CreateVisuals()
        {
            _visualItems.Clear();

            int firstRnd = Random.Range(0, _numberTuples.Count);
            int secondRnd = Random.Range(0, _numberTuples.Count);

            _firstNumberTuple = _numberTuples[firstRnd];
            _secondNumberTuple = _numberTuples[secondRnd];

            VisualItem visualItem = CompareNumbersManager.VisualItemFactory.Create();
            visualItem.Initialize(_firstNumberTuple, _firstNumberTuple.Sprite, _firstNumberTuple.Name);
            _visualItems.Add(visualItem);

            _compareState = CreateCompareState(_firstNumberTuple, _secondNumberTuple);

            visualItem = CompareNumbersManager.VisualItemFactory.Create();
            ItemTupleData itemTuple = GetCompareState(_compareState);

            visualItem.Initialize(itemTuple, _firstNumberTuple.Sprite, itemTuple.Name);
            visualItem.SetHidden();
            _visualItems.Add(visualItem);

            visualItem = CompareNumbersManager.VisualItemFactory.Create();
            visualItem.Initialize(_secondNumberTuple, _secondNumberTuple.Sprite, _secondNumberTuple.Name);
            _visualItems.Add(visualItem);

            Presenter.OnCreateVisuals(_visualItems);
        }

        private CompareState CreateCompareState(ItemTupleData firstItemTuple, ItemTupleData secondItemTuple)
        {
            if (!TryGetNumberValue(firstItemTuple, out int firstValue))
            {
                Debug.LogError($"Ýlk sayý int'e çevrilemedi. ItemTupleData: {firstItemTuple.name}, Name: {firstItemTuple.Name}");
                return CompareState.None;
            }

            if (!TryGetNumberValue(secondItemTuple, out int secondValue))
            {
                Debug.LogError($"Ýkinci sayý int'e çevrilemedi. ItemTupleData: {secondItemTuple.name}, Name: {secondItemTuple.Name}");
                return CompareState.None;
            }

            if (firstValue > secondValue)
            {
                return CompareState.Greater;
            }

            if (secondValue > firstValue)
            {
                return CompareState.Less;
            }

            return CompareState.Equals;
        }

        private bool TryGetNumberValue(ItemTupleData itemTuple, out int value)
        {
            value = 0;

            if (itemTuple == null)
            {
                return false;
            }

            if (string.IsNullOrWhiteSpace(itemTuple.Name))
            {
                return false;
            }

            return int.TryParse(itemTuple.Name.Trim(), out value);
        }

        private void CreateChoosables()
        {
            _choosables.Clear();

            _correctChoosable = CompareNumbersManager.ChoosableFactory.Create();
            ItemTupleData itemTuple = GetCompareState(_compareState);
            _correctChoosable.Initialize(null, itemTuple.Name);
            _correctChoosable.SetCorrectAnswer(itemTuple);
            _choosables.Add(_correctChoosable);

            List<ItemTupleData> otherStates = GetOtherStatesRandomly(_compareState);

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

        private ItemTupleData GetCompareState(CompareState compareState)
        {
            switch (compareState)
            {
                case CompareState.Equals:
                    return _equalTuple;

                case CompareState.Greater:
                    return _greaterTuple;

                case CompareState.Less:
                    return _lessTuple;

                default:
                    return _equalTuple;
            }
        }

        private List<ItemTupleData> GetOtherStatesRandomly(CompareState compareState)
        {
            List<ItemTupleData> states = new List<ItemTupleData>
            {
                _greaterTuple,
                _equalTuple,
                _lessTuple
            };

            ItemTupleData correctState = GetCompareState(compareState);
            states.RemoveAll(x => x == correctState);

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
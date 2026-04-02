using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    public class CompareNumbersView : UIView<CompareNumbersPresenter>
    {
        private List<ItemData> _numberTuples;
        private List<VisualItem> _visualItems;
        private List<Choosable> _choosables;

        private ItemData _firstNumberTuple;
        private ItemData _secondNumberTuple;

        private ItemData _greaterTuple;
        private ItemData _equalTuple;
        private ItemData _lessTuple;

        private Choosable _correctChoosable;

        public CompareState _compareState;

        public override void InitializeView()
        {
            _visualItems = new List<VisualItem>();
            _choosables = new List<Choosable>();
            _numberTuples = new List<ItemData>();

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
            _numberTuples.Clear();

            _greaterTuple = CompareNumbersManager.GreaterItemTuple;
            _equalTuple = CompareNumbersManager.EqualItemTuple;
            _lessTuple = CompareNumbersManager.LessItemTuple;

            if (CompareNumbersManager.ItemTuples == null)
            {
                return;
            }

            for (int i = 0; i < CompareNumbersManager.ItemTuples.Count; i++)
            {
                ItemData itemTuple = CompareNumbersManager.ItemTuples[i];
                if (itemTuple == null)
                {
                    continue;
                }

                if (TryGetNumberValue(itemTuple, out _))
                {
                    _numberTuples.Add(itemTuple);
                }
                else
                {
                    Debug.LogError($"Sayý parse edilemedi. ItemTupleData: {itemTuple.name}, Name: {itemTuple.LocalizedName}");
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
            ItemData itemTuple = GetCompareState(_compareState);

            visualItem.Initialize(itemTuple, _firstNumberTuple.Sprite, itemTuple.Name);
            visualItem.SetHidden();
            _visualItems.Add(visualItem);

            visualItem = CompareNumbersManager.VisualItemFactory.Create();
            visualItem.Initialize(_secondNumberTuple, _secondNumberTuple.Sprite, _secondNumberTuple.Name);
            _visualItems.Add(visualItem);

            Presenter.OnCreateVisuals(_visualItems);
        }

        private CompareState CreateCompareState(ItemData firstItemTuple, ItemData secondItemTuple)
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

        private bool TryGetNumberValue(ItemData itemTuple, out int value)
        {
            value = 0;

            if (itemTuple == null)
            {
                return false;
            }

            if (string.IsNullOrWhiteSpace(itemTuple.LocalName))
            {
                return false;
            }

            return int.TryParse(itemTuple.Name.Trim(), out value);
        }

        private void CreateChoosables()
        {
            _choosables.Clear();

            _correctChoosable = CompareNumbersManager.ChoosableFactory.Create();
            ItemData itemTuple = GetCompareState(_compareState);
            _correctChoosable.Initialize(null, itemTuple.Name);
            _correctChoosable.SetCorrectAnswer(itemTuple);
            _choosables.Add(_correctChoosable);

            List<ItemData> otherStates = GetOtherStatesRandomly(_compareState);

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

        private ItemData GetCompareState(CompareState compareState)
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

        private List<ItemData> GetOtherStatesRandomly(CompareState compareState)
        {
            List<ItemData> states = new List<ItemData>
            {
                _greaterTuple,
                _equalTuple,
                _lessTuple
            };

            ItemData correctState = GetCompareState(compareState);
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
using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    public class MatchingManager : MonoBehaviour
    {
        private static MatchingManager _instance;

        [SerializeField] private List<ItemTupleData> _itemTuples;

        [SerializeField] private ChoosableFactory _factory;

        public static ChoosableFactory ChoosableFactory => _instance._factory;

        public static IReadOnlyList<ItemTupleData> ItemTuples => _instance._itemTuples;

        private void Awake()
        {
            if (_instance == null)
            {
                _instance = this;
                return;
            }

            if (_instance != this)
            {
                Destroy(gameObject);
            }
        }

        private void OnEnable()
        {
            EventManager.Subscribe<OnCorrectOneChoosedEvent>(OnCorrectOneChoosed);
            EventManager.Subscribe<OnShowInfoTextEvent>(OnShowInfoText);
        }

        private void OnDisable()
        {
            EventManager.Unsubscribe<OnCorrectOneChoosedEvent>(OnCorrectOneChoosed);
            EventManager.Unsubscribe<OnShowInfoTextEvent>(OnShowInfoText);
        }

        private void OnShowInfoText(OnShowInfoTextEvent onShowInfoTextEvent)
        {
            AudioManager.PlaySound(onShowInfoTextEvent.ItemTuple.Audio, 0.25f);
        }

        private void OnCorrectOneChoosed(OnCorrectOneChoosedEvent onCorrectOneChoosedEvent)
        {
            AudioManager.PlaySuccessSoundRandomly();
            AudioManager.PlaySound(onCorrectOneChoosedEvent.Choosable.ItemTuple.Audio);
        }
    }
}
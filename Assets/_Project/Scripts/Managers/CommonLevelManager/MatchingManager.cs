using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    public class MatchingManager : MonoBehaviour
    {
        [SerializeField] private List<ItemData> _itemTuples;

        [SerializeField] private ChoosableFactory _factory;

        public IReadOnlyList<ItemData> ItemTuples => _itemTuples;

        public ChoosableFactory ChoosableFactory => _factory;

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
            if (onShowInfoTextEvent.ItemTuple == null)
            {
                return;
            }

            AudioManager.PlaySound(onShowInfoTextEvent.ItemTuple.Audio, 0.25f);
        }

        private void OnCorrectOneChoosed(OnCorrectOneChoosedEvent onCorrectOneChoosedEvent)
        {
            if (onCorrectOneChoosedEvent.Choosable == null || onCorrectOneChoosedEvent.Choosable.ItemTuple == null)
            {
                return;
            }

            AudioManager.PlaySuccessSoundRandomly();
            AudioManager.PlaySound(onCorrectOneChoosedEvent.Choosable.ItemTuple.Audio);
        }
    }
}
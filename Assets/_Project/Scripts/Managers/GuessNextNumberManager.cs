using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    public class GuessNextNumberManager : MonoBehaviour
    {
        private static GuessNextNumberManager _instance;

        [SerializeField] private ChoosableFactory _choosableFactory;

        [SerializeField] private VisualItemFactory _visualItemFactory;

        [SerializeField] private List<ItemTupleData> _itemTuples;

        public static ChoosableFactory ChoosableFactory => _instance._choosableFactory;

        public static VisualItemFactory VisualItemFactory => _instance._visualItemFactory;

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

        private void Start()
        {
            AudioManager.PlaySound(EffectType.StartGuessNextNumber);
        }

        private void OnEnable()
        {
            EventManager.Subscribe<OnVisualItemsCreatedEvent>(OnVisualItemsCreated);
            EventManager.Subscribe<OnCorrectOneChoosedEvent>(OnCorrectOneChoosed);
        }

        private void OnDisable()
        {
            EventManager.Unsubscribe<OnVisualItemsCreatedEvent>(OnVisualItemsCreated);
            EventManager.Unsubscribe<OnCorrectOneChoosedEvent>(OnCorrectOneChoosed);
        }

        private void OnVisualItemsCreated(OnVisualItemsCreatedEvent onVisualItemsCreatedEvent)
        {
            List<VisualItem> items = onVisualItemsCreatedEvent.VisualItems;

            EffectType[] gameSounds = new EffectType[items.Count];

            for (int i = 0; i < items.Count; i++)
            {
                if (items[i].IsHidden)
                {
                    gameSounds[i] = EffectType.GuessNextNumber;
                    continue;
                }

                gameSounds[i] = items[i].ItemTuple.Audio;
            }

            AudioManager.PlaySounds(gameSounds);
        }

        private void OnCorrectOneChoosed(OnCorrectOneChoosedEvent onCorrectOneChoosedEvent)
        {
            AudioManager.PlaySuccessSoundRandomly();
            AudioManager.PlaySounds(onCorrectOneChoosedEvent.Choosable.ItemTuple.Audio);
        }
    }
}
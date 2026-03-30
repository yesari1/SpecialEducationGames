using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    public class CompareNumbersManager : MonoBehaviour
    {
        private static CompareNumbersManager _instance;

        [SerializeField] private ChoosableFactory _choosableFactory;

        [SerializeField] private VisualItemFactory _visualItemFactory;

        [SerializeField] private List<ItemTupleData> _itemTuples;

        private EffectType[] _gameSounds;

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
            AudioManager.PlaySound(EffectType.StartCompareNumbers);
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

            _gameSounds = new EffectType[4];

            for (int i = 0; i < items.Count; i++)
            {
                if (items[i].IsHidden)
                {
                    continue;
                }

                _gameSounds[i] = items[i].ItemTuple.Audio;
            }

            EffectType gameSoundTemp = _gameSounds[2];

            _gameSounds[1] = EffectType.And;
            _gameSounds[2] = gameSoundTemp;
            _gameSounds[3] = EffectType.CompareNumbers;

            AudioManager.PlaySounds(_gameSounds);
        }

        private void OnCorrectOneChoosed(OnCorrectOneChoosedEvent onCorrectOneChoosedEvent)
        {
            AudioManager.PlaySuccessSoundRandomly();

            _gameSounds[1] = onCorrectOneChoosedEvent.Choosable.ItemTuple.Audio;
            _gameSounds[3] = EffectType.None;

            AudioManager.PlaySounds(_gameSounds);
        }
    }
}
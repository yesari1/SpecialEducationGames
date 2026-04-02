using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    public class CompareNumbersManager : MonoBehaviour
    {
        private static CompareNumbersManager _instance;

        [SerializeField] private ChoosableFactory _choosableFactory;
        [SerializeField] private VisualItemFactory _visualItemFactory;
        [SerializeField] private List<ItemData> _itemTuples;
        [SerializeField] private ItemData _greaterItemTuple;
        [SerializeField] private ItemData _equalItemTuple;
        [SerializeField] private ItemData _lessItemTuple;

        private SoundData _firstItemSound;
        private SoundData _secondItemSound;

        public static ChoosableFactory ChoosableFactory => _instance._choosableFactory;
        public static VisualItemFactory VisualItemFactory => _instance._visualItemFactory;
        public static IReadOnlyList<ItemData> ItemTuples => _instance._itemTuples;
        public static ItemData GreaterItemTuple => _instance._greaterItemTuple;
        public static ItemData EqualItemTuple => _instance._equalItemTuple;
        public static ItemData LessItemTuple => _instance._lessItemTuple;

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

            _firstItemSound = null;
            _secondItemSound = null;

            for (int i = 0; i < items.Count; i++)
            {
                if (items[i].IsHidden)
                {
                    continue;
                }

                SoundData soundData = items[i].ItemTuple != null ? items[i].ItemTuple.Audio : null;

                if (_firstItemSound == null)
                {
                    _firstItemSound = soundData;
                }
                else
                {
                    _secondItemSound = soundData;
                    break;
                }
            }

            AudioManager.PlaySounds(
                _firstItemSound,
                AudioManager.GetSoundData(EffectType.And),
                _secondItemSound,
                AudioManager.GetSoundData(EffectType.CompareNumbers));
        }

        private void OnCorrectOneChoosed(OnCorrectOneChoosedEvent onCorrectOneChoosedEvent)
        {
            AudioManager.PlaySuccessSoundRandomly();

            SoundData resultSound = onCorrectOneChoosedEvent.Choosable != null &&
                                    onCorrectOneChoosedEvent.Choosable.ItemTuple != null
                ? onCorrectOneChoosedEvent.Choosable.ItemTuple.Audio
                : null;

            AudioManager.PlaySounds(_firstItemSound, resultSound, _secondItemSound);
        }
    }
}
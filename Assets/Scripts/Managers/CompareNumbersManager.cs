using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    public class CompareNumbersManager : MonoBehaviour
    {
        private static CompareNumbersManager _instance;

        [SerializeField] private ChoosableFactory _choosableFactory;

        [SerializeField] private VisualItemFactory _visualItemFactory;

        [SerializeField] private NumberData _numberData;
        private GameSound[] _gameSounds;

        public static ChoosableFactory ChoosableFactory => _instance._choosableFactory;

        public static VisualItemFactory VisualItemFactory => _instance._visualItemFactory;

        public static NumberData NumberData => _instance._numberData;

        private void Awake()
        {
            if (_instance == null)
                _instance = this;
        }

        private void Start()
        {
            AudioManager.PlaySound(GameSound.StartCompareNumbers);
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

            _gameSounds = new GameSound[4];

            for (int i = 0; i < items.Count; i++)
            {
                if (items[i].IsHidden)
                    continue;
                _gameSounds[i] = items[i].ItemTuple.Audio;
            }

            GameSound gameSoundTemp = _gameSounds[2];

            _gameSounds[1] = GameSound.And;
            _gameSounds[2] = gameSoundTemp;
            _gameSounds[3] = GameSound.CompareNumbers;

            AudioManager.PlaySounds(_gameSounds);
        }


        private void OnCorrectOneChoosed(OnCorrectOneChoosedEvent onCorrectOneChoosedEvent)
        {
            AudioManager.PlaySuccessSoundRandomly();

            _gameSounds[1] = onCorrectOneChoosedEvent.Choosable.ItemTuple.Audio;
            _gameSounds[3] = GameSound.None;

            AudioManager.PlaySounds(_gameSounds);

        }

    }
}

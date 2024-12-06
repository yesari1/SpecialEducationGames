using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    public class GuessNextNumberManager : MonoBehaviour
    {
        private static GuessNextNumberManager _instance;

        [SerializeField] private ChoosableFactory _choosableFactory;

        [SerializeField] private VisualItemFactory _visualItemFactory;

        [SerializeField] private NumberData _numberData;

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
            AudioManager.PlaySound(GameSound.StartGuessNextNumber);
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

            GameSound[] gameSounds = new GameSound[items.Count];

            for (int i = 0; i < items.Count; i++)
            {
                if (items[i].IsHidden)
                {
                    gameSounds[i] = GameSound.GuessNextNumber;
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

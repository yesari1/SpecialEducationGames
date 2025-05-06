using System;
using System.Collections.Generic;
using UnityEngine;
using static SpecialEducationGames.Choosable;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    public class MatchingManager : MonoBehaviour
    {
        private static MatchingManager _instance;

        [SerializeField] private ChoosableData _choosableData;

        [SerializeField] private ChoosableFactory _factory;

        public static ChoosableFactory ChoosableFactory => _instance._factory;

        public static ChoosableData ChoosableData => _instance._choosableData;

        private void Awake()
        {
            if (_instance == null)
                _instance = this;
        }

        private void OnEnable()
        {
            EventManager.Subscribe<OnCorrectOneChoosedEvent>(OnCorrectOneChoosed);
            EventManager.Subscribe<OnShowInfoTextEvent>(OnShowInfoText);
        }

        private void OnShowInfoText(OnShowInfoTextEvent onShowInfoTextEvent)
        {
            AudioManager.PlaySound(onShowInfoTextEvent.ItemTuple.GameSoundTuple,0.25f);
        }

        private void OnDisable()
        {
            EventManager.Unsubscribe<OnCorrectOneChoosedEvent>(OnCorrectOneChoosed);
            EventManager.Unsubscribe<OnShowInfoTextEvent>(OnShowInfoText);
        }

        private void OnCorrectOneChoosed(OnCorrectOneChoosedEvent onCorrectOneChoosedEvent)
        {
            AudioManager.PlaySuccessSoundRandomly();

            AudioManager.PlaySound(onCorrectOneChoosedEvent.Choosable.ItemTuple.GameSoundTuple);
        }

    }
} 


using DG.Tweening;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using static SpecialEducationGames.Choosable;

namespace SpecialEducationGames
{
    public class MatchingTextManager : LevelTextManager
    {

        protected override void OnEnable()
        {
            base.OnEnable();
            GameEventReceiver.OnMatchingStartedEvent += OnMatchingStarted;
        }

        protected override void OnDisable()
        {
            base.OnDisable();
            GameEventReceiver.OnMatchingStartedEvent -= OnMatchingStarted;
        }

        protected override void Awake()
        {
            base.Awake();
        }

        protected override void Start()
        {
            base.Start();
        }


        private void OnMatchingStarted(ChoosableType choosableType)
        {
            _centerInfoText.text = choosableType.Name;
            PlayCenterInfoTextAnimation();
        }

        protected override void OnBeforeStageCompleted()
        {
            base.OnBeforeStageCompleted();
        }

        protected override void OnGameFinished()
        {
            base.OnGameFinished();
        }

    }
}

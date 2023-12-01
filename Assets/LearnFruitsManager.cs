using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Zenject;

namespace SpecialEducationGames
{
    public class LearnFruitsManager : LevelManager
    {
        private ParticleSettings _particleSettings;

        [Inject]
        public void Construct(ParticleSettings particleSettings)
        {
            _particleSettings = particleSettings;
        }

        private void OnEnable()
        {
            GameEventReceiver.OnGameFinishedEvent += OnGameFinished;
            GameEventReceiver.OnChoosedRightEvent += OnChoosedRight;
        }

        private void OnDisable()
        {
            GameEventReceiver.OnGameFinishedEvent -= OnGameFinished;
            GameEventReceiver.OnChoosedRightEvent -= OnChoosedRight;
        }


        private void OnChoosedRight()
        {
            ParticleManager.Instance.CreateAndPlay(_particleSettings.ChoosedRight, Vector3.zero, false);
        }


        private void OnGameFinished()
        {
            ParticleManager.Instance.CreateAndPlay(_particleSettings.GameFinished, Vector3.zero, true);
        }


        [Serializable]
        public struct ParticleSettings
        {
            public ParticleSystem ChoosedRight;
            public ParticleSystem GameFinished;
        }

    }
}

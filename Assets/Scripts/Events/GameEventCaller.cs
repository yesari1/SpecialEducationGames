using UnityEngine;
using System.Collections;
using System;

namespace SpecialEducationGames
{
    public class GameEventCaller: IGameEvents
    {
        private GameEventReceiver _gameEventReceiver;

        public static GameEventCaller Instance
        {
            get
            {
                return GameManager.GameEventCaller;
            }
        }

        public GameEventCaller(GameEventReceiver gameEventReceiver)
        {
            _gameEventReceiver = gameEventReceiver;
        }

        public void OnCenterTextAnimationEnded()
        {
            _gameEventReceiver.OnCenterTextAnimationEnded();
        }

        public void OnStageCompleted()
        {
            _gameEventReceiver.OnStageCompleted();
        }
    }

}

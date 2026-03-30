using UnityEngine;
using System.Collections;
using System;
using static SpecialEducationGames.Choosable;

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

        public void OnCenterTextAnimationEnded() => _gameEventReceiver.OnCenterTextAnimationEnded();

        public void OnStageCompleted() => _gameEventReceiver.OnStageCompleted();

        public void OnCorrectAnimationEnded() => _gameEventReceiver.OnCorrectAnimationEnded();

        public void OnChoosablePointerDown(Choosable choosable) => _gameEventReceiver.OnChoosablePointerDown(choosable);

        public void OnMatchingStarted(ChoosableType choosableType) => _gameEventReceiver.OnMatchingStarted(choosableType);

        public void OnBeforeStageCompleted() => _gameEventReceiver.OnBeforeStageCompleted();

        public void OnGameFinished() => _gameEventReceiver.OnGameFinished();

        public void OnChoosedRight(Choosable choosable) => _gameEventReceiver.OnChoosedRight(choosable);

    }

}

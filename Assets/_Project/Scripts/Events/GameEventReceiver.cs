using System;
using UnityEngine;
using static SpecialEducationGames.Choosable;

namespace SpecialEducationGames
{
    public class GameEventReceiver : IGameEvents
    {

        public static event Action OnCenterTextAnimationEndedEvent;

        public static event Action OnBeforeStageCompletedEvent;

        public static event Action<Choosable> OnChoosedRightEvent;

        public static event Action OnStageCompletedEvent;

        public static event Action OnGameFinishedEvent;

        public static event Action OnCorrectAnimationEndedEvent;

        public static event Action<Choosable> OnChoosablePointerDownEvent;

        public static event Action<ChoosableType> OnMatchingStartedEvent;


        public void OnCenterTextAnimationEnded() => OnCenterTextAnimationEndedEvent?.Invoke();

        public void OnCorrectAnimationEnded() => OnCorrectAnimationEndedEvent?.Invoke();

        public void OnStageCompleted() => OnStageCompletedEvent?.Invoke();

        public void OnChoosablePointerDown(Choosable choosable) => OnChoosablePointerDownEvent?.Invoke(choosable);

        public void OnMatchingStarted(ChoosableType choosableType) => OnMatchingStartedEvent?.Invoke(choosableType);

        public void OnBeforeStageCompleted() => OnBeforeStageCompletedEvent?.Invoke();

        public void OnGameFinished() => OnGameFinishedEvent?.Invoke();

        public void OnChoosedRight(Choosable choosable) => OnChoosedRightEvent?.Invoke(choosable);

    }

}

using System;
using UnityEngine;

namespace SpecialEducationGames
{
    public class GameEventReceiver : IGameEvents
    {
        public static event Action OnCenterTextAnimationEndedEvent;

        public static event Action OnStageCompletedEvent;

        public void OnCenterTextAnimationEnded() => OnCenterTextAnimationEndedEvent?.Invoke();

        public void OnStageCompleted() => OnStageCompletedEvent?.Invoke();
    }
}

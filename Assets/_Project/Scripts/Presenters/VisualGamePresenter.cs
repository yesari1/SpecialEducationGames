using MEC;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;

namespace SpecialEducationGames
{
    public class VisualGamePresenter : PresenterBase<VisualGameView>
    {
        private CoroutineHandle _showCoroutine;
        private CoroutineHandle _eventCoroutine;

        public override void InitializePresenter()
        {
            EventManager.Subscribe<OnVisualItemsCreatedEvent>(OnVisualItemsCreated);
            EventManager.Subscribe<OnChoosablesCreatedEvent>(OnChoosablesCreated);
            EventManager.Subscribe<OnChoosableSelectedEvent>(OnChoosableSelected);
            EventManager.Subscribe<OnShowInfoTextAnimationCompletedEvent>(OnShowInfoTextAnimationCompleted);
        }
        public override void Dispose()
        {
            EventManager.Unsubscribe<OnVisualItemsCreatedEvent>(OnVisualItemsCreated);
            EventManager.Unsubscribe<OnChoosablesCreatedEvent>(OnChoosablesCreated);
            EventManager.Unsubscribe<OnChoosableSelectedEvent>(OnChoosableSelected);
            EventManager.Unsubscribe<OnShowInfoTextAnimationCompletedEvent>(OnShowInfoTextAnimationCompleted);

            View.KillAnimations();
            Timing.KillCoroutines(_showCoroutine);
            Timing.KillCoroutines(_eventCoroutine);
        }
        private void OnVisualItemsCreated(OnVisualItemsCreatedEvent onVisualItemsCreatedEvent)
        {
            View.PlaceVisualObjects(onVisualItemsCreatedEvent.VisualItems);
        }

        private void OnChoosablesCreated(OnChoosablesCreatedEvent onChoosablesCreatedEvent)
        {
            View.PlaceChoosableObjects(onChoosablesCreatedEvent.Choosables);
        }

        private void OnChoosableSelected(OnChoosableSelectedEvent onChoosableSelectedEvent)
        {
            View.OnChoosableSelected(onChoosableSelectedEvent.Choosable);
        }

        internal void ShowInfoText(string text)
        {
            EventManager.Fire(new OnShowInfoTextEvent() { TextOnly = text });
        }

        private void OnShowInfoTextAnimationCompleted(OnShowInfoTextAnimationCompletedEvent @event)
        {
            _showCoroutine = Timing.RunCoroutine(View.OnInfoTextShowed());
        }

        internal void OnGameFinished()
        {
            EventManager.Fire<OnGameFinishedEvent>();
        }

        public void OnStageCompleted(float seconds)
        {
            _eventCoroutine = Timing.CallDelayed(seconds, FireStageCompletedEvent);
        }

        private void FireStageCompletedEvent()
        {
            EventManager.Fire<OnStageCompletedEvent>();
        }
    }
}

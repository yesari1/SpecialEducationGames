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
            Timing.RunCoroutine(View.OnInfoTextShowed());
        }

        public IEnumerator<float> OnStageCompleted(float seconds)
        {
            yield return Timing.WaitForSeconds(seconds);
            EventManager.Fire<OnStageCompletedEvent>();

        }

        internal void OnGameFinished()
        {
            EventManager.Fire<OnGameFinishedEvent>();
        }


    }
}

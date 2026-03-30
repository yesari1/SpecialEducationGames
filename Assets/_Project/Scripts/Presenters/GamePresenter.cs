
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;

namespace SpecialEducationGames
{
    public class GamePresenter : PresenterBase<GameView>
    {
        public override void InitializePresenter()
        {
            EventManager.Subscribe<OnShowInfoTextEvent>(ShowMatchText);
            EventManager.Subscribe<OnGameFinishedEvent>(OnGameFinished);
        }

        public override void Dispose()
        {
            EventManager.Unsubscribe<OnShowInfoTextEvent>(ShowMatchText);
            EventManager.Unsubscribe<OnGameFinishedEvent>(OnGameFinished);
        }

        private void ShowMatchText(OnShowInfoTextEvent onShowInfoTextEvent)
        {
            string text = "";
            if (!string.IsNullOrEmpty(onShowInfoTextEvent.TextOnly))
                text = onShowInfoTextEvent.TextOnly;
            else
                text = onShowInfoTextEvent.ItemTuple.Name;

            View.ShowMatchText(text);
        }

        public void OnShowInfoTextAnimationCompleted()
        {
            EventManager.Fire<OnShowInfoTextAnimationCompletedEvent>();
        }

        private void OnGameFinished(OnGameFinishedEvent @event)
        {
            View.Hide();
        }
    }
}

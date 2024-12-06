using MEC;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;

namespace SpecialEducationGames
{
    public class MatchingPresenter : PresenterBase<MatchingView>
    {
        public override void InitializePresenter()
        {
            EventManager.Subscribe<OnChoosableSelectedEvent>(View.OnChoosableSelected);
            EventManager.Subscribe<OnShowInfoTextAnimationCompletedEvent>(OnShowInfoTextAnimationCompleted);
        }

        public override void Dispose()
        {
            EventManager.Unsubscribe<OnChoosableSelectedEvent>(View.OnChoosableSelected);
            EventManager.Unsubscribe<OnShowInfoTextAnimationCompletedEvent>(OnShowInfoTextAnimationCompleted);
        }

        public void OnStageCompleted()
        {
            EventManager.Fire<OnStageCompletedEvent>();
        }

        public void ShowInfoText(ItemTuple itemTuple)
        {
            EventManager.Fire(new OnShowInfoTextEvent() { ItemTuple = itemTuple});
        }

        private void OnShowInfoTextAnimationCompleted(OnShowInfoTextAnimationCompletedEvent @event)
        {
            Timing.RunCoroutine(View.OnInfoTextShowed());
        }

    }
}

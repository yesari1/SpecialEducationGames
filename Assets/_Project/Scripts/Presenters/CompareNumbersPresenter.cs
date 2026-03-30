using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SpecialEducationGames
{
    public class CompareNumbersPresenter : PresenterBase<CompareNumbersView>
    {

        public override void InitializePresenter()
        {
            EventManager.Subscribe<OnStageCompletedEvent>(OnStageCompleted);
        }

        public override void Dispose()
        {
            EventManager.Unsubscribe<OnStageCompletedEvent>(OnStageCompleted);
        }

        public void OnCreateVisuals(List<VisualItem> visualItems)
        {
            EventManager.Fire(new OnVisualItemsCreatedEvent() { VisualItems = visualItems });
        }

        internal void OnCreateChoosables(List<Choosable> choosables)
        {
            EventManager.Fire(new OnChoosablesCreatedEvent() { Choosables = choosables });
        }


        private void OnStageCompleted(OnStageCompletedEvent @event)
        {
            if (!GameManager.IsGameFinished)
                View.StartCreating();
        }

    }
}

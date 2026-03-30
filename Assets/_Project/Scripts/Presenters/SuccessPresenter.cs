using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;

namespace SpecialEducationGames
{
    public class SuccessPresenter : PresenterBase<SuccessView>
    {

        public override void InitializePresenter()
        {
            EventManager.Subscribe<OnGameFinishedEvent>(OnGameFinished);
        }

        public override void Dispose()
        {
            EventManager.Unsubscribe<OnGameFinishedEvent>(OnGameFinished);
        }

        private void OnGameFinished(OnGameFinishedEvent onGameFinishedEvent)
        {
            View.Show();
            View.OnGameFinished();
        }

    }
}

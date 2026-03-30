using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    public class GuessNumberTextManager : LevelTextManager
    {

        private void Construct()
        {

        }

        protected override void Awake()
        {
            base.Awake();
        }

        protected override void Start()
        {
            base.Start();

            PlayCenterInfoTextAnimation();
        }

        protected override void OnBeforeStageCompleted()
        {
            //base.OnBeforeStageCompleted();
            //Bir sonraki stage için text in yukarý çýkýp kaybolmasýna gerek yok yerinde kalsýn
        }

        protected override void OnGameFinished()
        {
            HideCenterInfoText();

            base.OnGameFinished();
        }

        
    }
}

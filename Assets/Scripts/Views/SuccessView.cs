using DG.Tweening;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

namespace SpecialEducationGames
{
    public class SuccessView : UIView<SuccessPresenter>
    {
        [SerializeField] private TextMeshProUGUI _congratulationsText;

        [SerializeField] private ParticleSystem _confettiParticles;

        [SerializeField] private AnimationSettings _animationSettings;

        public override void InitializeView()
        {
        }

        public void OnGameFinished()
        {
            _confettiParticles.Play();

            _congratulationsText.gameObject.SetActive(true);
            _congratulationsText.transform.localScale = Vector3.zero;
            _congratulationsText.transform.DOScale(_animationSettings.CongTextScaleUp.Value, _animationSettings.CongTextScaleUp.Duration).SetDelayAndEase(_animationSettings.CongTextScaleUp);
        }

        [Serializable]
        public struct AnimationSettings
        {
            public TweenSettings CongTextScaleUp;
        }

    }
}

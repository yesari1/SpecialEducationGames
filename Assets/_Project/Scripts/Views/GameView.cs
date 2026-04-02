using DG.Tweening;
using EasyButtons;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

namespace SpecialEducationGames
{
    public class GameView : UIView<GamePresenter>
    {
        [SerializeField] private TextMeshProUGUI _infoText;

        [SerializeField] private AnimationSettings _animationSettings;
        private Sequence _sequence;

        public override void InitializeView()
        {
            _infoText.transform.localScale = Vector3.zero;
        }

        [Button]
        public void ShowMatchText(string text)
        {
            _sequence = DOTween.Sequence();

            _infoText.GetComponent<RectTransform>().SetAnchors(AnchorPresets.MiddleCenter);
            _infoText.GetComponent<RectTransform>().anchoredPosition = Vector2.zero;
            _infoText.text = text;

            _sequence.Append(_infoText.transform.DOScale(_animationSettings.MatchTextShow, true));

            _sequence.AppendInterval(_animationSettings.MatchTextGoUp.Delay);
            _sequence.Append(_infoText.GetComponent<RectTransform>().DOBlendableMoveBy(_animationSettings.MatchTextGoUp.Vector, _animationSettings.MatchTextGoUp.Duration).SetEase(_animationSettings.MatchTextGoUp.Ease));
            _sequence.Join(_infoText.transform.DOScale(1, _animationSettings.MatchTextGoUp.Duration).SetEase(_animationSettings.MatchTextGoUp.Ease));

            _sequence.OnComplete(Presenter.OnShowInfoTextAnimationCompleted);
        }

        public void KillAnimations()
        {
            _sequence.Kill();
        }

        [Serializable]
        public struct AnimationSettings
        {
            public TweenSettings MatchTextShow;
            public TweenSettings MatchTextGoUp;
        }
    }
}
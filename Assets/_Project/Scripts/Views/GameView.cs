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

        public override void InitializeView()
        {
            _infoText.transform.localScale = Vector3.zero;
        }

        [Button]
        public void ShowMatchText(string text)
        {
            Sequence sequence = DOTween.Sequence();

            _infoText.GetComponent<RectTransform>().SetAnchors(AnchorPresets.MiddleCenter);
            _infoText.GetComponent<RectTransform>().anchoredPosition = Vector2.zero;
            _infoText.text = text;

            sequence.Append(_infoText.transform.DOScale(_animationSettings.MatchTextShow, true));

            sequence.AppendInterval(_animationSettings.MatchTextGoUp.Delay);
            sequence.Append(_infoText.GetComponent<RectTransform>().DOBlendableMoveBy(_animationSettings.MatchTextGoUp.Vector, _animationSettings.MatchTextGoUp.Duration).SetEase(_animationSettings.MatchTextGoUp.Ease));
            sequence.Join(_infoText.transform.DOScale(1, _animationSettings.MatchTextGoUp.Duration).SetEase(_animationSettings.MatchTextGoUp.Ease));

            sequence.OnComplete(Presenter.OnShowInfoTextAnimationCompleted);
        }

        [Serializable]
        public struct AnimationSettings
        {
            public TweenSettings MatchTextShow;
            public TweenSettings MatchTextGoUp;
        }
    }
}
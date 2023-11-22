using DG.Tweening;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using Zenject;

namespace SpecialEducationGames
{
    public class TextController : MonoBehaviour
    {
        [SerializeField] private TextMeshProUGUI _centerInfoText;

        private AnimationSettings _animationSettings;

        [Inject]
        private void Construct(AnimationSettings animationSettings)
        {
            _animationSettings = animationSettings;
        }

        private void Start()
        {
            PlayAnimations();
        }

        private void PlayAnimations()
        {
            Tweener textScaleUp = _centerInfoText.transform.DOScale(_animationSettings.CenterInfoTextScaleUp, true);
            Tweener textMove = _centerInfoText.rectTransform.DOAnchorPos(_animationSettings.CenterInfoTextMove);
            Tweener textScaleDown = _centerInfoText.transform.DOScale(_animationSettings.CenterInfoTextScaleDown, false);

            Sequence sequence = DOTween.Sequence();
            sequence.Append(textScaleUp);
            sequence.Append(textMove);
            sequence.Join(textScaleDown);

            sequence.OnComplete(() => { GameEventCaller.Instance.OnCenterTextAnimationEnded(); });
        }

        [Serializable]
        public struct AnimationSettings
        {
            public TweenSettings CenterInfoTextScaleUp;
            public TweenSettings CenterInfoTextMove;
            public TweenSettings CenterInfoTextScaleDown;

        }

    }
}

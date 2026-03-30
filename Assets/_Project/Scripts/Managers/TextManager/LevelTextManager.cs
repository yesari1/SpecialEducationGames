using DG.Tweening;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using static SpecialEducationGames.Choosable;

namespace SpecialEducationGames
{
    public class LevelTextManager : MonoBehaviour
    {
        [SerializeField] protected TextMeshProUGUI _centerInfoText;
        [SerializeField] protected TextMeshProUGUI _finishedText;

        protected Vector2 _centerInfoTextStartPosition;

        protected AnimationSettings _animationSettings;

        protected virtual void OnEnable()
        {
            GameEventReceiver.OnBeforeStageCompletedEvent += OnBeforeStageCompleted; ;
            GameEventReceiver.OnGameFinishedEvent += OnGameFinished;
        }


        protected virtual void OnDisable()
        {
            GameEventReceiver.OnBeforeStageCompletedEvent -= OnBeforeStageCompleted; ;
            GameEventReceiver.OnGameFinishedEvent -= OnGameFinished;
        }

        private void Construct(AnimationSettings animationSettings)
        {
            _animationSettings = animationSettings;
        }

        protected virtual void Awake()
        {
            _centerInfoTextStartPosition = _centerInfoText.rectTransform.anchoredPosition;
        }

        protected virtual void Start()
        {

        }


        protected void PlayCenterInfoTextAnimation()
        {
            _centerInfoText.rectTransform.DOComplete();
            _centerInfoText.rectTransform.SetAnchors(AnchorPresets.FullHorizontalLower);
            _centerInfoText.rectTransform.anchoredPosition = _centerInfoTextStartPosition;

            Tweener textScaleUp = _centerInfoText.transform.DOScale(_animationSettings.CenterInfoTextStart.Sequence[0], true);
            Tweener textMove = _centerInfoText.rectTransform.DOAnchorPos(_animationSettings.CenterInfoTextStart.Sequence[1]);
            Tweener textScaleDown = _centerInfoText.transform.DOScale(_animationSettings.CenterInfoTextStart.Sequence[2], false);

            Sequence sequence = DOTween.Sequence();
            sequence.Append(textScaleUp);
            sequence.Append(textMove);
            sequence.Join(textScaleDown);

            sequence.OnComplete(() => { GameEventCaller.Instance.OnCenterTextAnimationEnded(); });
        }

        protected virtual void OnBeforeStageCompleted()
        {
            HideCenterInfoText();
        }


        protected virtual void OnGameFinished()
        {
            PlayFinishedTextAnimation();
        }

        public void PlayFinishedTextAnimation()
        {
            _finishedText.gameObject.SetActive(true);
            _finishedText.transform.DOScale(_animationSettings.FinishedText, true);
        }

        public void HideCenterInfoText()
        {
            _centerInfoText.rectTransform.SetAnchors(AnchorPresets.FullHorizontalUpper);
            Tweener textMoveUp = _centerInfoText.rectTransform.DOAnchorPos(_animationSettings.CenterInfoTextStageFinished);
            textMoveUp.Play();
        }

        [Serializable]
        public partial struct AnimationSettings
        {
            public SequenceSettings CenterInfoTextStart;
            public TweenSettings CenterInfoTextStageFinished;
            public TweenSettings FinishedText;

        }

    }
}

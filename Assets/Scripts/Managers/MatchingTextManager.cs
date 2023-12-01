using DG.Tweening;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using Zenject;
using static SpecialEducationGames.Choosable;

namespace SpecialEducationGames
{
    public class MatchingTextManager : MonoBehaviour
    {
        [SerializeField] private TextMeshProUGUI _centerInfoText;
        [SerializeField] private TextMeshProUGUI _finishedText;

        private Vector2 _centerInfoTextStartPosition;

        private AnimationSettings _animationSettings;
        private MatchingManager _matchingManager;

        private void OnEnable()
        {
            GameEventReceiver.OnMatchingStartedEvent += OnMatchingStarted;
            GameEventReceiver.OnBeforeStageCompletedEvent += OnBeforeStageCompleted; ;
            GameEventReceiver.OnGameFinishedEvent += OnGameFinished;
        }


        private void OnDisable()
        {
            GameEventReceiver.OnMatchingStartedEvent -= OnMatchingStarted;
            GameEventReceiver.OnBeforeStageCompletedEvent -= OnBeforeStageCompleted; ;
            GameEventReceiver.OnGameFinishedEvent -= OnGameFinished;
        }

        [Inject]
        private void Construct(AnimationSettings animationSettings,MatchingManager matchingManager)
        {
            _animationSettings = animationSettings;
            _matchingManager = matchingManager;
        }

        private void Awake()
        {
            _centerInfoTextStartPosition = _centerInfoText.rectTransform.localPosition;
        }

        private void OnMatchingStarted(ChoosableType choosableType)
        {
            _centerInfoText.text = choosableType.Name;
            PlayCenterInfoTextAnimation();
        }

        private void PlayCenterInfoTextAnimation()
        {
            _centerInfoText.rectTransform.DOComplete();
            _centerInfoText.rectTransform.localPosition = _centerInfoTextStartPosition;
            _centerInfoText.rectTransform.SetAnchors(AnchorPresets.LowerCenter);

            Tweener textScaleUp = _centerInfoText.transform.DOScale(_animationSettings.CenterInfoTextStart.Sequence[0], true);
            Tweener textMove = _centerInfoText.rectTransform.DOAnchorPos(_animationSettings.CenterInfoTextStart.Sequence[1]);
            Tweener textScaleDown = _centerInfoText.transform.DOScale(_animationSettings.CenterInfoTextStart.Sequence[2], false);

            Sequence sequence = DOTween.Sequence();
            sequence.Append(textScaleUp);
            sequence.Append(textMove);
            sequence.Join(textScaleDown);

            sequence.OnComplete(() => { GameEventCaller.Instance.OnCenterTextAnimationEnded(); });
        }

        private void OnBeforeStageCompleted()
        {
            _centerInfoText.rectTransform.SetAnchors(AnchorPresets.UpperCenter);
            Tweener textMoveUp = _centerInfoText.rectTransform.DOAnchorPos(_animationSettings.CenterInfoTextStageFinished);
            textMoveUp.Play();
        }

        private void OnGameFinished()
        {
            PlayFinishedTextAnimation();
        }

        public void PlayFinishedTextAnimation()
        {
            _finishedText.gameObject.SetActive(true);
            _finishedText.transform.DOScale(_animationSettings.FinishedText,true);
        }


        [Serializable]
        public struct AnimationSettings
        {
            public SequenceSettings CenterInfoTextStart;
            public TweenSettings CenterInfoTextStageFinished;
            public TweenSettings FinishedText;

        }

    }
}

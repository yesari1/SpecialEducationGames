using DG.Tweening;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using Zenject;
using Zenject.SpaceFighter;
using static SpecialEducationGames.Choosable;

namespace SpecialEducationGames
{
    public class Choosable : MonoBehaviour, IPointerDownHandler
    {
        [SerializeField] private Image _image;

        private ChoosableType _choosableType;

        protected AnimationSettings _animationSettings;
        protected bool _scaleUp = false;
        protected float _scaleUpSpeed;
        protected Vector3 _maxScale;

        protected RectTransform _rectTransform;

        public ChoosableType Type => _choosableType;

        private void OnEnable()
        {
            _rectTransform = GetComponent<RectTransform>();
        }

        [Inject]
        public virtual void Construct(AnimationSettings animationSettings)
        {
            _animationSettings = animationSettings;
        }

        public virtual void OnSpawned()
        {
            Tweener spawn = transform.DOScale(_animationSettings.Spawn, true,true);
            spawn.Play();
        }

        public virtual void OnPointerDown(PointerEventData eventData)
        {

        }

        public virtual void OnOtherOneChoosed()
        {
            Tweener disapper = transform.DOScale(_animationSettings.Disapper);
            disapper.Play();
        }

        public virtual void OnTrulyChoosed(Action OnChoosedAnimationCompleted)
        {
            _rectTransform.SetAnchors(AnchorPresets.MiddleCenter);

            Tweener goToCenter = _rectTransform.DOAnchorPos(_animationSettings.Choosed.Sequence[0]);
            Tweener scaleUp = _rectTransform.DOScale(_animationSettings.Choosed.Sequence[1]);
            Sequence sequence = DOTween.Sequence();
            sequence.Append(goToCenter);
            sequence.Append(scaleUp);

            sequence.OnComplete(() => OnChoosedAnimationCompleted?.Invoke());
        }

        public void SetChoosableType(ChoosableType choosableType)
        {
            _choosableType = choosableType;
            _image.sprite = choosableType.Image;
            name = choosableType.Name;
        }


        public void PlayOnboardingAnimation()
        {
            transform.DOComplete();
            transform.DOPunchScale(_animationSettings.OnBoarding);
        }

        public void Hide()
        {
            _rectTransform.SetAnchors(AnchorPresets.LowerCenter);
            _rectTransform.DOAnchorPos(_animationSettings.Hide);
        }


        [Serializable]
        public struct AnimationSettings
        {
            public TweenSettings Spawn;
            public TweenSettings OnBoarding;//This one choosed but other on clicked
            public TweenSettings Disapper;//OtherOneChoosed
            public SequenceSettings Choosed;//On Truly Choosed
            public TweenSettings Hide;//On Truly Choosed Hide
        }

        [Serializable]
        public struct ChoosableTypes
        {
            public List<ChoosableType> Choosables;
        }

        [Serializable]
        public struct ChoosableType
        {
            public string Name;
            public Sprite Image;
        }

        public class Factory : PlaceholderFactory<Choosable>
        {
            public override Choosable Create()
            {
                Choosable choosable = base.Create();
                choosable.OnSpawned();
                return choosable;
            }
        }
    }
}
using DG.Tweening;
using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace SpecialEducationGames
{
    public class Choosable : MonoBehaviour, IPointerDownHandler, IFactoryObject<Choosable>
    {
        [SerializeField] private TextMeshProUGUI _text;

        [SerializeField] private Image _image;

        protected ChoosableType _choosableType;
        protected AnimationSettings _animationSettings;
        protected bool _scaleUp = false;
        protected float _scaleUpSpeed;
        protected Vector3 _maxScale;
        protected RectTransform _rectTransform;

        private FactoryBase<Choosable> _factory;
        private bool _isCorrectAnswer;
        private ItemData _itemTuple;
        private bool _isSelectable;

        private Tween _spawnTween;

        public bool IsCorrectAnswer => _isCorrectAnswer;
        public ItemData ItemTuple => _itemTuple;

        protected virtual void Awake()
        {
            _rectTransform = GetComponent<RectTransform>();
        }

        private void OnDisable()
        {
            InvalidateState();
        }

        private void OnDestroy()
        {
            InvalidateState();
        }

        public void OnSpawn(FactoryBase<Choosable> factory)
        {
            _factory = factory;
        }

        public void Dispose()
        {
            InvalidateState();
            transform.SetParent(null);

            if (_factory != null)
            {
                _factory.Push(this);
            }
        }

        public void Initialize(Sprite sprite, string text)
        {
            InvalidateState();

            _isCorrectAnswer = false;
            _itemTuple = null;

            _image.enabled = sprite != null;
            _image.sprite = sprite;
            _text.text = text;

            transform.localScale = Vector3.zero;
        }

        public void SetAnimationSettings(AnimationSettings choosableAnimationSettings)
        {
            _animationSettings = choosableAnimationSettings;
        }

        public virtual void OnPointerDown(PointerEventData eventData)
        {
            if (!_isSelectable)
            {
                return;
            }

            EventManager.Fire(new OnChoosableSelectedEvent() { Choosable = this });
        }

        public void PlaySpawn()
        {
            KillSpawnTween();

            _isSelectable = false;
            transform.localScale = Vector3.zero;

            _spawnTween = transform
                .DOScale(_animationSettings.Spawn.Value, _animationSettings.Spawn.Duration)
                .SetDelayAndEase(_animationSettings.Spawn)
                .OnComplete(() =>
                {
                    if (this != null && gameObject.activeInHierarchy)
                    {
                        _isSelectable = true;
                    }
                });
        }

        public virtual void OnOtherOneChoosed()
        {
            transform.DOScale(_animationSettings.Disapper);
        }

        public void OnCorrectOneChoosed(Action onChoosableGoneToCenter, Action OnChoosedAnimationCompleted)
        {
            _isSelectable = false;

            _rectTransform.SetAnchors(AnchorPresets.MiddleCenter);

            Tweener goToCenter = _rectTransform
                .DOAnchorPos(_animationSettings.Choosed.Sequence[0])
                .OnComplete(() => onChoosableGoneToCenter?.Invoke());

            Tweener scaleUp = _rectTransform.DOScale(_animationSettings.Choosed.Sequence[1]);

            Sequence sequence = DOTween.Sequence();
            sequence.Append(goToCenter);
            sequence.Append(scaleUp);
            sequence.AppendInterval(1f);
            sequence.OnComplete(() => OnChoosedAnimationCompleted?.Invoke());

            EventManager.Fire(new OnCorrectOneChoosedEvent() { Choosable = this });
        }

        public void ShowSelf()
        {
            EventManager.Fire<OnWrongOneChoosedEvent>();
            AudioManager.PlayTryAgainSoundRandomly();

            transform.DOKill();
            transform.DOPunchScale(_animationSettings.ShowSelf);
        }

        public void Hide()
        {
            _isSelectable = false;
            _rectTransform.DOScale(_animationSettings.Hide).OnComplete(Dispose);
        }

        public void SetCorrectAnswer(ItemData itemTuple)
        {
            _itemTuple = itemTuple;
            _isCorrectAnswer = true;
        }

        private void InvalidateState()
        {
            _isSelectable = false;

            KillSpawnTween();

            if (transform != null)
            {
                transform.DOKill();
            }

            if (_rectTransform != null)
            {
                _rectTransform.DOKill();
            }
        }

        private void KillSpawnTween()
        {
            if (_spawnTween != null)
            {
                _spawnTween.Kill(false);
                _spawnTween = null;
            }
        }

        [Serializable]
        public struct AnimationSettings
        {
            public TweenSettings Spawn;
            public TweenSettings ShowSelf;
            public TweenSettings Disapper;
            public SequenceSettings Choosed;
            public TweenSettings Hide;
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
    }
}
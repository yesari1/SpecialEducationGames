using DG.Tweening;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace SpecialEducationGames
{
    public class Choosable : MonoBehaviour, IPointerDownHandler,IFactoryObject<Choosable>
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

        private ItemTuple _itemTuple;

        public bool IsCorrectAnswer => _isCorrectAnswer;    

        public ItemTuple ItemTuple => _itemTuple;

        protected virtual void Awake()
        {
            _rectTransform = GetComponent<RectTransform>();
        }

        public void OnSpawn(FactoryBase<Choosable> factory)
        {
            _factory = factory;

        }

        public void Dispose()
        {
            transform.SetParent(null);
            _factory.Push(this);
        }

        public void Initialize(Sprite sprite,string text)
        {
            _isCorrectAnswer = false;

            if (sprite == null)
                _image.enabled = false;
            else
                _image.enabled = true;

            _image.sprite = sprite;
            _text.text = text;

            transform.localScale = Vector3.zero;

            //_spawnTween = transform.DOScale(_animationSettings.Spawn, true, true);
            //_spawnTween.Play();
        }

        public void SetAnimationSettings(AnimationSettings choosableAnimationSettings)
        {
            _animationSettings = choosableAnimationSettings;
        }

        public virtual void OnPointerDown(PointerEventData eventData)
        {
            EventManager.Fire(new OnChoosableSelectedEvent() { Choosable = this });
        }

        public IEnumerator Spawn()
        {
            yield return transform.DOScale(_animationSettings.Spawn.Value, _animationSettings.Spawn.Duration).SetDelayAndEase(_animationSettings.Spawn).WaitForCompletion();
        }

        public virtual void OnOtherOneChoosed()
        {
            transform.DOScale(_animationSettings.Disapper);
        }

        public void OnCorrectOneChoosed(Action onChoosableGoneToCenter,Action OnChoosedAnimationCompleted)
        {
            _rectTransform.SetAnchors(AnchorPresets.MiddleCenter);

            Tweener goToCenter = _rectTransform.DOAnchorPos(_animationSettings.Choosed.Sequence[0]).OnComplete(()=> onChoosableGoneToCenter?.Invoke());
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

            //Yanlýþ olan seçilmiþ
            AudioManager.PlayTryAgainSoundRandomly();

            transform.DOComplete();
            transform.DOPunchScale(_animationSettings.ShowSelf);
        }

        public void Hide()
        {
            _rectTransform.DOScale(_animationSettings.Hide).OnComplete(Dispose);
        }

        public void SetCorrectAnswer(ItemTuple itemTuple)
        {
            _itemTuple = itemTuple;
            _isCorrectAnswer = true;
        }


        [Serializable]
        public struct AnimationSettings
        {
            public TweenSettings Spawn;
            public TweenSettings ShowSelf;//This one choosed but other on clicked
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

    }
}
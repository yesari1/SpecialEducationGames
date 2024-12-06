using DG.Tweening;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace SpecialEducationGames
{
    public class VisualItem : MonoBehaviour, IFactoryObject<VisualItem>
    {
        [SerializeField] private Image _image;

        [SerializeField] private TextMeshProUGUI _text;

        protected AnimationSettings _animationSettings;

        private FactoryBase<VisualItem> _factory;

        protected RectTransform _rectTransform;

        private bool _isHidden;

        private string _correctText;

        private ItemTuple _itemTuple;

        public bool IsHidden => _isHidden;

        public ItemTuple ItemTuple => _itemTuple;

        private void Awake()
        {
            _rectTransform = GetComponent<RectTransform>();
        }

        public void Initialize(ItemTuple itemTuple,Sprite sprite = null,string text = "")
        {
            _itemTuple = itemTuple;

            if(text == "")
                _text.enabled = false;

            _image.sprite = sprite;
            _text.text = text;
            _isHidden = false;
        }

        public void SetAnimationSettings(AnimationSettings visualItemAnimationSettings)
        {
            _animationSettings = visualItemAnimationSettings;
        }


        public void OnSpawn(FactoryBase<VisualItem> factory)
        {
            _factory = factory;
        }

        public void Dispose()
        {
            _image.color = Color.white;
            _factory.Push(this);
        }

        internal void SetHidden()
        {
            _isHidden = true;
            _correctText = _text.text;
            _image.color = _animationSettings.HiddenColor;
            _text.text = "?";
        }

        public IEnumerator Spawn()
        {
            yield return transform.DOScale(_animationSettings.Spawn.Value, _animationSettings.Spawn.Duration).SetDelayAndEase(_animationSettings.Spawn).WaitForCompletion();
        }

        internal void OnCorrect()
        {
            _text.text = _correctText;
            _image.color = Color.white;

            transform.DOPunchScale(_animationSettings.PunchScale);
        }

        public void Hide()
        {
            _rectTransform.DOScale(_animationSettings.Hide).OnComplete(Dispose);
        }

        [Serializable]
        public struct AnimationSettings
        {
            public Color HiddenColor;
            public TweenSettings Spawn;
            public TweenSettings PunchScale;
            public TweenSettings Hide;
        }

    }
}

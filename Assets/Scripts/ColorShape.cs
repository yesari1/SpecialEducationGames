using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace SpecialEducationGames
{
    [Serializable]
    public class ColorShape : Choosable, IAnimationControllable
    {
        private ColorProperties colorProperty;
        [SerializeField] private GameObject shape;
        [SerializeField] private GameObject shapeInside;

        private LevelManager levelManager;
        private bool _isCorrect = false;

        public bool IsCorrect
        {
            get { return _isCorrect; }
        }

        public ColorProperties ColorProperty
        {
            get
            {
                return colorProperty;
            }
        }

        private void Update()
        {
            if (_scaleUp)
            {
                _rectTransform.localScale = Vector3.Lerp(_rectTransform.localScale, _maxScale, Time.deltaTime * _scaleUpSpeed);

                if (Vector3.Distance(_rectTransform.localScale, _maxScale) <= 0.1f)
                {
                    _scaleUp = false;
                    GameEventCaller.Instance.OnCorrectAnimationEnded();
                }
            }
        }

        public void SetColor(LevelManager levelManager, ColorProperties colorProperties)
        {
            shapeInside.GetComponent<Image>().color = colorProperties.color;
            colorProperty = colorProperties;
            this.levelManager = levelManager;
        }

        public void SetAsCorrect()
        {
            _isCorrect = true;
        }

        //public override void OnPointerDown(PointerEventData eventData)
        //{
        //    levelManager.OnAnswerChoose(this);
        //}

        public void PlayCorrectAnimation(float scaleUpSpeed, Vector3 maxScale)
        {
            this._maxScale = maxScale;
            this._scaleUpSpeed = scaleUpSpeed;
            _scaleUp = true;
        }
    }
}
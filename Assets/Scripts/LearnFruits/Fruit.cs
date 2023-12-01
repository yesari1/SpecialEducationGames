using DG.Tweening;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using UnityEngine.UIElements;
using Zenject;

namespace SpecialEducationGames
{
    public class Fruit : Choosable, IAnimationControllable
    {
        private float _time = 0;

        private void Update()
        {
            if (_scaleUp)
            {
                _rectTransform.localScale = Vector3.Lerp(_rectTransform.localScale, _maxScale, _time / _scaleUpSpeed);
                //scaleUpSpeed aslýnda zaman ý temsil ediyor
                //Sonradan deðiþtirdik o yüzden kalsýn böyle :)
                _time += Time.deltaTime;
                if (Vector3.Distance(_rectTransform.localScale, _maxScale) <= 0.01f)
                {
                    _scaleUp = false;
                    GameEventCaller.Instance.OnCorrectAnimationEnded();
                }
            }
        }

        public override void OnSpawned()
        {
            base.OnSpawned();
        }

        public override void OnPointerDown(PointerEventData eventData)
        {
            GameEventCaller.Instance.OnChoosablePointerDown(this);
        }

        public void PlayCorrectAnimation(float scaleUpSpeed, Vector3 maxScale)
        {
            GameManager.SetAnchors(_rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f));

            //rectTransform.anchorMax = new Vector2(0.5f, 0.5f);
            //rectTransform.anchorMin = new Vector2(0.5f, 0.5f);
            this._maxScale = maxScale;
            this._scaleUpSpeed = scaleUpSpeed;
            _scaleUp = true;

        }

        public void PlayHideAnimation()
        {
            Destroy(gameObject, 2.5f);
        }


        public class Factory : PlaceholderFactory<Fruit>
        {

        }

    }
}
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SpecialEducationGames
{
    public class StageController : MonoBehaviour
    {
        private List<GameObject> _stars;
        private RectTransform _rectTransform;
        private int _filledStarCount = 0;

        [SerializeField] private GameObject _startPrefab;
        [SerializeField] private Sprite _starFill;

        [SerializeField] private int _spacing;
        [SerializeField] private int _padding;

        private void OnEnable()
        {
            EventManager.Subscribe<OnStageCompletedEvent>(OnStageCompleted);
        }

        private void OnDisable()
        {
            EventManager.Unsubscribe<OnStageCompletedEvent>(OnStageCompleted);
        }

        private void Awake()
        {
            _rectTransform = GetComponent<RectTransform>();
            _stars = new List<GameObject>();
        }

        private void Start()
        {
            SetStars(GameManager.MaxStage);
        }

        public void SetStars(int starCount)
        {
            _rectTransform.sizeDelta = new Vector2(_spacing * (starCount - 1) + _startPrefab.GetComponent<RectTransform>().sizeDelta.x / 2 + _padding * 2, 100);
            _rectTransform.anchoredPosition = new Vector2(_rectTransform.sizeDelta.x / 2 + 25, 75);

            for (int i = 0; i < starCount; i++)
            {
                GameObject star = Instantiate(_startPrefab, transform);
                star.GetComponent<RectTransform>().pivot = new Vector2(0, 0.5f);
                star.GetComponent<RectTransform>().anchoredPosition = new Vector2(_padding + _spacing * i, 0);
                star.GetComponent<RectTransform>().SetAnchors(AnchorPresets.MiddleCenter);
                _stars.Add(star);
            }
        }


        public void FillStar()
        {
            if (_stars.Count < _filledStarCount)
                return;

            _stars[_filledStarCount].GetComponent<Image>().sprite = _starFill;
            _stars[_filledStarCount].GetComponent<Animation>().Play();
            _filledStarCount++;
        }


        private void OnStageCompleted(OnStageCompletedEvent @event)
        {
            FillStar();
        }


    }
}
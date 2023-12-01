using EasyButtons;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace SpecialEducationGames
{
    public class PointController : MonoBehaviour
    {
        [SerializeField] private Point _pointPrefab;
        [SerializeField] private List<Point> _points;
        [SerializeField] private PointSettings _pointSettings;

        private Canvas _canvas;

        private void OnEnable()
        {
            GameEventReceiver.OnStageCompletedEvent += OnStageCompleted;
        }

        private void OnDisable()
        {
            GameEventReceiver.OnStageCompletedEvent -= OnStageCompleted;
        }

        private void Awake()
        {
            CreatePoints();
        }

        private void OnStageCompleted()
        {
            for (int i = 0; i < _points.Count; i++)
            {
                _points[i].IsUsing = false;
            }
        }

        public Point GetRandomPoint()
        {
            Point point;

            point = _points.Where((point) => !point.IsUsing).OrderBy(x => Guid.NewGuid()).FirstOrDefault();

            point.IsUsing = true;

            return point;
        }

        public void CreatePoints()
        {
            _canvas = FindObjectOfType<Canvas>();

            for (int i = 0; i < _pointSettings.Count; i++)
            {
                Point point = Instantiate(_pointPrefab,transform);
                point.RectTransform.SetAnchors(AnchorPresets.MiddleLeft);
                _points.Add(point);
            }

        }

        [Serializable]
        public struct PointSettings
        {
            public int Count;
        }

    }
}

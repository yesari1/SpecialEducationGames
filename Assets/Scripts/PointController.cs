using DG.Tweening;
using EasyButtons;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;

namespace SpecialEducationGames
{
    [RequireComponent(typeof(HorizontalLayoutGroup))]
    public class PointController : MonoBehaviour
    {
        private Point _pointPrefab;
        private List<GameObject> _items;

        private void Construct(Point pointPrefab)
        {
            if(_pointPrefab == null)
                _pointPrefab = pointPrefab;
        }

        private void Awake()
        {
            _items = new List<GameObject>();
        }

        //public Point GetRandomPoint()
        //{
        //    Point point;

        //    point = _items.Where((point) => !point.IsUsing).OrderBy(x => Guid.NewGuid()).FirstOrDefault();

        //    point.IsUsing = true;

        //    return point;
        //}

        public void SetOffset(Vector2 offset)
        {
            GetComponent<RectTransform>().anchoredPosition += offset;
        }

        public void AddItem(GameObject item)
        {
            _items.Add(item);
            item.transform.SetParent(transform, true);
        }

        public void ClearChilds()
        {
            for (int i = 0; i < _items.Count; i++)
                Destroy(_items[i]);
            _items.Clear();
        }

        public void HideAllItems(TweenSettings tweenSettings)
        {
            Sequence sequence = DOTween.Sequence(); 
            for (int i = 0; i < _items.Count; i++)
            {
                sequence.Append(_items[i].transform.DOScale(tweenSettings));
            }
            sequence.Play();
        }

        /// <summary>
        /// Not from list, remove as child
        /// </summary>
        /// <param name="item"></param>
        public void RemoveChild(GameObject item)
        {
            item.transform.SetParent(transform.parent);
        }

        [Serializable]
        public struct PointSettings
        {
            public int Count;
            public float Spacing;
        }

    }
}

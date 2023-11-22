using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace SpecialEducationGames
{
    public class PointController : MonoBehaviour
    {
        [SerializeField] private List<Point> _points;



        public Point GetRandomPoint()
        {
            Point point;

            point = _points.Where((point) => !point.IsUsing).OrderBy(x => Guid.NewGuid()).FirstOrDefault();

            point.IsUsing = true;

            return point;
        }
    }
}

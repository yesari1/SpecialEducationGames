using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    [CreateAssetMenu(fileName = "NumberData", menuName = "SEG/NumberData")]
    public class NumberData : ScriptableObject
    {
        public List<ItemTuple> NumberTuples;
    }
}

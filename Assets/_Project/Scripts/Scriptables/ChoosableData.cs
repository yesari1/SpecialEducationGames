using System;
using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    [CreateAssetMenu(fileName = "ChoosableData", menuName = "SEG/ChoosableData")]
    public class ChoosableData : ScriptableObject
    {
        public List<ItemData> ChoosableTuples;
    }


}

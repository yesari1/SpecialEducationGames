using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    [CreateAssetMenu(fileName = "ChoosableData", menuName = "SEG/ChoosableData")]
    public class ChoosableData : ScriptableObject
    {
        public List<ItemTuple> ChoosableTuples;
    }

    [Serializable]
    public struct ItemTuple
    {
        public string Name;
        public Sprite Sprite;
        public GameSound Audio;
    }

}

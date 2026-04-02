using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Localization;

namespace SpecialEducationGames
{
    [CreateAssetMenu(fileName = "ItemTupleData", menuName = "SEG/ItemTupleData")]
    public class ItemData : ScriptableObject
    {
        public string Name;
        public Sprite Sprite;
        public LocalizedString LocalizedName;
        public SoundData Audio;
    }
}

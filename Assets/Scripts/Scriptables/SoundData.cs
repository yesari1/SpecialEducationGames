using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    [CreateAssetMenu(fileName = "SoundData", menuName = "SEG/SoundData")]
    public class SoundData : ScriptableObject
    {
        public List<GameSoundTuple> GameSoundTuples;
        public List<MenuSoundTuple> MenuSoundTuples;
    }
}

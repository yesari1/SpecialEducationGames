using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    [CreateAssetMenu(fileName = "SoundSettingsData", menuName = "SEG/SoundSettingsData")]
    public class SoundSettingsData : ScriptableObject
    {
        public List<GameSoundTuple> GameSoundTuples;
        public List<MenuSoundTuple> MenuSoundTuples;
    }
}

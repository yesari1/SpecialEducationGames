using System;
using System.Collections.Generic;
using UnityEngine;
using Zenject;
using static SpecialEducationGames.Choosable;

namespace SpecialEducationGames
{
    [CreateAssetMenu(fileName = "LearnFruitsSettingsInstaller", menuName = "Installers/LearnFruitsSettingsInstaller")]
    public class LearnFruitsSettingsInstaller : ScriptableObjectInstaller<LearnFruitsSettingsInstaller>
    {
        public PrefabSettings PrefabSettings;
        public ChoosableTypes ChoosableTypes;

        public override void InstallBindings()
        {
            Container.BindInstance(PrefabSettings);
            Container.BindInstance(ChoosableTypes);
        }

    }

    [Serializable]
    public struct PrefabSettings
    {
        public Fruit Fruit;
    }

}
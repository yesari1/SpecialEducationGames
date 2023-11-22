using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Zenject;

namespace SpecialEducationGames
{
    public class GameInstaller : MonoInstaller
    {
        public override void InstallBindings()
        {
            LearnFruitsInstaller.Install(Container);
            //Container.Bind<StageController>().FromComponentInHierarchy().AsSingle();
            //Container.Bind<ItemPointsController>().FromComponentInHierarchy().AsSingle();
        }

    }
}

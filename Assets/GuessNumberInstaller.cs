using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Zenject;

namespace SpecialEducationGames
{
    public class GuessNumberInstaller : MonoInstaller
    {
        public override void InstallBindings()
        {
            Container.Bind<StageController>().FromComponentInHierarchy().AsSingle();
            Container.Bind<PointController>().FromComponentInHierarchy().AsSingle();
            Container.Bind<NumberPlacer>().FromComponentInHierarchy().AsSingle();

            Container.Bind<Canvas>().FromComponentInHierarchy().AsSingle();

        }

    }
}

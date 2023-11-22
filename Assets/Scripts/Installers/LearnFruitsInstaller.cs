using SpecialEducationGames;
using UnityEngine;
using Zenject;

public class LearnFruitsInstaller : Installer<LearnFruitsInstaller>
{
    public override void InstallBindings()
    {
        Container.Bind<StageController>().FromComponentInHierarchy().AsSingle();
        Container.Bind<PointController>().FromComponentInHierarchy().AsSingle();
        Container.Bind<Canvas>().FromComponentInHierarchy().AsSingle();
    }
}
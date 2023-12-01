using SpecialEducationGames;
using UnityEngine;
using Zenject;

public class LearnFruitsInstaller : MonoInstaller
{
    [Inject]
    private PrefabSettings _prefabSettings;

    public override void InstallBindings()
    {
        Container.Bind<StageController>().FromComponentInHierarchy().AsSingle();
        Container.Bind<PointController>().FromComponentInHierarchy().AsSingle();
        Container.Bind<MatchingManager>().FromComponentInHierarchy().AsSingle();
        Container.Bind<Canvas>().FromComponentInHierarchy().AsSingle();

        Container.BindFactory<Choosable, Choosable.Factory>().FromComponentInNewPrefab(_prefabSettings.Fruit).UnderTransform(GameObject.FindGameObjectWithTag("Canvas").transform);
    }

}
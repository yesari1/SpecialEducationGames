using SpecialEducationGames;
using UnityEngine;
using Zenject;

[CreateAssetMenu(fileName = "LearnFruitsAnimationInstaller", menuName = "Installers/LearnFruitsAnimationInstaller")]
public class LearnFruitsAnimationInstaller : ScriptableObjectInstaller<LearnFruitsAnimationInstaller>
{

    public TextController.AnimationSettings TextControllerAnimationSettings;

    public override void InstallBindings()
    {
        Container.BindInstance(TextControllerAnimationSettings);
    }
}
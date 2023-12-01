using SpecialEducationGames;
using UnityEngine;
using Zenject;

[CreateAssetMenu(fileName = "LearnFruitsAnimationInstaller", menuName = "Installers/LearnFruitsAnimationInstaller")]
public class LearnFruitsAnimationInstaller : ScriptableObjectInstaller<LearnFruitsAnimationInstaller>
{

    public MatchingTextManager.AnimationSettings TextControllerAnimationSettings;
    public Choosable.AnimationSettings ChoosableAnimationSettings;

    public override void InstallBindings()
    {
        Container.BindInstance(TextControllerAnimationSettings);
        Container.BindInstance(ChoosableAnimationSettings);
    }
}
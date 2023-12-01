using SpecialEducationGames;
using UnityEngine;
using Zenject;

[CreateAssetMenu(fileName = "LearnFruitsParticleInstaller", menuName = "Installers/LearnFruitsParticleInstaller")]
public class LearnFruitsParticleInstaller : ScriptableObjectInstaller<LearnFruitsParticleInstaller>
{
    public LearnFruitsManager.ParticleSettings ChoosableParticleSettings;
    public override void InstallBindings()
    {
        Container.BindInstance(ChoosableParticleSettings);
    }
}
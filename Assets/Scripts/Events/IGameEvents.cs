using System.Threading.Tasks;
using UnityEditor.Rendering;

namespace SpecialEducationGames
{
    public interface IGameEvents
    {
        public void OnCenterTextAnimationEnded();

        public void OnStageCompleted();
    }

}

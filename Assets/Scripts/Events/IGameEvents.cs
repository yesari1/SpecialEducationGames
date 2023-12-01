using System.Threading.Tasks;
using UnityEditor.Rendering;
using static SpecialEducationGames.Choosable;

namespace SpecialEducationGames
{
    public interface IGameEvents
    {
        //Matching Game
        public void OnCenterTextAnimationEnded();

        public void OnChoosedRight();

        public void OnBeforeStageCompleted();

        public void OnStageCompleted();

        public void OnGameFinished();

        public void OnCorrectAnimationEnded();

        public void OnChoosablePointerDown(Choosable choosable);

        public void OnMatchingStarted(ChoosableType choosableType);
    }

}

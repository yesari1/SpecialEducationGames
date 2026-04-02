using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    public class MatchingPresenter : PresenterBase<MatchingView>
    {
        private MatchingManager _manager;
        private bool _isSubscribed;

        public override void InitializePresenter()
        {
            TryResolveManager();
        }

        public void Activate()
        {
            if (_isSubscribed)
            {
                return;
            }

            EventManager.Subscribe<OnChoosableSelectedEvent>(View.OnChoosableSelected);
            EventManager.Subscribe<OnShowInfoTextAnimationCompletedEvent>(OnShowInfoTextAnimationCompleted);

            _isSubscribed = true;
        }

        public void Deactivate()
        {
            if (!_isSubscribed)
            {
                return;
            }

            EventManager.Unsubscribe<OnChoosableSelectedEvent>(View.OnChoosableSelected);
            EventManager.Unsubscribe<OnShowInfoTextAnimationCompletedEvent>(OnShowInfoTextAnimationCompleted);

            _isSubscribed = false;
        }

        public override void Dispose()
        {
            Deactivate();
        }

        public bool TryGetItemTuples(out List<ItemData> itemTuples)
        {
            itemTuples = new List<ItemData>();

            if (!TryResolveManager())
            {
                return false;
            }

            IReadOnlyList<ItemData> sourceItemTuples = _manager.ItemTuples;
            if (sourceItemTuples == null)
            {
                return true;
            }

            for (int i = 0; i < sourceItemTuples.Count; i++)
            {
                ItemData itemTuple = sourceItemTuples[i];
                if (itemTuple != null)
                {
                    itemTuples.Add(itemTuple);
                }
            }

            return true;
        }

        public Choosable CreateChoosable(Transform parent)
        {
            if (!TryResolveManager())
            {
                return null;
            }

            if (_manager.ChoosableFactory == null)
            {
                Debug.LogError("MatchingManager üzerindeki ChoosableFactory atanmadı.");
                return null;
            }

            return _manager.ChoosableFactory.Create(Vector2.zero, Quaternion.identity, parent);
        }

        public void OnStageCompleted()
        {
            EventManager.Fire<OnStageCompletedEvent>();
        }

        public void ShowInfoText(ItemData itemTuple)
        {
            if (itemTuple == null)
            {
                return;
            }

            EventManager.Fire(new OnShowInfoTextEvent() { ItemTuple = itemTuple });
        }

        private void OnShowInfoTextAnimationCompleted(OnShowInfoTextAnimationCompletedEvent @event)
        {
            View.PlayInfoTextShowedSequence();
        }

        private bool TryResolveManager()
        {
            if (_manager != null)
            {
                return true;
            }

            _manager = Object.FindObjectOfType<MatchingManager>();

            if (_manager != null)
            {
                return true;
            }

            Debug.LogError("Sahnede aktif bir MatchingManager bulunamadı.");
            return false;
        }
    }
}
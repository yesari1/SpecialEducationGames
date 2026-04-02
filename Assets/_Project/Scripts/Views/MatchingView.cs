using DG.Tweening;
using MEC;
using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    public class MatchingView : UIView<MatchingPresenter>
    {
        private const int ChoosableCount = 3;

        [SerializeField] private LayoutGroup _layoutGroup;

        [Header("Particles")]
        [SerializeField] private ParticleSystem _circleParticles;

        [Header("Animations")]
        [SerializeField] private AnimationSettings _animationSettings;

        [SerializeField] private Choosable.AnimationSettings _choosableAnimationSettings;

        private List<Choosable> _choosables;
        private List<ItemData> _itemTuples;

        private int _selectedChoosableId = -1;
        private ItemData _selectedChoosableTuple;
        private Choosable _selectedChoosable;

        private CoroutineHandle _createChoosablesCoroutine;
        private CoroutineHandle _infoTextShowedCoroutine;

        private bool _isInitialized;
        private int _routineVersion;

        private void OnEnable()
        {
            Presenter?.Activate();
            TryStartCreateChoosables();
        }

        private void OnDisable()
        {
            Presenter?.Deactivate();
            InvalidateRunningOperations();
        }

        protected override void OnDestroy()
        {
            InvalidateRunningOperations();
            base.OnDestroy();
        }

        public override void InitializeView()
        {
            _choosables = new List<Choosable>();

            if (!Presenter.TryGetItemTuples(out _itemTuples))
            {
                Debug.LogError("MatchingView baþlatýlamadý. MatchingManager bulunamadý.");
                return;
            }

            if (_itemTuples.Count < ChoosableCount)
            {
                Debug.LogError($"MatchingView baþlatýlamadý. En az {ChoosableCount} adet ItemTupleData atanmalý.");
                return;
            }

            _isInitialized = true;
            TryStartCreateChoosables();
        }

        public void PlayInfoTextShowedSequence()
        {
            if (!CanRun(_routineVersion))
            {
                return;
            }

            StopInfoTextShowedCoroutine();

            int routineVersion = _routineVersion;
            _infoTextShowedCoroutine = Timing.RunCoroutine(OnInfoTextShowed(routineVersion));
        }

        private void TryStartCreateChoosables()
        {
            if (!_isInitialized || !isActiveAndEnabled)
            {
                return;
            }

            if (_itemTuples == null || _itemTuples.Count < ChoosableCount)
            {
                return;
            }

            if (_choosables != null && _choosables.Count > 0)
            {
                return;
            }

            StopCreateChoosablesCoroutine();

            int routineVersion = _routineVersion;
            _createChoosablesCoroutine = Timing.RunCoroutine(CreateChoosables(routineVersion));
        }

        private IEnumerator<float> CreateChoosables(int routineVersion)
        {
            if (!CanRun(routineVersion))
            {
                yield break;
            }

            if (_itemTuples.Count < ChoosableCount)
            {
                Debug.LogWarning($"Yeni tur oluþturulamadý. Kalan ItemTupleData sayýsý {ChoosableCount}'ten az.");
                yield break;
            }

            yield return Timing.WaitForSeconds(0.5f);

            if (!CanRun(routineVersion))
            {
                yield break;
            }

            Helper.Shuffle(_itemTuples);

            _selectedChoosableId = Random.Range(0, ChoosableCount);
            _selectedChoosableTuple = _itemTuples[_selectedChoosableId];

            for (int i = 0; i < ChoosableCount; i++)
            {
                if (!CanRun(routineVersion))
                {
                    yield break;
                }

                Choosable choosable = Presenter.CreateChoosable(_layoutGroup.transform);
                if (choosable == null)
                {
                    Debug.LogError("Choosable oluþturulamadý.");
                    yield break;
                }

                choosable.Initialize(_itemTuples[i].Sprite, string.Empty);
                choosable.SetAnimationSettings(_choosableAnimationSettings);

                Vector3 pos = choosable.transform.localPosition;
                pos.z = 0f;
                choosable.transform.localPosition = pos;
                choosable.transform.localScale = Vector3.zero;

                _choosables.Add(choosable);

                yield return Timing.WaitForOneFrame;
            }

            if (!CanRun(routineVersion) || _choosables.Count <= _selectedChoosableId)
            {
                yield break;
            }

            _selectedChoosable = _choosables[_selectedChoosableId];
            _selectedChoosable.SetCorrectAnswer(_selectedChoosableTuple);

            Presenter.ShowInfoText(_selectedChoosableTuple);
        }

        public IEnumerator<float> OnInfoTextShowed(int routineVersion)
        {
            //Debug.Log("OnInfoTextShowed");
            for (int i = 0; i < _choosables.Count; i++)
            {
                if (!CanRun(routineVersion) || _choosables[i] == null)
                {
                    yield break;
                }

                _choosables[i].PlaySpawn();

                yield return Timing.WaitForSeconds(_choosableAnimationSettings.Spawn.Duration / 2f);
            }
        }

        public void OnChoosableSelected(OnChoosableSelectedEvent onChoosableSelectedEvent)
        {
            if (!_isInitialized || !isActiveAndEnabled || _selectedChoosable == null)
            {
                return;
            }

            if (onChoosableSelectedEvent.Choosable.IsCorrectAnswer)
            {
                OnRightOneSelected();
            }
            else
            {
                _selectedChoosable.ShowSelf();
            }
        }

        private void OnRightOneSelected()
        {
            _layoutGroup.enabled = false;

            for (int i = 0; i < _choosables.Count; i++)
            {
                if (i == _selectedChoosableId)
                {
                    continue;
                }

                _choosables[i].Hide();
            }

            _selectedChoosable.OnCorrectOneChoosed(OnChoosableGoneToCenter, OnChoosedAnimationCompleted);
        }

        private void OnChoosableGoneToCenter()
        {
            if (!_isInitialized || !isActiveAndEnabled)
            {
                return;
            }

            _circleParticles.Play();
        }

        private void OnChoosedAnimationCompleted()
        {
            if (!_isInitialized || !isActiveAndEnabled || _selectedChoosable == null)
            {
                return;
            }

            Presenter.OnStageCompleted();
            _selectedChoosable.Hide();

            _selectedChoosable = null;
            _selectedChoosableId = -1;
            _choosables.Clear();
            _layoutGroup.enabled = true;

            if (GameManager.IsGameFinished)
            {
                return;
            }

            _itemTuples.Remove(_selectedChoosableTuple);

            if (_itemTuples.Count >= ChoosableCount)
            {
                TryStartCreateChoosables();
            }
            else
            {
                Debug.LogError($"Yeni tur baþlatýlmadý. Kalan ItemTupleData sayýsý {ChoosableCount}'ten az.");
            }
        }

        private void InvalidateRunningOperations()
        {
            _routineVersion++;
            StopRunningCoroutines();
        }

        private void StopRunningCoroutines()
        {
            StopCreateChoosablesCoroutine();
            StopInfoTextShowedCoroutine();
        }

        private void StopCreateChoosablesCoroutine()
        {
            Timing.KillCoroutines(_createChoosablesCoroutine);
            _createChoosablesCoroutine = default;
        }

        private void StopInfoTextShowedCoroutine()
        {
            Timing.KillCoroutines(_infoTextShowedCoroutine);
            _infoTextShowedCoroutine = default;
        }

        private bool CanRun(int routineVersion)
        {
            return _isInitialized && isActiveAndEnabled && routineVersion == _routineVersion;
        }

        [Serializable]
        public struct AnimationSettings
        {
            public TweenSettings MatchTextShow;
            public TweenSettings MatchTextGoUp;
            public TweenSettings CongTextScaleUp;
        }
    }
}
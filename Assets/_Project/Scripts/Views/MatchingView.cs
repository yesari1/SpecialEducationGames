using DG.Tweening;
using MEC;
using System;
using System.Collections;
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

        private List<ItemTupleData> _itemTuples;

        private int _selectedChoosableId;

        private ItemTupleData _selectedChoosableTuple;

        private Choosable _selectedChoosable;

        public override void InitializeView()
        {
            _choosables = new List<Choosable>();
            _itemTuples = new List<ItemTupleData>();

            if (MatchingManager.ItemTuples != null)
            {
                for (int i = 0; i < MatchingManager.ItemTuples.Count; i++)
                {
                    ItemTupleData itemTuple = MatchingManager.ItemTuples[i];
                    if (itemTuple != null)
                    {
                        _itemTuples.Add(itemTuple);
                    }
                }
            }

            if (_itemTuples.Count < ChoosableCount)
            {
                Debug.LogError($"MatchingView baþlatýlamadý. En az {ChoosableCount} adet ItemTupleData atanmalý.");
                return;
            }

            StartCoroutine(CreateChoosables());
        }

        private IEnumerator CreateChoosables()
        {
            if (_itemTuples.Count < ChoosableCount)
            {
                Debug.LogWarning($"Yeni tur oluþturulamadý. Kalan ItemTupleData sayýsý {ChoosableCount}'ten az.");
                yield break;
            }

            yield return new WaitForSeconds(0.5f);

            Helper.Shuffle(_itemTuples);

            _selectedChoosableId = Random.Range(0, ChoosableCount);
            _selectedChoosableTuple = _itemTuples[_selectedChoosableId];

            for (int i = 0; i < ChoosableCount; i++)
            {
                Choosable choosable = MatchingManager.ChoosableFactory.Create(Vector2.zero, Quaternion.identity, _layoutGroup.transform);
                choosable.Initialize(_itemTuples[i].Sprite, string.Empty);
                choosable.SetAnimationSettings(_choosableAnimationSettings);

                Vector3 pos = choosable.transform.localPosition;
                pos.z = 0;
                choosable.transform.localPosition = pos;

                _choosables.Add(choosable);

                yield return null;

                choosable.transform.localScale = Vector3.zero;
            }

            _selectedChoosable = _choosables[_selectedChoosableId];
            _selectedChoosable.SetCorrectAnswer(_selectedChoosableTuple);

            Presenter.ShowInfoText(_selectedChoosableTuple);
        }

        public IEnumerator<float> OnInfoTextShowed()
        {
            for (int i = 0; i < _choosables.Count; i++)
            {
                StartCoroutine(_choosables[i].Spawn());
                yield return Timing.WaitForSeconds(_choosableAnimationSettings.Spawn.Duration / 2f);
            }
        }

        public void OnChoosableSelected(OnChoosableSelectedEvent onChoosableSelectedEvent)
        {
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
            _circleParticles.Play();
        }

        private void OnChoosedAnimationCompleted()
        {
            Presenter.OnStageCompleted();
            _selectedChoosable.Hide();

            _selectedChoosable = null;
            _selectedChoosableId = -1;
            _choosables.Clear();
            _layoutGroup.enabled = true;

            if (!GameManager.IsGameFinished)
            {
                _itemTuples.Remove(_selectedChoosableTuple);

                if (_itemTuples.Count >= ChoosableCount)
                {
                    StartCoroutine(CreateChoosables());
                }
                else
                {
                    Debug.LogError($"Yeni tur baþlatýlmadý. Kalan ItemTupleData sayýsý {ChoosableCount}'ten az.");
                }
            }
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
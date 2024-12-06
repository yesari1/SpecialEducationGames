using DG.Tweening;
using MEC;
using SpecialEducationGames;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    public class MatchingView : UIView<MatchingPresenter>
    {
        [SerializeField] private LayoutGroup _layoutGroup;

        [Header("Particles")]
        [SerializeField] private ParticleSystem _circleParticles;

        [Header("Animations")]
        [SerializeField] private AnimationSettings _animationSettings;

        [SerializeField] private Choosable.AnimationSettings _choosableAnimationSettings;

        private List<Choosable> _choosables;

        private List<ItemTuple> _choosableTuples;

        private int _selectedChoosableId;

        private ItemTuple _selectedChoosableTuple;

        private Choosable _selectedChoosable;

        public override void InitializeView()
        {
            _choosableTuples = new List<ItemTuple>(MatchingManager.ChoosableData.ChoosableTuples);

            _choosables = new List<Choosable>();

            StartCoroutine(CreateChoosables());
        }

        private IEnumerator CreateChoosables()
        {
            yield return new WaitForSeconds(0.5f);

            Helper.Shuffle(_choosableTuples);

            _selectedChoosableId = Random.Range(0, 3);

            _selectedChoosableTuple = _choosableTuples[_selectedChoosableId];

            for (int i = 0; i < 3; i++)
            {
                Choosable choosable = MatchingManager.ChoosableFactory.Create(Vector2.zero, Quaternion.identity, _layoutGroup.transform);
                choosable.Initialize(_choosableTuples[i].Sprite, "");
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
            for (int i = 0; i < 3; i++)
            {
                StartCoroutine(_choosables[i].Spawn());
                yield return Timing.WaitForSeconds(_choosableAnimationSettings.Spawn.Duration / 2f);
            }
        }


        public void OnChoosableSelected(OnChoosableSelectedEvent onChoosableSelectedEvent)
        {
            if(onChoosableSelectedEvent.Choosable.IsCorrectAnswer)
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
                    continue;

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
                _choosableTuples.RemoveAt(_choosableTuples.FindIndex((x) => x.Name == _selectedChoosableTuple.Name));
                StartCoroutine(CreateChoosables());
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

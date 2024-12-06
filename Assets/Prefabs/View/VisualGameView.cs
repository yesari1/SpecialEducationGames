using MEC;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    public class VisualGameView : UIView<VisualGamePresenter>
    {
        [SerializeField] private string _startText;

        [SerializeField] private LayoutGroup _topLayoutGroup;

        [SerializeField] private LayoutGroup _bottomLayoutGroup;

        [SerializeField] private ParticleSystem _circleParticles;

        [SerializeField] private Choosable.AnimationSettings _choosableAnimationSettings;

        [SerializeField] private VisualItem.AnimationSettings _visualItemAnimationSettings;

        private List<VisualItem> _visuals;

        private List<Choosable> _choosables;

        private Choosable _correctChoosable;

        private VisualItem _hiddenVisual;

        public override void InitializeView()
        {
            _visuals = new List<VisualItem>();
            _choosables = new List<Choosable>();
        }

        public void PlaceVisualObjects(List<VisualItem> visualItems)
        {
            for (int i = 0; i < visualItems.Count; i++)
            {
                VisualItem visualItem = visualItems[i];
                visualItem.transform.SetParent(_topLayoutGroup.transform);
                visualItem.SetAnimationSettings(_visualItemAnimationSettings);

                visualItem.transform.localScale = Vector3.zero;

                if (visualItem.IsHidden)
                    _hiddenVisual = visualItem;

                Vector3 pos = visualItem.transform.localPosition;
                pos.z = 0;
                visualItem.transform.localPosition = pos;

                _visuals.Add(visualItem);

                //Animasyonlar
            }
        }

        public void PlaceChoosableObjects(List<Choosable> choosables)
        {
            for (int i = 0; i < choosables.Count; i++)
            {
                Choosable choosable = choosables[i];
                choosable.transform.SetParent(_bottomLayoutGroup.transform);
                choosable.SetAnimationSettings(_choosableAnimationSettings);
                
                Vector3 pos = choosable.transform.localPosition;
                pos.z = 0;
                choosable.transform.localPosition = pos;

                if (choosable.IsCorrectAnswer)
                    _correctChoosable = choosable;

                _choosables.Add(choosable);
            }

            Presenter.ShowInfoText(_startText);
        }

        public IEnumerator<float> OnInfoTextShowed()
        {
            for (int i = 0; i < _visuals.Count; i++)
            {
                StartCoroutine(_visuals[i].Spawn());
                yield return Timing.WaitForSeconds(_visualItemAnimationSettings.Spawn.Duration / 2f);
            }

            for (int i = 0; i < _choosables.Count; i++)
            {
                StartCoroutine(_choosables[i].Spawn());
                yield return Timing.WaitForSeconds(_choosableAnimationSettings.Spawn.Duration / 2f);
            }
        }

        internal void OnChoosableSelected(Choosable choosable)
        {
            if (choosable.IsCorrectAnswer)
            {
                OnRightOneSelected();
            }
            else
            {
                _correctChoosable.ShowSelf();
            }
        }

        private void OnRightOneSelected()
        {
            _topLayoutGroup.enabled = false;
            _bottomLayoutGroup.enabled = false;

            for (int i = 0; i < _choosables.Count; i++)
            {
                if (_choosables[i].IsCorrectAnswer)
                    continue;

                _choosables[i].Hide();
            }

            _correctChoosable.OnCorrectOneChoosed(OnChoosableGoneToCenter, OnChoosedAnimationCompleted);
        }

        private void OnChoosableGoneToCenter()
        {
            _circleParticles.Play();
            _hiddenVisual.OnCorrect();
        }

        private void OnChoosedAnimationCompleted()
        {
            _topLayoutGroup.enabled = true;
            _bottomLayoutGroup.enabled = true;

            _correctChoosable.Hide();

            for (int i = 0; i < _visuals.Count; i++)
            {
                _visuals[i].Hide();
            }

            _choosables.Clear();
            _visuals.Clear();

            Timing.RunCoroutine(Presenter.OnStageCompleted(2));
        }


        //private IEnumerator CreateChoosables()
        //{
        //    yield return new WaitForSeconds(0.5f);

        //    Helper.Shuffle(_choosableTuples);

        //    _selectedChoosableId = Random.Range(3, 10);

        //    _selectedChoosableTuple = _choosableTuples[_selectedChoosableId];

        //    for (int i = 0; i < 3; i++)
        //    {
        //        Choosable choosable = MatchingManager.ChoosableFactory.Create(Vector2.zero, Quaternion.identity, _topLayoutGroup.transform);
        //        choosable.Initialize(i, _choosableTuples[i], _choosableAnimationSettings);
        //        Vector3 pos = choosable.transform.localPosition;
        //        pos.z = 0;

        //        choosable.transform.localPosition = pos;

        //        _choosables.Add(choosable);

        //        yield return null;

        //        choosable.transform.localScale = Vector3.zero;
        //    }

        //    _selectedChoosable = _choosables[_selectedChoosableId];

        //    Presenter.ShowInfoText(_selectedChoosableTuple.Name);

        //}

        [Serializable]
        public struct AnimationSettings
        {
            public TweenSettings Spawn;
            public TweenSettings ShowSelf;//This one choosed but other on clicked
            public TweenSettings Disapper;//OtherOneChoosed
            public SequenceSettings Choosed;//On Truly Choosed
            public TweenSettings Hide;//On Truly Choosed Hide
        }


    }
}

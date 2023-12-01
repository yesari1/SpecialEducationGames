using System;
using System.Collections.Generic;
using UnityEngine;
using Zenject;
using static SpecialEducationGames.Choosable;
using static SpecialEducationGames.Fruit;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    [RequireComponent(typeof(MatchingTextManager))]
    public class MatchingManager : MonoBehaviour
    {
        private Choosable _choosed;
        private ChoosableType _choosedChoosableType;
        private Choosable.Factory _choosableFactory;
        private Choosable.ChoosableTypes _choosableTypes;

        private PointController _pointController;
        private List<Choosable> _createdChoosables;

        public ChoosableType Choosed => _choosedChoosableType;

        [Inject]
        private void Construct(ChoosableTypes choosableTypes, PointController pointController,Choosable.Factory factory)
        {
            _choosableTypes = choosableTypes;
            _pointController = pointController;
            _choosableFactory = factory;
        }

        private void OnEnable()
        {
            GameEventReceiver.OnCenterTextAnimationEndedEvent += OnCenterTextAnimationEnded;
            GameEventReceiver.OnChoosablePointerDownEvent += OnChoosablePointerDown;
        }

        private void OnDisable()
        {
            GameEventReceiver.OnCenterTextAnimationEndedEvent -= OnCenterTextAnimationEnded;
            GameEventReceiver.OnChoosablePointerDownEvent -= OnChoosablePointerDown;
        }

        private void Awake()
        {
            _createdChoosables = new List<Choosable>();
        }

        private void Start()
        {
            SetMatchObject();
        }

        private void SetMatchObject()
        {
            int rnd = Random.Range(0, _choosableTypes.Choosables.Count);
            _choosedChoosableType = _choosableTypes.Choosables[rnd];
            GameEventCaller.Instance.OnMatchingStarted(_choosedChoosableType);
            //ShowStartTextAnimation(choosedFruit.name);
        }

        private void OnCenterTextAnimationEnded()
        {
            SetChoosablePlaces();
        }

        private void SetChoosablePlaces()
        {

            List<ChoosableType> choosableTypes = new List<ChoosableType>(_choosableTypes.Choosables);

            Point point = _pointController.GetRandomPoint();
            
            Choosable choosable = CreateChoosable(point.RectTransform);
            
            _choosed = choosable;

            _choosed.SetChoosableType(_choosedChoosableType);

            choosableTypes.Remove(_choosedChoosableType);

            for (int i = 0; i < 2; i++)
            {
                point = _pointController.GetRandomPoint();

                int rndFruit = Random.Range(0, choosableTypes.Count);

                choosable = CreateChoosable(point.RectTransform);
                ChoosableType otherChoosableType = choosableTypes[rndFruit];
                choosable.SetChoosableType(otherChoosableType);

                choosableTypes.Remove(otherChoosableType);
            }
        }

        private Choosable CreateChoosable(RectTransform point)
        {
            Choosable choosable = _choosableFactory.Create();

            choosable.GetComponent<RectTransform>().anchorMax = point.anchorMax;
            choosable.GetComponent<RectTransform>().anchorMin = point.anchorMin;
            choosable.GetComponent<RectTransform>().anchoredPosition = point.anchoredPosition;

            _createdChoosables.Add(choosable);

            return choosable;
        }

        private void OnChoosablePointerDown(Choosable choosable)
        {
            if (_choosedChoosableType.Name == choosable.Type.Name)
            {
                //choosable.OnCorrectAnimationFinished += OnStageCompleted;

                //fruit.PlayCorrectAnimation(scaleUpSpeed, maxScale);

                for (int i = 0; i < _createdChoosables.Count; i++)
                {
                    if (_createdChoosables[i].name != choosable.name)
                    {
                        _createdChoosables[i].OnOtherOneChoosed();
                    }
                }
                _createdChoosables.Clear();
                
                _choosed.OnTrulyChoosed(OnChoosedAnimationCompleted);

            }
            else
            {
                _choosed.PlayOnboardingAnimation();
            }
        }

        private void OnChoosedAnimationCompleted()
        {
            GameEventCaller.Instance.OnChoosedRight();

            Invoke(nameof(PlayStageCompletedAnimations),3);
        }


        public void PlayStageCompletedAnimations()
        {
            GameEventCaller.Instance.OnBeforeStageCompleted();
            _choosed.Hide();
            OnStageCompleted();
        }

        public void OnStageCompleted()
        {
            GameEventCaller.Instance.OnStageCompleted();

            if (!GameManager.Instance.IsGameFinished())
                Invoke(nameof(SetMatchObject), 1.5f);
        }

    }
} 


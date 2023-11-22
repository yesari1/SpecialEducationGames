using System.Collections.Generic;
using UnityEngine;
using Zenject;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    public class MatchingManager : MonoBehaviour
    {
        private Canvas _canvas;
        private PointController _pointController;
        private Fruit _choosedFruit;
        private List<Fruit> _createdFruits;

        [SerializeField] private List<Fruit> _fruits;

        [Inject]
        private void Construct(Canvas canvas,PointController pointController)
        {
            _canvas = canvas;
            _pointController = pointController;
        }

        private void OnEnable()
        {
            GameEventReceiver.OnCenterTextAnimationEndedEvent += OnCenterTextAnimationEnded;
        }

        private void OnDisable()
        {
            GameEventReceiver.OnCenterTextAnimationEndedEvent -= OnCenterTextAnimationEnded;
        }

        private void OnCenterTextAnimationEnded()
        {
            SetFruitsPlace();
        }

        private void Awake()
        {
            _createdFruits = new List<Fruit>();
            _canvas = GameObject.FindGameObjectWithTag("Canvas").GetComponent<Canvas>();
        }

        private void Start()
        {
            SetMatchObject();
        }

        private void SetMatchObject()
        {
            int rnd = Random.Range(0, _fruits.Count);
            _choosedFruit = _fruits[rnd];

            //ShowStartTextAnimation(choosedFruit.name);
        }

        private void SetFruitsPlace()
        {
            List<Fruit> fruits = new List<Fruit>(_fruits);

            Point point = _pointController.GetRandomPoint();

            Fruit fruit = CreateFruit(_choosedFruit, point.RectTransform);

            fruits.Remove(_choosedFruit);

            _choosedFruit = fruit;

            for (int i = 0; i < 2; i++)
            {
                point = _pointController.GetRandomPoint();

                int rndFruit = Random.Range(0, fruits.Count);

                fruit = CreateFruit(fruits[rndFruit], point.RectTransform);
                fruits.Remove(fruits[rndFruit]);
            }
        }

        private Fruit CreateFruit(Fruit fruitPrfb, RectTransform point)
        {
            Fruit fruit = Instantiate(fruitPrfb, _canvas.transform);

            fruit.SetMatchingManager(this);
            fruit.GetComponent<RectTransform>().anchorMax = point.anchorMax;
            fruit.GetComponent<RectTransform>().anchorMin = point.anchorMin;
            fruit.GetComponent<RectTransform>().anchoredPosition = point.anchoredPosition;

            _createdFruits.Add(fruit);

            return fruit;
        }

        public void OnAnswerChoose(Choosable choosable)
        {
            Fruit fruit = (Fruit)choosable;

            if (_choosedFruit.name == fruit.name)
            {
                fruit.OnCorrectAnimationFinished += OnStageCompleted;

                //fruit.PlayCorrectAnimation(scaleUpSpeed, maxScale);

                for (int i = 0; i < _createdFruits.Count; i++)
                {
                    if (_createdFruits[i].name != fruit.name)
                    {
                        Destroy(_createdFruits[i].gameObject);
                    }
                }
                _createdFruits.Clear();
                //ParticleManager.instance.CreateAndPlay(ParticleManager.instance.psStars, canvas.gameObject, Vector3.zero, false);
                //choosedFruit.PlayOnboardingAnimation();
            }
            else
            {
                _choosedFruit.PlayOnboardingAnimation("CorrectFruit");
            }
        }

        public void OnStageCompleted()
        {
            GameEventCaller.Instance.OnStageCompleted();
            ParticleManager.instance.CreateAndPlay(ParticleManager.instance.psCircles, _canvas.gameObject, _choosedFruit.GetComponent<RectTransform>().anchoredPosition, false);
            _choosedFruit.PlayHideAnimation();
            //startText.gameObject.SetActive(false);

            if (!GameManager.Instance.IsGameFinished())
                Invoke("SetMatchObject", 3);

        }

    }
} 


using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace SpecialEducationGames
{
    public class GameManager : MonoBehaviour
    {
        private static GameManager _instance;

        [Header("Stage Settings")]
        [SerializeField] private int _maxStage = 5;

        private EventManager _eventManager;

        private int _currentStage;

        public static GameManager Instance => _instance;

        public static GameEventReceiver GameEventReceiver { get; set; }

        public static GameEventCaller GameEventCaller { get; set; }

        public static int CurrentStage => _instance._currentStage;

        public static int MaxStage => _instance._maxStage; 
        
        public static bool IsGameFinished => _instance._currentStage >= _instance._maxStage;

        private void OnEnable()
        {
            EventManager.Subscribe<OnCorrectOneChoosedEvent>(OnCorrectOneChoosed);
            EventManager.Subscribe<OnWrongOneChoosedEvent>(OnWrongOneChoosed);
            EventManager.Subscribe<OnStageCompletedEvent>(OnStageCompleted);
        }

        private void OnDisable()
        {
            EventManager.Unsubscribe<OnCorrectOneChoosedEvent>(OnCorrectOneChoosed);
            EventManager.Unsubscribe<OnWrongOneChoosedEvent>(OnWrongOneChoosed);
            EventManager.Unsubscribe<OnStageCompletedEvent>(OnStageCompleted);
        }


        private void Awake()
        {
            if (_instance == null) _instance = this;

            InitializeEventSystem();
            _currentStage = 0;

            _eventManager = new EventManager();
        }

        private void OnDestroy()
        {
            _eventManager.Dispose();
            _eventManager = null;
        }


        void Start()
        {
            GAManager.OnLevelStarted();
        }

        private void InitializeEventSystem()
        {
            GameEventReceiver = new GameEventReceiver();
            GameEventCaller = new GameEventCaller(GameEventReceiver);
        }

        public static void Shuffle<T>(IList<T> ts)
        {
            var count = ts.Count;
            var last = count - 1;
            for (var i = 0; i < last; ++i)
            {
                var r = UnityEngine.Random.Range(i, count);
                var tmp = ts[i];
                ts[i] = ts[r];
                ts[r] = tmp;
            }
        }

        public void GameFinished()
        {
            EventManager.Fire<OnGameFinishedEvent>();

            AudioManager.PlayLevelEndCongratsSoundRandomly();

            Invoke(nameof(LoadScene), 4);

            GAManager.OnLevelEnded();
        }

        private void OnStageCompleted(OnStageCompletedEvent onStageCompletedEvent)
        {
            _currentStage++;

            if (_currentStage >= _maxStage)
            {
                GameFinished();
            }
        }

        public void LoadScene()
        {
            SceneManager.LoadScene(0);
        }

        private void OnCorrectOneChoosed(OnCorrectOneChoosedEvent @event)
        {
            GAManager.OnCorrectChoosableSelected();
        }

        private void OnWrongOneChoosed(OnWrongOneChoosedEvent @event)
        {
            GAManager.OnWrongChoosableSelected();
        }
    }
}
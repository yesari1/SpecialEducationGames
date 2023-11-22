using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.SceneManagement;
using Zenject;

namespace SpecialEducationGames
{
    public class GameManager : MonoBehaviour
    {
        private static GameManager _instance;

        private StageController _stageController;

        [Header("Stage Settings")]
        [SerializeField] private int maxStage = 5;
        private int stageCount;

        public static GameManager Instance => _instance;

        public static GameEventReceiver GameEventReceiver { get; set; }

        public static GameEventCaller GameEventCaller { get; set; }

        [Inject]
        private void Construct(StageController stageController)
        {
            _stageController = stageController;
        }

        private void OnEnable()
        {
            //FindObjectOfType<LevelManager>().OnStageCompletedEvent += OnStageCompleted;
        }

        private void Awake()
        {
            if (_instance == null) _instance = this;

            InitializeEventSystem();
            stageCount = 0;
        }

        void Start()
        {
            _stageController.SetStars(maxStage);

        }

        private void InitializeEventSystem()
        {
            GameEventReceiver = new GameEventReceiver();
            GameEventCaller = new GameEventCaller(GameEventReceiver);
        }


        public static void SetAnchors(RectTransform This, Vector2 AnchorMin, Vector2 AnchorMax)
        {
            var OriginalPosition = This.localPosition;
            var OriginalSize = This.sizeDelta;

            This.anchorMin = AnchorMin;
            This.anchorMax = AnchorMax;

            This.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, OriginalSize.x);
            This.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, OriginalSize.y);
            This.localPosition = OriginalPosition;

            This.pivot = AnchorMax;
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
            //print("Game Finished. Show Success UI");

            //StartCoroutine(ParticleManager.instance.CreateAndPlay(ParticleManager.instance.psConfettis, canvas.gameObject, Vector2.zero, true, 3));

            //UIManager.instance.Invoke("ShowFinishText",3);

            //StartCoroutine(CallAfterDelay(7, LoadScene));

            //SceneManager.LoadScene(0);
        }

        public bool IsGameFinished()
        {
            return stageCount >= maxStage;
        }

        private void OnStageCompleted()
        {
            _stageController.FillStar();
            stageCount++;

            if (stageCount >= maxStage)
            {
                GameFinished();
            }
        }

        public static IEnumerator CallAfterDelay(float waitSeconds, Func<int> function)
        {
            yield return new WaitForSeconds(waitSeconds);
            function();
        }

        public int LoadScene()
        {
            SceneManager.LoadScene(0);
            return 1;
        }

    }
}
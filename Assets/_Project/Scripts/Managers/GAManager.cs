using Facebook.Unity;
using GameAnalyticsSDK;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace SpecialEducationGames
{
    public class GAManager : MonoBehaviour
    {
        private static GAManager _instance;

        private void Awake()
        {
            if (_instance == null)
            {
                _instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else
            {
                Destroy(gameObject);
                return;
            }
        }

        private void Start()
        {
            Debug.Log("GA Init");
            GameAnalytics.Initialize();
        }

        public static void OnLevelStarted()
        {
            string levelName = SceneNameFromIndex(SceneManager.GetActiveScene().buildIndex);
            //Debug.Log("levelName: " + levelName);
            GameAnalytics.NewProgressionEvent(GAProgressionStatus.Start, levelName);
            GameAnalytics.StartTimer(levelName);
        }

        public static void OnLevelEnded()
        {
            string levelName = SceneNameFromIndex(SceneManager.GetActiveScene().buildIndex);

            GameAnalytics.NewProgressionEvent(GAProgressionStatus.Complete, levelName);
            GameAnalytics.StopTimer(levelName);
        }

        public static void OnWrongChoosableSelected()
        {
            string levelName = SceneNameFromIndex(SceneManager.GetActiveScene().buildIndex);

            GameAnalytics.NewProgressionEvent(GAProgressionStatus.Start, levelName, "WrongChoose");
        }

        public static void OnCorrectChoosableSelected()
        {
            string levelName = SceneNameFromIndex(SceneManager.GetActiveScene().buildIndex);

            GameAnalytics.NewProgressionEvent(GAProgressionStatus.Start, levelName, "CorrectChoose");
        }

        private static string SceneNameFromIndex(int BuildIndex)
        {
            string path = SceneUtility.GetScenePathByBuildIndex(BuildIndex);
            int slash = path.LastIndexOf('/');
            string name = path.Substring(slash + 1);
            int dot = name.LastIndexOf('.');
            return name.Substring(0, dot);
        }
    }
}

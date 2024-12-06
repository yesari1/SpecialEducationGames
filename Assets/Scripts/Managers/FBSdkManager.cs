using Facebook.Unity;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    public class FBSdkManager : MonoBehaviour
    {
        private static FBSdkManager _instance;

        private void Awake()
        {
            if (_instance == null)
            {
                _instance = this;
                DontDestroyOnLoad(this);
            }
            else
            {
                Destroy(this);
                return;
            }
        }

        private void Start()
        {
            Debug.Log("FB Init");
            FB.Init();
        }
    }
}

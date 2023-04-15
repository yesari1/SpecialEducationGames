using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;
using TMPro;

public class UIManager : MonoBehaviour
{
    public static UIManager instance;
    [SerializeField] private TextMeshProUGUI textFinish;

    private void Awake()
    {
        if (instance == null) instance = this;

    }

    private void Start()
    {
    }

    public void ShowFinishText()
    {
        textFinish.gameObject.SetActive(true);
    }
}

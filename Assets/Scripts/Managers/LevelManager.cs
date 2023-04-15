using System;
using TMPro;
using UnityEngine;

public abstract class LevelManager : MonoBehaviour
{
    public abstract event Action OnStageCompleted;

    [SerializeField] protected TextMeshProUGUI startText;

    [Header("Choosable Animation Settings")]
    [SerializeField] protected float goCenterSpeed = 250;
    [SerializeField] protected float scaleUpSpeed = 5;
    [SerializeField] protected Vector3 maxScale;

    public abstract void OnAnswerChoose(Choosable choosable);


    protected void ShowStartTextAnimation(string text = "")
    {
        startText.gameObject.SetActive(true);
        startText.text = (text != "") ? text : startText.text;
        startText.GetComponent<Animation>().Play();
    }


}

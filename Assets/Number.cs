using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UIElements;

public class Number : Choosable
{
    public override event Action OnCorrectAnimationFinished;

    private TextMeshProUGUI text;

    private bool isChoosableNumber = false;
    private LevelManager levelManager;
    private int num;

    void Awake()
    {
        text = GetComponentInChildren<TextMeshProUGUI>();
    }

    private void OnEnable()
    {
        base.OnEnable();
        rectTransform = GetComponent<RectTransform>();
    }

    public int Num
    {
        get { return num; }
    }

    private void Update()
    {
        if (scaleUp)
        {
            print("gasf");
            rectTransform.localScale = Vector3.Lerp(rectTransform.localScale, maxScale, Time.deltaTime * scaleUpSpeed);

            if (Vector3.Distance(rectTransform.localScale, maxScale) <= 0.1f)
            {
                scaleUp = false;
                OnCorrectAnimationFinished?.Invoke();
            }
        }
    }

    public void SetNumber(int number)
    {
        num = number;
        text.text = num.ToString();
    }

    public void SetHidedNumber(int number)
    {
        num = number;
    }

    public void SetAsChoosable(LevelManager levelManager)
    {
        isChoosableNumber = true;
        this.levelManager = levelManager;
    }


    public override void OnPointerDown(PointerEventData eventData)
    {
        levelManager.OnAnswerChoose(this);
    }

    public override void PlayCorrectAnimation(float scaleUpSpeed, Vector3 maxScale)
    {
        this.maxScale = maxScale;
        this.scaleUpSpeed = scaleUpSpeed;
        scaleUp = true;
    }

}



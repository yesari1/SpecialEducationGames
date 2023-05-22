using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UIElements;

public class Number : Choosable,IAnimationControllable
{
    public override event Action OnCorrectAnimationFinished;

    private TextMeshProUGUI text;

    private bool isChoosableNumber = false;
    private LevelManager levelManager;
    private int num;
    private bool _isCorrect = false;

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

    public string Text
    {
        get
        {
            return text.text;
        }
    }

    public bool IsCorrect
    {
        get
        {
            return _isCorrect;
        }
    }

    private void Update()
    {
        if (scaleUp)
        {
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

    public void SetNumber(string str)
    {
        text.text = str.ToString();
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

    public void SetCorrect()
    {
        _isCorrect = true;
    }

    public override void OnPointerDown(PointerEventData eventData)
    {
        levelManager.OnAnswerChoose(this);
    }

    public void PlayCorrectAnimation(float scaleUpSpeed, Vector3 maxScale)
    {
        this.maxScale = maxScale;
        this.scaleUpSpeed = scaleUpSpeed;
        scaleUp = true;
    }

}



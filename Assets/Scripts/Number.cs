using SpecialEducationGames;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UIElements;
using Zenject;

public class Number : Choosable,IAnimationControllable
{
    private TextMeshProUGUI text;

    private bool isChoosableNumber = false;
    private LevelManager levelManager;
    private int num;
    private bool _isCorrect = false;

    void Awake()
    {
        text = GetComponentInChildren<TextMeshProUGUI>();
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
        //if (_scaleUp)
        //{
        //    _rectTransform.localScale = Vector3.Lerp(_rectTransform.localScale, _maxScale, Time.deltaTime * _scaleUpSpeed);

        //    if (Vector3.Distance(_rectTransform.localScale, _maxScale) <= 0.1f)
        //    {
        //        _scaleUp = false;
        //        GameEventCaller.Instance.OnCorrectAnimationEnded();
        //    }
        //}
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

    //public override void OnPointerDown(PointerEventData eventData)
    //{
    //    levelManager.OnAnswerChoose(this);
    //}

    public void PlayCorrectAnimation(float scaleUpSpeed, Vector3 maxScale)
    {
        this._maxScale = maxScale;
        this._scaleUpSpeed = scaleUpSpeed;
        _scaleUp = true;
    }

    public class Factory : PlaceholderFactory<Choosable>
    {
    }

}



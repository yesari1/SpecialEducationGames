using SpecialEducationGames;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UIElements;

public class Number : MonoBehaviour,IFactoryObject<Number>
{
    private TextMeshProUGUI _text;

    private bool isChoosableNumber = false;
    private int num;
    private bool _isCorrect = false;
    private FactoryBase<Number> _factory;

    protected void Awake()
    {
        _text = GetComponentInChildren<TextMeshProUGUI>();
    }

    public int Num
    {
        get { return num; }
    }

    public string Text
    {
        get
        {
            return _text.text;
        }
    }

    public bool IsCorrect
    {
        get
        {
            return _isCorrect;
        }
    }

    public void SetNumber(int number)
    {
        num = number;
        _text.text = num.ToString();
    }

    public void SetNumber(string str)
    {
        _text.text = str.ToString();
    }

    public void SetHidedNumber(int number)
    {
        num = number;
    }

    public void SetAsChoosable()
    {
        isChoosableNumber = true;
    }

    public void SetCorrect()
    {
        _isCorrect = true;
    }

    public void OnSpawn(FactoryBase<Number> factory)
    {
        _factory = factory;
    }

    public void Dispose()
    {
        _factory.Push(this);
    }

    [Serializable]
    public struct NumberSettings
    {
        public Color BackgroundColor;
        public Color TextColor;
    }

}



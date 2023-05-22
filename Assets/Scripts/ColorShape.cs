using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

[Serializable]
public class ColorShape : Choosable,IAnimationControllable
{
    public override event Action OnCorrectAnimationFinished;

    private ColorProperties colorProperty;
    [SerializeField] private GameObject shape;
    [SerializeField] private GameObject shapeInside;

    private LevelManager levelManager;
    private bool _isCorrect = false;

    private void OnEnable()
    {
        base.OnEnable();
        rectTransform = GetComponent<RectTransform>();
    }

    public bool IsCorrect
    {
        get { return _isCorrect; }
    }

    public ColorProperties ColorProperty
    {
        get
        {
            return colorProperty;
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

    public void SetColor(LevelManager levelManager,ColorProperties colorProperties)
    {
        shapeInside.GetComponent<Image>().color = colorProperties.color;
        colorProperty = colorProperties;
        this.levelManager = levelManager;
    }

    public void SetAsCorrect()
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

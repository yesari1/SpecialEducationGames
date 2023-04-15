using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

[Serializable]
public class Fruit : Choosable
{
    public override event Action OnCorrectAnimationFinished;

    private MatchingManager matchingManager;

    private bool goToCenter = false;
    private bool hide = false;

    private float goCenterSpeed;

    public string name;


    private void OnEnable()
    {
        base.OnEnable();
        rectTransform = GetComponent<RectTransform>();
    }

    private void Update()
    {
        if (goToCenter)
        {
            rectTransform.anchoredPosition = Vector2.Lerp(rectTransform.anchoredPosition, Vector2.zero, Time.deltaTime * goCenterSpeed);
            if(Vector2.Distance(rectTransform.anchoredPosition,Vector2.zero) <= 2f)
            {
                goToCenter = false;
                scaleUp = true;
            }
        }
        else if(scaleUp)
        {
            rectTransform.localScale = Vector3.Lerp(rectTransform.localScale, maxScale, Time.deltaTime * scaleUpSpeed);

            if (Vector3.Distance(rectTransform.localScale, maxScale) <= 0.1f)
            {
                scaleUp = false;
                OnCorrectAnimationFinished?.Invoke();
            }
        }
    }

    public void SetMatchingManager(MatchingManager matchingManager)
    {
        this.matchingManager = matchingManager;
    }


    public override void OnPointerDown(PointerEventData eventData)
    {
        matchingManager.OnAnswerChoose(this);
    }

    public void PlayCorrectAnimation(float goCenterSpeed,float scaleUpSpeed,Vector3 maxScale)
    {
        GameManager.SetAnchors(rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f));

        //rectTransform.anchorMax = new Vector2(0.5f, 0.5f);
        //rectTransform.anchorMin = new Vector2(0.5f, 0.5f);
        this.maxScale = maxScale;
        this.scaleUpSpeed = scaleUpSpeed;
        this.goCenterSpeed = goCenterSpeed;
        goToCenter = true;

    }

    public void PlayHideAnimation()
    {
        animation.Play("HideFruit");
        Destroy(gameObject,2.5f);
    }

}

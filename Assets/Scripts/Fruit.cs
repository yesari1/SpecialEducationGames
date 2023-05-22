using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

[Serializable]
public class Fruit : Choosable,IAnimationControllable
{
    public override event Action OnCorrectAnimationFinished;

    private MatchingManager matchingManager;

    private bool goToCenter = false;
    private bool hide = false;

    private float goCenterSpeed = 5;

    public string name;

    private float _time = 0;

    private void OnEnable()
    {
        base.OnEnable();
        rectTransform = GetComponent<RectTransform>();
    }

    private void Update()
    {
        if (scaleUp)
        {
            rectTransform.localScale = Vector3.Lerp(rectTransform.localScale, maxScale, _time / scaleUpSpeed);
            //scaleUpSpeed aslýnda zaman ý temsil ediyor
            //Sonradan deðiþtirdik o yüzden kalsýn böyle :)
            _time += Time.deltaTime;
            if (Vector3.Distance(rectTransform.localScale, maxScale) <= 0.01f)
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

    public void PlayCorrectAnimation(float scaleUpSpeed,Vector3 maxScale)
    {
        GameManager.SetAnchors(rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f));

        //rectTransform.anchorMax = new Vector2(0.5f, 0.5f);
        //rectTransform.anchorMin = new Vector2(0.5f, 0.5f);
        this.maxScale = maxScale;
        this.scaleUpSpeed = scaleUpSpeed;
        scaleUp = true;

    }

    public void PlayHideAnimation()
    {
        animation.Play("HideFruit");
        Destroy(gameObject,2.5f);
    }
}

using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

public class Choosable : MonoBehaviour, IPointerDownHandler
{
    public virtual event Action OnCorrectAnimationFinished;

    protected bool scaleUp = false;
    protected float scaleUpSpeed;
    protected Vector3 maxScale;

    protected RectTransform rectTransform;
    protected Animation animation;

    protected virtual void OnEnable()
    {
        animation = GetComponent<Animation>();
    }

    public virtual void OnPointerDown(PointerEventData eventData)
    {

    }


    public virtual void PlayCorrectAnimation(float goCenterSpeed, float scaleUpSpeed, Vector3 maxScale)
    {

    }

    public virtual void PlayCorrectAnimation(float scaleUpSpeed, Vector3 maxScale)
    {

    }

    public void PlayOnboardingAnimation(string animName)
    {
        animation.Play(animName);
    }

}

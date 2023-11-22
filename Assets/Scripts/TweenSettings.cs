using DG.Tweening;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    [Serializable]
    public struct TweenSettings
    {
        public Ease Ease;
        public float Delay;
        public float Duration;
        public float Value;
        public Vector3 Vector;
    }

    public static class TweenSettingsModifier
    {
        public static Tweener DOScale(this Transform tweenTransform,TweenSettings tweenSettings,bool fromZero = false)
        {
            if(fromZero)
                tweenTransform.localScale = Vector3.zero;

            return tweenTransform.DOScale(tweenSettings.Value, tweenSettings.Duration).SetDelayAndEase(tweenSettings);
        }

        public static Tweener DOAnchorPos(this RectTransform tweenTransform, TweenSettings tweenSettings)
        {
            return tweenTransform.DOAnchorPos(tweenSettings.Vector, tweenSettings.Duration).SetDelayAndEase(tweenSettings);
        }

        public static Tweener SetDelayAndEase(this Tweener tweener,TweenSettings tweenSettings)
        {
            return tweener.SetDelay(tweenSettings.Delay).SetEase(tweenSettings.Ease);
        }

    }

}

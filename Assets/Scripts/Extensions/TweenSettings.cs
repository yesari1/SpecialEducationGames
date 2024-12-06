using System;
using System.Collections.Generic;
using DG.Tweening;
using SpecialEducationGames;
using TMPro;
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

    [Serializable]
    public struct SequenceSettings
    {
        public List<TweenSettings> Sequence;

        public int Count => Sequence.Count;
    }

    public static class TweenSettingsExtension
    {
        public static Tweener DOScale(this Transform tweenTransform, TweenSettings tweenSettings, bool fromZero = false,
            bool useStartScale = false)
        {
            var startScale = tweenTransform.localScale;
            var endScale = tweenSettings.Value * Vector3.one;

            if (fromZero)
                tweenTransform.localScale = Vector3.zero;

            if (useStartScale)
                endScale = startScale;


            return tweenTransform.DOScale(endScale, tweenSettings.Duration).SetDelayAndEase(tweenSettings);
        }

        public static Tweener DOAnchorPos(this RectTransform tweenTransform, TweenSettings tweenSettings)
        {
            return tweenTransform.DOAnchorPos(tweenSettings.Vector, tweenSettings.Duration)
                .SetDelayAndEase(tweenSettings);
        }

        public static Tweener DOPunchScale(this Transform tweenTransform, TweenSettings tweenSettings)
        {
            return tweenTransform.DOPunchScale(tweenSettings.Vector, tweenSettings.Duration, 5, 0.5f)
                .SetDelayAndEase(tweenSettings);
        }

        public static Tweener DORotate(this Transform tweenTransform, TweenSettings tweenSettings)
        {
            return tweenTransform.DORotate(tweenSettings.Vector, tweenSettings.Duration, RotateMode.FastBeyond360)
                .SetDelayAndEase(tweenSettings);
        }

        public static Tweener DOFade(this CanvasGroup tweenTransform, TweenSettings tweenSettings)
        {
            return tweenTransform.DOFade(tweenSettings.Value, tweenSettings.Duration).SetDelayAndEase(tweenSettings);
        }

        public static Tweener DOFade(this TextMeshProUGUI tweenTransform, TweenSettings tweenSettings)
        {
            return tweenTransform.DOFade(tweenSettings.Value, tweenSettings.Duration).SetDelayAndEase(tweenSettings);
        }

        public static Tweener SetDelayAndEase(this Tweener tweener, TweenSettings tweenSettings)
        {
            return tweener.SetDelay(tweenSettings.Delay).SetEase(tweenSettings.Ease);
        }

        public static Tweener DOLocalRotate(this Transform tweenTransform, TweenSettings tweenSettings)
        {
            return tweenTransform.DOLocalRotate(tweenSettings.Vector, tweenSettings.Duration, RotateMode.FastBeyond360)
                .SetDelayAndEase(tweenSettings);
        }

        public static Tweener DOLocalMove(this Transform tweenTransform, TweenSettings tweenSettings)
        {
            return tweenTransform.DOLocalMove(tweenSettings.Vector, tweenSettings.Duration)
                .SetDelayAndEase(tweenSettings);
        }

        public static Tweener DOMove(this Transform tweenTransform, TweenSettings tweenSettings)
        {
            return tweenTransform.DOMove(tweenSettings.Vector, tweenSettings.Duration)
                .SetDelayAndEase(tweenSettings);
        }
    }
}
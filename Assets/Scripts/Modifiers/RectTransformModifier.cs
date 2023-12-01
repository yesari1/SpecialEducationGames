using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    public static class RectTransformModifier
    {
        public static RectTransform SetAnchors(this RectTransform rectTransform, AnchorPresets anchor)
        {
            Vector2 anchorMax;
            Vector2 anchorMin;
            GetVectorsFromAnchor(anchor,out anchorMax, out anchorMin);

            Vector3 local = rectTransform.localPosition;
            rectTransform.anchorMax = anchorMax;
            rectTransform.anchorMin = anchorMin;
            rectTransform.localPosition = local;
            return rectTransform;
        }
        public static void GetVectorsFromAnchor(AnchorPresets anchorPresets, out Vector2 anchorMax, out Vector2 anchorMin)
        {
            anchorMax = Vector2.zero;
            anchorMin = Vector2.zero;
            switch (anchorPresets)
            {
                case AnchorPresets.UpperLeft:
                    anchorMax = new Vector2(0, 1);
                    anchorMin = new Vector2(0, 1);
                    break;
                case AnchorPresets.UpperCenter:
                    anchorMax = new Vector2(0.5f, 1);
                    anchorMin = new Vector2(0.5f, 1);
                    break;
                case AnchorPresets.UpperRight:
                    anchorMax = new Vector2(1, 1);
                    anchorMin = new Vector2(1, 1);
                    break;
                case AnchorPresets.MiddleLeft:
                    anchorMax = new Vector2(0, 0.5f);
                    anchorMin = new Vector2(0, 0.5f);
                    break;
                case AnchorPresets.MiddleCenter:
                    anchorMax = new Vector2(0.5f, 0.5f);
                    anchorMin = new Vector2(0.5f, 0.5f);
                    break;
                case AnchorPresets.MiddleRight:
                    anchorMax = new Vector2(1, 0.5f);
                    anchorMin = new Vector2(1, 0.5f);
                    break;
                case AnchorPresets.LowerLeft:
                    anchorMax = new Vector2(0, 0);
                    anchorMin = new Vector2(0, 0);
                    break;
                case AnchorPresets.LowerCenter:
                    anchorMax = new Vector2(0.5f, 0);
                    anchorMin = new Vector2(0.5f, 0);
                    break;
                case AnchorPresets.LowerRight:
                    anchorMax = new Vector2(1, 0);
                    anchorMin = new Vector2(1, 0);
                    break;
                default:
                    break;
            }
        }

    }
}

public enum AnchorPresets
{
    //
    // Summary:
    //     Text is anchored in upper left corner.
    UpperLeft,
    //
    // Summary:
    //     Text is anchored in upper side, centered horizontally.
    UpperCenter,
    //
    // Summary:
    //     Text is anchored in upper right corner.
    UpperRight,
    //
    // Summary:
    //     Text is anchored in left side, centered vertically.
    MiddleLeft,
    //
    // Summary:
    //     Text is centered both horizontally and vertically.
    MiddleCenter,
    //
    // Summary:
    //     Text is anchored in right side, centered vertically.
    MiddleRight,
    //
    // Summary:
    //     Text is anchored in lower left corner.
    LowerLeft,
    //
    // Summary:
    //     Text is anchored in lower side, centered horizontally.
    LowerCenter,
    //
    // Summary:
    //     Text is anchored in lower right corner.
    LowerRight
}
using System;
using TMPro;
using UnityEngine;

public abstract class LevelManager : MonoBehaviour
{
    protected Canvas canvas;

    [Header("Choosable Animation Settings")]
    [SerializeField] protected float goCenterSpeed = 250;
    [SerializeField] protected float scaleUpSpeed = 5;
    [SerializeField] protected Vector3 maxScale;

    public abstract void OnAnswerChoose(Choosable choosable);

}

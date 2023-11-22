using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Point : MonoBehaviour
{

    private void Awake()
    {
        this.RectTransform = GetComponent<RectTransform>();
    }

    public RectTransform RectTransform { get; private set; }

    public bool IsUsing { get; set; }

}

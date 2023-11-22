using SpecialEducationGames;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class StageController : MonoBehaviour
{
    private List<GameObject> listStar;
    private RectTransform rectTransform;
    private int filledStarCount = 0;


    [SerializeField] private GameObject prfbStar;
    [SerializeField] private Sprite starFill;

    [SerializeField] private int spacing;
    [SerializeField] private int padding;

    private void Awake()
    {
        rectTransform = GetComponent<RectTransform>();
        listStar = new List<GameObject>();
    }

    public void SetStars(int starCount)
    {
        rectTransform.sizeDelta = new Vector2((spacing) * (starCount - 1) + (prfbStar.GetComponent<RectTransform>().sizeDelta.x / 2) + padding * 2, 100);
        rectTransform.anchoredPosition = new Vector2((rectTransform.sizeDelta.x) / 2 + 25, 75);

        for (int i = 0; i < starCount; i++)
        {
            GameObject star = Instantiate(prfbStar, transform);
            star.GetComponent<RectTransform>().pivot = new Vector2(0, 0.5f);
            star.GetComponent<RectTransform>().anchoredPosition = new Vector2(padding+ (spacing) * i, 0);
            GameManager.SetAnchors(star.GetComponent<RectTransform>(), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f));
            listStar.Add(star);
        }
    }


    public void FillStar()
    {
        if (listStar.Count < filledStarCount)
            return;

        listStar[filledStarCount].GetComponent<Image>().sprite = starFill;
        listStar[filledStarCount].GetComponent<Animation>().Play();
        filledStarCount++;
    }

}

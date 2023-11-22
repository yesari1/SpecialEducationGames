using SpecialEducationGames;
using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using Random = UnityEngine.Random;

public class NumberManager : LevelManager
{
    private NumberPlacer numberPlacer;
    private Canvas canvas;
    private int choosedNumber;
    private Number hidedNumber;
    private Number hidedChoosableNumber;

    [SerializeField] private List<RectTransform> listPoints;
    [SerializeField] private List<Number> listChoosableNumbers;
    [SerializeField] private Number prfbNumber;

    void Awake()
    {
        numberPlacer = FindObjectOfType<NumberPlacer>();
        canvas = GameObject.FindGameObjectWithTag("Canvas").GetComponent<Canvas>();
    }

    private void Start()
    {
        //ShowStartTextAnimation();

        Invoke("CreateNumbers", 3);
    }

    public void PlaceNumbers()
    {

    }

    private void CreateNumbers()
    {
        hidedNumber = numberPlacer.CreateNumbers();
        choosedNumber = hidedNumber.Num;
        CreateChoosableNumbers();
    }

    private void CreateChoosableNumbers()
    {

        GameManager.Shuffle(listPoints);

        for (int i = 0; i < 3; i++)
        {
            Number number = Instantiate(prfbNumber, canvas.transform);
            listChoosableNumbers.Add(number);

            number.SetNumber(choosedNumber - (i % 3));

            if ((i % 3) == 0)
                hidedChoosableNumber = number;

            number.GetComponent<RectTransform>().anchoredPosition = listPoints[i].anchoredPosition;
            number.SetAsChoosable(this);
        }
    }

    public override void OnAnswerChoose(Choosable choosable)
    {
        Number number = (Number)choosable;

        if(choosedNumber == number.Num)
        {
            number.OnCorrectAnimationFinished += OnStageCompleted;

            for (int i = 0; i < listChoosableNumbers.Count; i++)
            {
                if (listChoosableNumbers[i] != number)
                    Destroy(listChoosableNumbers[i].gameObject);
            }

            number.PlayCorrectAnimation(scaleUpSpeed,maxScale);
        }
        else
        {
            hidedChoosableNumber.PlayOnboardingAnimation("CorrectNumber");
        }
    }


    public void OnStageCompleted()
    {
        numberPlacer.ShowCorrectNumber();

        GameManager.SetAnchors(hidedChoosableNumber.GetComponent<RectTransform>(), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f));

        ParticleManager.instance.CreateAndPlay(ParticleManager.instance.psCircles, canvas.gameObject, hidedChoosableNumber.GetComponent<RectTransform>().anchoredPosition, false);

        numberPlacer.Invoke("ClearAllNumbers", 2.8f);
        Invoke("ClearChoosableNumbers", 2.8f);

        if (!GameManager.Instance.IsGameFinished())
        {
            Invoke("CreateNumbers", 3);
        }
        else
        {
            //startText.gameObject.SetActive(false);
        }

    }

    private void ClearChoosableNumbers()
    {
        for (int i = 0; i < listChoosableNumbers.Count; i++)
        {
            if(listChoosableNumbers[i] != null)
                Destroy(listChoosableNumbers[i].gameObject);
        }

        listChoosableNumbers.Clear();
    }

}

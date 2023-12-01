using SpecialEducationGames;
using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using Zenject;

public class GuessNumberManager : LevelManager
{
    private PointController _pointController;
    private NumberPlacer _numberPlacer;
    private int choosedNumber;
    private Number hidedNumber;
    private Number hidedChoosableNumber;

    [SerializeField] private Number prfbNumber;
    [SerializeField] private List<Number> listChoosableNumbers;

    [Inject]
    private void Construct(PointController pointController,NumberPlacer numberPlacer)
    {
        _pointController = pointController;
        _numberPlacer = numberPlacer;
    }

    void Awake()
    {
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
        hidedNumber = _numberPlacer.CreateNumbers();
        choosedNumber = hidedNumber.Num;
        CreateChoosableNumbers();
    }

    private void CreateChoosableNumbers()
    {
        //for (int i = 0; i < 3; i++)
        //{
        //    Number number = Instantiate(prfbNumber, canvas.transform);
        //    listChoosableNumbers.Add(number);

        //    number.SetNumber(choosedNumber - (i % 3));

        //    if ((i % 3) == 0)
        //        hidedChoosableNumber = number;

        //    number.GetComponent<RectTransform>().anchoredPosition = _pointController.GetRandomPoint().RectTransform.anchoredPosition;
        //    number.SetAsChoosable(this);
        //}
    }

    //public override void OnAnswerChoose(Choosable choosable)
    //{
    //    Number number = (Number)choosable;

    //    if(choosedNumber == number.Num)
    //    {
    //        //number.OnCorrectAnimationFinished += OnStageCompleted;

    //        for (int i = 0; i < listChoosableNumbers.Count; i++)
    //        {
    //            if (listChoosableNumbers[i] != number)
    //                Destroy(listChoosableNumbers[i].gameObject);
    //        }

    //        number.PlayCorrectAnimation(scaleUpSpeed,maxScale);
    //    }
    //    else
    //    {
    //        hidedChoosableNumber.PlayOnboardingAnimation();
    //    }
    //}


    public void OnStageCompleted()
    {
        _numberPlacer.ShowCorrectNumber();

        GameManager.SetAnchors(hidedChoosableNumber.GetComponent<RectTransform>(), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f));

        //ParticleManager.Instance.CreateAndPlay(ParticleManager.Instance.psCircles, hidedChoosableNumber.GetComponent<RectTransform>().anchoredPosition, false);

        _numberPlacer.Invoke("ClearAllNumbers", 2.8f);
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

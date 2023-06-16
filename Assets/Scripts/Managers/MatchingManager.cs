using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.Net;
using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using Random = UnityEngine.Random;

public class MatchingManager : LevelManager
{
    public override event Action OnStageCompletedEvent;


    private Fruit choosedFruit;
    private List<Fruit> listCreatedFruit;

    [SerializeField] private List<Fruit> listFruits;
    [SerializeField] private List<RectTransform> listPoints;

    private void Awake()
    {
        listCreatedFruit = new List<Fruit>();
        canvas = GameObject.FindGameObjectWithTag("Canvas").GetComponent<Canvas>();
    }

    private void Start()
    {
        SetMatchObject();
    }

    private void SetMatchObject()
    {
        int rnd = Random.Range(0, listFruits.Count);
        choosedFruit = listFruits[rnd];

        ShowStartTextAnimation(choosedFruit.name);
        Invoke("SetFruitsPlace", 3);
    }

    private void SetFruitsPlace()
    {
        List<Fruit> fruits = new List<Fruit>(listFruits);
        List<RectTransform> points = new List<RectTransform>(listPoints);

        int choosedFruitPlace = Random.Range(0, points.Count);

        Fruit fruit = CreateFruit(choosedFruit, points[choosedFruitPlace]);

        fruits.Remove(choosedFruit);
        points.RemoveAt(choosedFruitPlace);

        choosedFruit = fruit;

        for (int i = 0; i < 2; i++)
        {
            int rndPoint = Random.Range(0, points.Count);
            int rndFruit = Random.Range(0, fruits.Count);

            fruit = CreateFruit(fruits[rndFruit], points[rndPoint]);
            fruits.Remove(fruits[rndFruit]);
            points.RemoveAt(rndPoint);
        }
    }

    private Fruit CreateFruit(Fruit fruitPrfb,RectTransform point)
    {
        Fruit fruit = Instantiate(fruitPrfb, canvas.transform);

        fruit.SetMatchingManager(this);
        fruit.GetComponent<RectTransform>().anchorMax = point.anchorMax;
        fruit.GetComponent<RectTransform>().anchorMin = point.anchorMin;
        fruit.GetComponent<RectTransform>().anchoredPosition = point.anchoredPosition;

        listCreatedFruit.Add(fruit);

        return fruit;
    }

    public override void OnAnswerChoose(Choosable choosable)
    {
        Fruit fruit = (Fruit) choosable;

        if(choosedFruit.name == fruit.name)
        {
            fruit.OnCorrectAnimationFinished += OnStageCompleted;

            fruit.PlayCorrectAnimation(scaleUpSpeed, maxScale);

            for (int i = 0; i < listCreatedFruit.Count; i++)
            {
                if (listCreatedFruit[i].name != fruit.name)
                {
                    Destroy(listCreatedFruit[i].gameObject);
                }
            }
            listCreatedFruit.Clear();
            //ParticleManager.instance.CreateAndPlay(ParticleManager.instance.psStars, canvas.gameObject, Vector3.zero, false);
            //choosedFruit.PlayOnboardingAnimation();
        }
        else
        {
            choosedFruit.PlayOnboardingAnimation("CorrectFruit");
        }
    }

    public override void OnStageCompleted()
    {
        OnStageCompletedEvent?.Invoke();
        ParticleManager.instance.CreateAndPlay(ParticleManager.instance.psCircles, canvas.gameObject, choosedFruit.GetComponent<RectTransform>().anchoredPosition, false);
        choosedFruit.PlayHideAnimation();
        startText.gameObject.SetActive(false);

        if(!GameManager.instance.IsGameFinished())
            Invoke("SetMatchObject", 3);

    }

}

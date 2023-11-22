using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    public class CompareManager : LevelManager
    {
        [SerializeField] private Number numberPrefab;
        [SerializeField] private Number choosablePrefab;
        [SerializeField] private CanvasPlacer placerQuestion;
        [SerializeField] private CanvasPlacer placerAnswer;

        private Number questionNumber;
        private List<Number> listNumbers;
        private List<Choosable> listChoosables;

        private Number correctObj;

        private int number1;
        private int number2;

        private void Awake()
        {
            listNumbers = new List<Number>();
            listChoosables = new List<Choosable>();
            canvas = GameObject.FindGameObjectWithTag("Canvas").GetComponent<Canvas>();
        }

        void Start()
        {
            //ShowStartTextAnimation("Sayýlarý Karþýlaþtýr");
            Invoke("PlaceNumbersAndQuestionMark", 3);
        }
        public override void OnAnswerChoose(Choosable choosable)
        {
            Number num = (Number)choosable;

            if (num.IsCorrect)
            {
                num.PlayCorrectAnimation(scaleUpSpeed, maxScale);
                num.OnCorrectAnimationFinished += StageCompleted;
            }
            else
            {
                correctObj.PlayOnboardingAnimation("CorrectNumber");
            }
        }

        private void ClearScene()
        {
            for (int i = 0; i < listChoosables.Count; i++)
                Destroy(listChoosables[i].gameObject);

            for (int i = 0; i < listNumbers.Count; i++)
                Destroy(listNumbers[i].gameObject);

            listNumbers.Clear();
            listChoosables.Clear();
        }

        private void PlaceNumbersAndQuestionMark()
        {
            ClearScene();

            string[] strCharacters = new string[3];
            number1 = Random.Range(0, 10);
            number2 = Random.Range(0, 10);
            string questionMark = "?";

            strCharacters[0] = number1.ToString();
            strCharacters[1] = questionMark;
            strCharacters[2] = number2.ToString();

            for (int i = 0; i < strCharacters.Length; i++)
            {
                Number number = Instantiate(numberPrefab);
                number.SetNumber(strCharacters[i]);
                listNumbers.Add(number);
            }

            questionNumber = listNumbers[1].GetComponent<Number>();

            placerQuestion.PlaceObjects(listNumbers);

            Invoke("PlaceAnswers", 1);

        }


        private void PlaceAnswers()
        {
            string[] arrayAnswer = new string[3];
            int correctIndex = 0;

            if (number1 == number2) correctIndex = 0;
            else if (number1 > number2) correctIndex = 2;
            else if (number1 < number2) correctIndex = 1;

            arrayAnswer[0] = "=";
            arrayAnswer[1] = "<";
            arrayAnswer[2] = ">";

            for (int i = 0; i < arrayAnswer.Length; i++)
            {
                Number choosable = Instantiate(choosablePrefab);
                choosable.SetAsChoosable(this);
                choosable.SetNumber(arrayAnswer[i]);

                if (i == correctIndex)
                {
                    correctObj = choosable;
                    choosable.SetCorrect();
                }

                listChoosables.Add(choosable);
            }

            placerAnswer.PlaceObjects(listChoosables);

        }


        private void StageCompleted()
        {
            GameEventCaller.Instance.OnStageCompleted();
            ParticleManager.instance.CreateAndPlay(ParticleManager.instance.psCircles, canvas.gameObject, correctObj.GetComponent<RectTransform>().anchoredPosition + new Vector2(0, -175), false);

            questionNumber.gameObject.SetActive(false);
            questionNumber.SetNumber(correctObj.Text);
            questionNumber.gameObject.SetActive(true);

            for (int i = 0; i < listChoosables.Count; i++)
            {
                if (listChoosables[i] != correctObj)
                    listChoosables[i].gameObject.SetActive(false);
            }


            if (!GameManager.Instance.IsGameFinished())
            {
                Invoke("PlaceNumbersAndQuestionMark", 3);
            }
            else
            {
                Invoke("ClearScene", 2.75f);
                //startText.gameObject.SetActive(false);
            }

        }

        public void OnStageCompleted()
        {

        }
    }
}
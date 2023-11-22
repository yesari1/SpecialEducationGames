using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    public class ColorManager : LevelManager
    {
        public delegate void OnAgentHealthChangedDelegate(string agent, float oldHealth, float newHealth);

        public event OnAgentHealthChangedDelegate OnAgentHealthChanged;

        [SerializeField] private List<ColorProperties> listColorProperties;
        [SerializeField] private List<ColorShape> listColorShapes;
        [SerializeField] private CanvasPlacer placerAnswers;

        private ColorShape selectedColor;
        List<ColorShape> listChoosables = new List<ColorShape>();

        private void Awake()
        {
            canvas = GameObject.FindGameObjectWithTag("Canvas").GetComponent<Canvas>();
        }

        private void Start()
        {
            SetColorQuestionAndAnswer();

        }


        private void SetColorQuestionAndAnswer()
        {
            List<ColorProperties> selectedChoosableColors = new List<ColorProperties>();

            for (int i = 0; i < 3; i++)
            {
                int rndColor = Random.Range(0, listColorProperties.Count);

                while (selectedChoosableColors.Contains(listColorProperties[rndColor]))
                    rndColor = Random.Range(0, listColorProperties.Count);

                ColorProperties colorProperty = listColorProperties[rndColor];

                int rndShape = Random.Range(0, listColorShapes.Count);
                ColorShape colorShape = Instantiate(listColorShapes[rndShape]);
                colorShape.SetColor(this, colorProperty);

                //Ýlk rastgele seçileni doðru olan renk yapýyoruz
                if (i == 0)
                {
                    selectedColor = colorShape;
                    colorShape.SetAsCorrect();
                }

                selectedChoosableColors.Add(colorProperty);
                listChoosables.Add(colorShape);
            }

            //GameManager.Shuffle
            GameManager.Shuffle(listChoosables);

            //SetStartTextColor(selectedColor.ColorProperty.color);
            //ShowStartTextAnimation(selectedColor.ColorProperty.colorName);

            placerAnswers.PlaceObjects(listChoosables, 3);
        }

        public override void OnAnswerChoose(Choosable choosable)
        {
            ColorShape colorShape = (ColorShape)choosable;

            if (colorShape.ColorProperty.color == selectedColor.ColorProperty.color)
            {
                colorShape.PlayCorrectAnimation(scaleUpSpeed, maxScale);
                colorShape.OnCorrectAnimationFinished += OnStageCompleted;

                for (int i = 0; i < listChoosables.Count; i++)
                    if (listChoosables[i] != selectedColor)
                        Destroy(listChoosables[i].gameObject);
            }
            else
            {
                selectedColor.PlayOnboardingAnimation("CorrectShape");
            }
        }

        public void OnStageCompleted()
        {
            GameEventCaller.Instance.OnStageCompleted();

            ParticleManager.instance.CreateAndPlay(ParticleManager.instance.psCircles, canvas.gameObject, selectedColor.GetComponent<RectTransform>().anchoredPosition + Vector2.up * 50, false);
            ClearScene();

            if (!GameManager.Instance.IsGameFinished())
            {
                Invoke("SetColorQuestionAndAnswer", 3);
            }
            else
            {
                //startText.gameObject.SetActive(false);
            }
        }

        private void ClearScene()
        {
            Destroy(selectedColor.gameObject, 3);
            listChoosables.Clear();
        }


    }

    [Serializable]
    public class ColorProperties
    {
        public Color color;
        public string colorName;
    }
}
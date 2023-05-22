using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UI;

public class NumberPlacer : MonoBehaviour
{
    private List<Number> listNumbers;
    private Number hidedNumber;

    [SerializeField] private Number prfbNumber;
    [SerializeField] private int count = 4;
    [SerializeField] private int minNumber = 0;
    [SerializeField] private int maxNumber = 25;

    private float imageWidth;
    [SerializeField] private int spacing;
    [SerializeField] private int padding;
    // Start is called before the first frame update
    void Awake()
    {
        imageWidth = prfbNumber.GetComponent<Image>().preferredWidth * prfbNumber.GetComponent<RectTransform>().localScale.x;
        listNumbers = new List<Number>();
    }

    private void Start()
    {
    }

    void Update()
    {
    }

    public Number CreateNumbers()
    {
        int rndStart = Random.Range(minNumber, maxNumber);
        rndStart = Mathf.Clamp(rndStart, 0, 6);

        float allWidth = imageWidth * count + spacing;

        int place = 0;
        for (int i = rndStart; i < rndStart + count; i++)
        {
            Number number = Instantiate(prfbNumber);
            number.gameObject.SetActive(false);
            number.transform.SetParent(transform, false);
            number.GetComponent<RectTransform>().anchoredPosition = new Vector2(padding + ((allWidth / count) * place) - (allWidth - imageWidth) / 2, 0);
            listNumbers.Add(number);

            if (i != rndStart + count - 1)
            {
                number.SetNumber(i);
            }
            else
            {
                hidedNumber = number;
                hidedNumber.SetHidedNumber(i);
            }

            place++;
        }

        StartCoroutine(ActivateNumbersAfterAWhile());

        return hidedNumber;
    }


    public void ClearAllNumbers()
    {
        Destroy(hidedNumber.gameObject);

        for (int i = 0; i < listNumbers.Count; i++)
        {
            Destroy(listNumbers[i].gameObject);
        }

        listNumbers.Clear();
    }

    public void ShowCorrectNumber()
    {
        hidedNumber.SetNumber(hidedNumber.Num);
        hidedNumber.GetComponent<Animation>().Play();
    }

    private IEnumerator ActivateNumbersAfterAWhile()
    {
        for (int i = 0; i < listNumbers.Count; i++)
        {
            listNumbers[i].gameObject.SetActive(true);

            yield return new WaitForSeconds(0.25f);
        }
    }


}

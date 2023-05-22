using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class CanvasPlacer : MonoBehaviour
{

    [SerializeField] private int spacing;

    private void Awake()
    {
    }

    void Start()
    {
    }

    public void PlaceObjects<T>(List<T> listPlacePrefabs,float waitTime = 0) where T : Choosable
    {
        List<GameObject> listPlacedObjects = new List<GameObject>();
        int place = 0;
        for (int i = 0; i < listPlacePrefabs.Count; i++)
        {
            GameObject placedObject = listPlacePrefabs[i].gameObject;
            placedObject.transform.SetParent(transform, false);
            placedObject.GetComponent<RectTransform>().anchoredPosition = new Vector2((spacing * i) - ((listPlacePrefabs.Count - 1) * spacing) / 2, 0);
            listPlacedObjects.Add(placedObject);
            placedObject.gameObject.SetActive(false);

            place++;
        }

        StartCoroutine(ActivateNumbersAfterAWhile(listPlacedObjects, waitTime));
    }


    private IEnumerator ActivateNumbersAfterAWhile(List<GameObject> listPlacedObjects,float waitTime = 0)
    {
        yield return new WaitForSeconds(waitTime);
        for (int i = 0; i < listPlacedObjects.Count; i++)
        {
            listPlacedObjects[i].gameObject.SetActive(true);

            yield return new WaitForSeconds(0.25f);
        }
    }


}

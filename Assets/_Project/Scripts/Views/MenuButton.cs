using System;
using UnityEngine;
using UnityEngine.UI;

namespace SpecialEducationGames
{
    public class MenuButton : MonoBehaviour
    {
        [SerializeField] private UIView _view;

        private Button _button;

        private void Awake()
        {
            _button = GetComponent<Button>();
        }

        private void OnEnable()
        {
            _button.onClick.AddListener(OnButtonClick);
        }

        private void OnDisable()
        {
            _button.onClick.RemoveListener(OnButtonClick);
        }

        private void OnButtonClick()
        {
            UIManager.Show(_view);
        }
    }
}

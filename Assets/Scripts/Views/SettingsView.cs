using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SpecialEducationGames
{
    public class SettingsView : MonoBehaviour
    {
        [SerializeField] private Button _soundButton;
        [SerializeField] private Sprite _soundOnSprite;
        [SerializeField] private Sprite _soundOffSprite;

        private void Awake()
        {
            _soundButton.onClick.AddListener(OnSoundButtonClicked);
            SetSound();
            SetSoundButtonImage();
        }

        private void SetSound()
        {
            if(!PlayerPrefs.HasKey(AudioManager.SOUND))
                PlayerPrefs.SetFloat(AudioManager.SOUND, 1);

            AudioListener.volume = PlayerPrefs.GetFloat(AudioManager.SOUND, 1);

        }

        private void SetSoundButtonImage()
        {
            if (PlayerPrefs.GetFloat(AudioManager.SOUND) <= 0)
            {
                _soundButton.image.sprite = _soundOffSprite;
            }
            else
            {
                _soundButton.image.sprite = _soundOnSprite;
            }
        }

        private void OnSoundButtonClicked()
        {
            if(PlayerPrefs.GetFloat(AudioManager.SOUND) <= 0)
            {
                PlayerPrefs.SetFloat(AudioManager.SOUND, 1);
            }
            else
            {
                PlayerPrefs.SetFloat(AudioManager.SOUND, 0);
            }

            SetSound();
            SetSoundButtonImage();
        }
    }
}

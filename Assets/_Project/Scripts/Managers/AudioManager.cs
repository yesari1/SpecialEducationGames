using EasyButtons;
using MEC;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Localization;
using UnityEngine.Localization.Settings;
using UnityEngine.SceneManagement;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    public class AudioManager : MonoBehaviour
    {
        public const string SOUND = "Sound";

        private static AudioManager _instance;

        [Header("Ana Sesler")]
        [SerializeField] private List<SoundData> _soundDataList;

        [Header("Baþarý Sesleri")]
        [SerializeField] private List<SoundData> _successSoundDataList;

        [Header("Tebrik Sesleri")]
        [SerializeField] private List<SoundData> _congratsSoundDataList;

        [SerializeField] private float _delay;
        [SerializeField] private float _betweenSoundsDelay;

        private Stack<AudioSource> _audioSources;

        private List<AudioSource> _usingAudioSources;

        void OnEnable()
        {
            // Dil deðiþtiðinde otomatik olarak bu metot tetiklenir
            LocalizationSettings.SelectedLocaleChanged += OnLocaleChanged;
            // Ýlk açýlýþta yükleme yap
            PreloadAll();
        }

        void OnDisable()
        {
            LocalizationSettings.SelectedLocaleChanged -= OnLocaleChanged;
        }

        private void Awake()
        {
            if (_instance == null)
            {
                _instance = this;
                DontDestroyOnLoad(gameObject);
                SceneManager.sceneLoaded += OnSceneLoaded;
            }
            else
            {
                Destroy(gameObject);
                return;
            }

            _audioSources = new Stack<AudioSource>();
            _usingAudioSources = new List<AudioSource>();
        }

        private void OnDestroy()
        {
            SceneManager.sceneLoaded -= OnSceneLoaded;
        }

        void OnLocaleChanged(Locale locale)
        {
            Debug.Log($"Dil {locale.name} olarak deðiþti. Sesler güncelleniyor...");
            PreloadAll();
        }

        void PreloadAll()
        {
            foreach (var data in _soundDataList)
            {
                data.Unload();   // Eski dildeki asseti RAM'den temizle
                data.Preload();  // Yeni aktif dile göre klibi RAM'e çek
            }
            foreach (var data in _successSoundDataList)
            {
                data.Unload();
                data.Preload();
            }

            foreach (var data in _congratsSoundDataList)
            {
                data.Unload();
                data.Preload();
            }
        }


        private void OnSceneLoaded(Scene scene, LoadSceneMode mode)
        {
            StopAllSounds();
        }

        private void StopAllSounds()
        {
            foreach (var src in _usingAudioSources)
            {
                src.Stop();
                PushAudioSource(src);
            }
            _usingAudioSources.Clear();
        }

        private void Update()
        {
            for (int i = _usingAudioSources.Count - 1; i >= 0; i--)
            {
                if (!_usingAudioSources[i].isPlaying)
                {
                    PushAudioSource(_usingAudioSources[i]);
                    _usingAudioSources.RemoveAt(i);
                }
            }
        }

        private AudioSource PopAudioSource()
        {
            if (_audioSources.Count > 0)
            {
                var src = _audioSources.Pop();
                src.gameObject.SetActive(true);
                return src;
            }
            else
            {
                var go = new GameObject("Audio Source", typeof(AudioSource));
                go.transform.SetParent(transform);
                return go.GetComponent<AudioSource>();
            }
        }

        private void PushAudioSource(AudioSource src)
        {
            src.Stop();
            src.gameObject.SetActive(false);
            _audioSources.Push(src);
        }

        private SoundData FindSoundData(EffectType effect, List<SoundData> list)
        {
            return list.Find(s => s.GameSound == effect);
        }

        private AudioSource PlaySound(SoundData soundData, bool loop = false, float volume = 1f)
        {
            if (soundData == null || soundData.LocalizedAudioClip == null)
                return null;

            AudioSource audioSource = PopAudioSource();
            audioSource.clip = soundData.Clip;
            audioSource.loop = loop;
            audioSource.volume = volume;
            audioSource.Play();
            _usingAudioSources.Add(audioSource);
            return audioSource;
        }

        public static void PlaySound(EffectType effect, float delay = 0)
        {
            if (_instance == null) return;
            SoundData soundData = _instance.FindSoundData(effect, _instance._soundDataList);
            if (soundData == null) return;
            if (delay > 0)
                _instance.StartCoroutine(_instance.PlaySoundWithDelay(soundData, delay));
            else
                _instance.PlaySound(soundData);
        }

        private IEnumerator PlaySoundWithDelay(SoundData soundData, float delay)
        {
            yield return new WaitForSeconds(delay);
            PlaySound(soundData);
        }

        public static void PlaySuccessSoundRandomly()
        {
            if (_instance == null || _instance._successSoundDataList.Count == 0) return;
            int rnd = Random.Range(0, _instance._successSoundDataList.Count);
            _instance.StartCoroutine(_instance.PlaySoundWithDelay(_instance._successSoundDataList[rnd], 0.6f));
        }

        public static void PlayCongratsSoundRandomly()
        {
            if (_instance == null || _instance._congratsSoundDataList.Count == 0) return;
            int rnd = Random.Range(0, _instance._congratsSoundDataList.Count);
            _instance.StartCoroutine(_instance.PlaySoundWithDelay(_instance._congratsSoundDataList[rnd], 0.6f));
        }

        public static void PlaySounds(params EffectType[] effects)
        {
            _instance.StartCoroutine(_instance.IEPlaySounds(_instance._delay, effects));
        }

        private IEnumerator IEPlaySounds(float delay, params EffectType[] effects)
        {
            yield return new WaitForSeconds(delay);

            foreach (var effect in effects)
            {
                PlaySound(effect);
                yield return new WaitForSeconds(_betweenSoundsDelay);
            }
    }

        internal static void PlayTryAgainSoundRandomly()
        {
            Debug.Log("HENÜZ EKLENMEDÝ");
        }
    }

    public enum EffectType
    {
        None,
        One,
        Two,
        Three,
        Four,
        Five,
        Six,
        Seven,
        Eight,
        Nine,
        GuessNextNumber,
        TryOneMore,
        CompareNumbers,
        And,
        Greater,
        Equal,
        Less,
        Bear,
        Cat,
        Chicken,
        Cock,
        Cow,
        Dog,
        Frog,
        Giraffe,
        Horse,
        Rabbit,
        Sheep,
        Black,
        Blue,
        Brown,
        Gray,
        Green,
        Pink,
        Purple,
        Red,
        White,
        Yellow,
        Orange,
        Pear,
        Banana,
        Strawberry,
        Cabbage,
        Eggplant,
        Tomato,
        Potato,
        Cherry,
        Grape,
        StartCompareNumbers,
        StartGuessNextNumber
    }

    public enum MusicType
    {
        Background,
    }

    [Serializable]
    public class Sounds
    {
        public List<GameSoundTuple> GameSounds;
        public List<MenuSoundTuple> MenuSounds;
    }

    [Serializable]
    public class GameSoundTuple : SoundTuple
    {
        public EffectType GameSound;
    }

    [Serializable]
    public class MenuSoundTuple : SoundTuple
    {
        public MusicType MenuSound;
    }

    [Serializable]
    public abstract class SoundTuple
    {
        public AudioClip AudioClip;
        public bool IsLoop;
        public float Volume;
    }

}


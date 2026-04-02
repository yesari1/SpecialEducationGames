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

        [Header("All Sounds")]
        [SerializeField] private List<SoundData> _soundDataList;

        [Header("EffectType Sounds")]
        [SerializeField] private List<EffectSoundEntry> _effectSoundEntries;

        [Header("Success Sounds")]
        [SerializeField] private List<SoundData> _successSoundDataList;

        [Header("Congratulations Sounds")]
        [SerializeField] private List<SoundData> _congratsSoundDataList;

        [Header("Try Again Sounds")]
        [SerializeField] private List<SoundData> _tryAgainSoundDataList;

        [SerializeField] private float _delay;
        [SerializeField] private float _betweenSoundsDelay;

        private Stack<AudioSource> _audioSources;
        private List<AudioSource> _usingAudioSources;

        void OnEnable()
        {
            LocalizationSettings.SelectedLocaleChanged += OnLocaleChanged;
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
            HashSet<SoundData> allSounds = new HashSet<SoundData>();

            AddSounds(_soundDataList, allSounds);
            AddSounds(_successSoundDataList, allSounds);
            AddSounds(_congratsSoundDataList, allSounds);

            if (_effectSoundEntries != null)
            {
                for (int i = 0; i < _effectSoundEntries.Count; i++)
                {
                    SoundData soundData = _effectSoundEntries[i]?.SoundData;
                    if (soundData != null)
                    {
                        allSounds.Add(soundData);
                    }
                }
            }

            foreach (SoundData soundData in allSounds)
            {
                soundData.Unload();
                soundData.Preload();
            }
        }

        private static void AddSounds(List<SoundData> sounds, HashSet<SoundData> allSounds)
        {
            if (sounds == null)
                return;

            for (int i = 0; i < sounds.Count; i++)
            {
                if (sounds[i] != null)
                {
                    allSounds.Add(sounds[i]);
                }
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

            var go = new GameObject("Audio Source", typeof(AudioSource));
            go.transform.SetParent(transform);
            return go.GetComponent<AudioSource>();
        }

        private void PushAudioSource(AudioSource src)
        {
            src.Stop();
            src.gameObject.SetActive(false);
            _audioSources.Push(src);
        }

        private SoundData FindSoundData(EffectType effect)
        {
            if (_effectSoundEntries == null)
                return null;

            for (int i = 0; i < _effectSoundEntries.Count; i++)
            {
                EffectSoundEntry entry = _effectSoundEntries[i];
                if (entry != null && entry.EffectType == effect)
                {
                    return entry.SoundData;
                }
            }

            return null;
        }

        private AudioSource PlaySoundInternal(SoundData soundData, bool loop = false, float volume = 1f)
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

        public static SoundData GetSoundData(EffectType effect)
        {
            if (_instance == null || effect == EffectType.None)
                return null;

            return _instance.FindSoundData(effect);
        }

        public static void PlaySound(SoundData soundData, float delay = 0)
        {
            if (_instance == null || soundData == null)
                return;

            if (delay > 0)
                _instance.StartCoroutine(_instance.PlaySoundWithDelay(soundData, delay));
            else
                _instance.PlaySoundInternal(soundData);
        }

        public static void PlaySound(EffectType effect, float delay = 0)
        {
            if (_instance == null)
                return;

            SoundData soundData = GetSoundData(effect);
            if (soundData == null)
                return;

            if (delay > 0)
                _instance.StartCoroutine(_instance.PlaySoundWithDelay(soundData, delay));
            else
                _instance.PlaySoundInternal(soundData);
        }

        private IEnumerator PlaySoundWithDelay(SoundData soundData, float delay)
        {
            yield return new WaitForSeconds(delay);
            PlaySoundInternal(soundData);
        }

        public static void PlaySuccessSoundRandomly()
        {
            if (_instance == null || _instance._successSoundDataList.Count == 0)
                return;

            int rnd = Random.Range(0, _instance._successSoundDataList.Count);
            _instance.StartCoroutine(_instance.PlaySoundWithDelay(_instance._successSoundDataList[rnd], 0.6f));
        }

        public static void PlayCongratsSoundRandomly()
        {
            if (_instance == null || _instance._congratsSoundDataList.Count == 0)
                return;

            int rnd = Random.Range(0, _instance._congratsSoundDataList.Count);
            _instance.StartCoroutine(_instance.PlaySoundWithDelay(_instance._congratsSoundDataList[rnd], 0.6f));
        }

        public static void PlaySounds(params EffectType[] effects)
        {
            if (_instance == null || effects == null || effects.Length == 0)
                return;

            SoundData[] soundDataList = new SoundData[effects.Length];

            for (int i = 0; i < effects.Length; i++)
            {
                soundDataList[i] = GetSoundData(effects[i]);
            }

            _instance.StartCoroutine(_instance.IEPlaySounds(_instance._delay, soundDataList));
        }

        public static void PlaySounds(params SoundData[] sounds)
        {
            if (_instance == null || sounds == null || sounds.Length == 0)
                return;

            _instance.StartCoroutine(_instance.IEPlaySounds(_instance._delay, sounds));
        }

        private IEnumerator IEPlaySounds(float delay, params SoundData[] sounds)
        {
            yield return new WaitForSeconds(delay);

            for (int i = 0; i < sounds.Length; i++)
            {
                if (sounds[i] != null)
                {
                    PlaySoundInternal(sounds[i]);
                }

                if (i < sounds.Length - 1)
                {
                    yield return new WaitForSeconds(_betweenSoundsDelay);
                }
            }
        }

        internal static void PlayTryAgainSoundRandomly()
        {
            if (_instance == null || _instance._tryAgainSoundDataList.Count == 0)
                return;
            int rnd = Random.Range(0, _instance._tryAgainSoundDataList.Count);
            _instance.StartCoroutine(_instance.PlaySoundWithDelay(_instance._tryAgainSoundDataList[rnd], 0f));
        }
    }

    public enum EffectType
    {
        None = 0,
        GuessNextNumber = 10,
        TryOneMore = 11,
        CompareNumbers = 12,
        And = 13,
        Greater = 14,
        Equal = 15,
        Less = 16,
        StartCompareNumbers = 48,
        StartGuessNextNumber = 49
    }

    public enum MusicType
    {
        Background,
    }

    [Serializable]
    public class EffectSoundEntry
    {
        public EffectType EffectType;
        public SoundData SoundData;
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
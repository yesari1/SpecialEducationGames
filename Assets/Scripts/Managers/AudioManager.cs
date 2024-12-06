using EasyButtons;
using MEC;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using Random = UnityEngine.Random;

namespace SpecialEducationGames
{
    public class AudioManager : MonoBehaviour
    {
        private static AudioManager _instance;

        [SerializeField] SoundData _soundData;

        [SerializeField] SoundData _successSoundData;

        [SerializeField] SoundData _congratsSoundData;

        [SerializeField] private float _delay;

        [SerializeField] private float _betweenSoundsDelay;

        private Stack<AudioSource> _audioSources;

        private List<AudioSource> _usingAudioSources;

        private AudioSource _tryAgainAudioSource;

        private AudioSource _loopAudioSource;
        private AudioSource _backgroundMusicAudioSource;
        public const string SOUND = "sound";

        private void OnDestroy()
        {
            SceneManager.sceneLoaded -= OnSceneLoaded;
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

            var list = new List<AudioSource>();

            for (int i = 0; i < 10; i++)
            {
                list.Add(PopAudioSource());
            }

            for (int i = 0; i < list.Count; i++)
            {
                PushAudioSource(list[i]);
            }
        }

        private void OnSceneLoaded(Scene arg0, LoadSceneMode arg1)
        {
            //Debug.Log("Scene LOADED: "+ arg0.buildIndex);
            if (arg0.buildIndex == 0)
            {
                if(_backgroundMusicAudioSource != null && !_backgroundMusicAudioSource.isPlaying)
                    _backgroundMusicAudioSource = PlayWithAudioSource(_soundData.MenuSoundTuples.Find((x)=>x.MenuSound == MenuSound.Background));

                Timing.KillCoroutines();
                StopAllSounds();
            }
            else
            {
                if(_backgroundMusicAudioSource != null)
                    _backgroundMusicAudioSource.Stop();
            }
        }



        private void Start()
        {
            _backgroundMusicAudioSource = PlayWithAudioSource(_soundData.MenuSoundTuples.Find((x)=>x.MenuSound == MenuSound.Background));
        }


        private void StopAllSounds()
        {
            StopAllCoroutines();

            if (_usingAudioSources == null)
                return;

            for (int i = 0; i < _usingAudioSources.Count; i++)
            {
                _usingAudioSources[i].Stop();
                PushAudioSource(_usingAudioSources[i]);
            }
        }

        private void Update()
        {
            for (int i = 0; i < _usingAudioSources.Count; i++)
            {
                if (!_usingAudioSources[i].isPlaying)
                {
                    AudioSource audioSource = _usingAudioSources[i];
                    PushAudioSource(audioSource);
                }
            }
        }

        public static void PlaySound(Enum sound, float delay = 0)
        {
            if (_instance == null)
            {
                Debug.LogError("No AudioManager Instance");
                return;
            }

            if (sound is GameSound)
            {
                if ((GameSound)sound == GameSound.None)
                    return;

                GameSoundTuple tuple = _instance._soundData.GameSoundTuples.Find(t => t.GameSound == (GameSound)sound);
                _instance.StartCoroutine(PlaySoundTimer(delay, tuple));
            }
            else if (sound is MenuSound)
            {
                MenuSoundTuple tuple = _instance._soundData.MenuSoundTuples.Find(t => t.MenuSound == (MenuSound)sound);
                _instance.StartCoroutine(PlaySoundTimer(delay, tuple));
            }
            else
            {
                Debug.LogWarning("Sound Not Found!!");
            }

        }

        private static IEnumerator PlaySoundTimer(float delay, SoundTuple soundTuple)
        {
            yield return new WaitForSeconds(delay);
            PlaySound(soundTuple);
        }

        private static void PlaySound(SoundTuple tuple)
        {
            if (tuple.IsLoop && _instance._loopAudioSource != null)
                PushAudioSource(_instance._loopAudioSource);

            AudioSource audioSource = PopAudioSource();
            audioSource.clip = tuple.AudioClip;
            audioSource.loop = tuple.IsLoop;
            audioSource.volume = tuple.Volume;

            if (tuple.IsLoop) _instance._loopAudioSource = audioSource;

            audioSource.Play();
            _instance._usingAudioSources.Add(audioSource);
        }

        public static void PlaySuccessSoundRandomly()
        {
            Timing.RunCoroutine(IEPlaySuccessSoundRandomly());
        }

        private static IEnumerator<float> IEPlaySuccessSoundRandomly()
        {
            yield return Timing.WaitForSeconds(0.4f);

            if (_instance._tryAgainAudioSource != null)
                _instance._tryAgainAudioSource.Stop();

            PlaySound(_instance._successSoundData.GameSoundTuples[0]);

            yield return Timing.WaitForSeconds(0.4f);

            int rnd = Random.Range(1, _instance._successSoundData.GameSoundTuples.Count);
            PlaySound(_instance._successSoundData.GameSoundTuples[rnd]);
        }

        public static void PlayLevelEndCongratsSoundRandomly()
        {
            Timing.RunCoroutine(IEPlayLevelEndCongratsSoundRandomly());
        }

        private static IEnumerator<float> IEPlayLevelEndCongratsSoundRandomly()
        {
            yield return Timing.WaitForSeconds(0.7f);

            if (_instance._tryAgainAudioSource != null)
                _instance._tryAgainAudioSource.Stop();

            //Success Level
            PlaySound(_instance._congratsSoundData.GameSoundTuples[0]);
            PlaySound(_instance._congratsSoundData.GameSoundTuples[1]);

            int rnd = Random.Range(2, _instance._congratsSoundData.GameSoundTuples.Count);
            PlaySound(_instance._congratsSoundData.GameSoundTuples[rnd]);
        }

        public static void PlayTryAgainSoundRandomly()
        {
            if (_instance._tryAgainAudioSource != null && _instance._tryAgainAudioSource.isPlaying)
                return;

            SoundTuple soundTuple = _instance._soundData.GameSoundTuples.Find((x) => x.GameSound == GameSound.TryOneMore);
            _instance._tryAgainAudioSource = PlayWithAudioSource(soundTuple);
        }

        private static AudioSource PlayWithAudioSource(SoundTuple soundTuple)
        {
            AudioSource audioSource = PopAudioSource();
            audioSource.clip = soundTuple.AudioClip;
            audioSource.volume = soundTuple.Volume;
            audioSource.loop = soundTuple.IsLoop;
            audioSource.Play();

            return audioSource;
        }

        private static AudioSource PopAudioSource()
        {
            if (_instance._audioSources.Count > 0)
            {
                AudioSource audioSource = _instance._audioSources.Pop();
                audioSource.gameObject.SetActive(true);

                return audioSource;
            }
            else
            {
                GameObject audioSourceObject = new GameObject("Audio Source", new Type[] { typeof(AudioSource) });
                audioSourceObject.transform.SetParent(_instance.transform);
                return audioSourceObject.GetComponent<AudioSource>();
            }
        }

        private static void PushAudioSource(AudioSource audioSource)
        {
            audioSource.Stop();
            _instance._usingAudioSources.Remove(audioSource);
            _instance._audioSources.Push(audioSource);
            audioSource.gameObject.SetActive(false);
        }

        public static void PlaySounds(params GameSound[] sounds)
        {
            Timing.RunCoroutine(IEPlaySounds(_instance._delay,sounds));
        }

        private static IEnumerator<float> IEPlaySounds(float delay,params GameSound[] sounds)
        {
            yield return Timing.WaitForSeconds(delay);

            for (int i = 0; i < sounds.Length; i++)
            {
                PlaySound(sounds[i]);

                yield return Timing.WaitForSeconds(_instance._betweenSoundsDelay);
            }
        }


    }

    public enum GameSound
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

    public enum MenuSound
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
        public GameSound GameSound;
    }

    [Serializable]
    public class MenuSoundTuple : SoundTuple
    {
        public MenuSound MenuSound;
    }

    [Serializable]
    public abstract class SoundTuple
    {
        public AudioClip AudioClip;
        public bool IsLoop;
        public float Volume;
    }

}


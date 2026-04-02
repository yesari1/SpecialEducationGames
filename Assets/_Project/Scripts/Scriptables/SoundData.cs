using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.Localization;
using UnityEngine.ResourceManagement.AsyncOperations;

namespace SpecialEducationGames
{
    [CreateAssetMenu(fileName = "SoundData", menuName = "SEG/SoundData")]
    public class SoundData : ScriptableObject
    {
        public LocalizedAudioClip LocalizedAudioClip;

        private AudioClip _cachedClip;
        private AsyncOperationHandle<AudioClip> _handle;

        public void Preload()
        {
            if (_cachedClip != null || LocalizedAudioClip == null)
                return;

            _handle = LocalizedAudioClip.LoadAssetAsync();
            _handle.Completed += op =>
            {
                if (op.Status == AsyncOperationStatus.Succeeded)
                {
                    _cachedClip = op.Result;
                }
            };
        }

        public AudioClip Clip
        {
            get
            {
                if (LocalizedAudioClip == null)
                    return null;

                if (_cachedClip == null)
                {
                    Debug.LogWarning($"{name} için senkron yükleme yapılıyor. Gecikme olabilir!");

                    var handle = LocalizedAudioClip.LoadAssetAsync();
                    _cachedClip = handle.WaitForCompletion();
                }

                return _cachedClip;
            }
        }

        public void Unload()
        {
            if (_handle.IsValid())
            {
                Addressables.Release(_handle);
                _cachedClip = null;
            }
        }
    }
}
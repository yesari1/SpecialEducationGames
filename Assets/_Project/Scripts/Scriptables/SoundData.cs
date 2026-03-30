using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.Localization;
using UnityEngine.ResourceManagement.AsyncOperations;

namespace SpecialEducationGames
{
    [CreateAssetMenu(fileName = "SoundData", menuName = "SEG/SoundData")]
    public class SoundData : ScriptableObject
    {
        public EffectType GameSound;
        public LocalizedAudioClip LocalizedAudioClip;

        // Bellekte tutacağımız ham klip
        private AudioClip _cachedClip;
        private AsyncOperationHandle<AudioClip> _handle;

        // 1. Sahne başında veya Manager üzerinden bu metodu çağır
        public void Preload()
        {
            if (_cachedClip != null) return; // Zaten yüklüyse tekrar yükleme

            _handle = LocalizedAudioClip.LoadAssetAsync();
            _handle.Completed += (op) =>
            {
                if (op.Status == AsyncOperationStatus.Succeeded)
                {
                    _cachedClip = op.Result;
                }
            };
        }

        // 2. Sesi çalmak istediğinde bu mülkü (property) kullan
        public AudioClip Clip
        {
            get
            {
                if (_cachedClip == null)
                {
                    Debug.LogWarning($"{GameSound} için senkron yükleme yapılıyor. Gecikme olabilir!");

                    // Handle üzerinden senkron beklemeyi tetikliyoruz
                    var handle = LocalizedAudioClip.LoadAssetAsync();
                    _cachedClip = handle.WaitForCompletion();
                }
                return _cachedClip;
            }
        }

        // 3. Bellek yönetimi için (Opsiyonel)
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
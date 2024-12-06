using System;
using System.Collections.Generic;
using System.Diagnostics.Tracing;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;

namespace SpecialEducationGames
{

    public abstract class EventManagerBase<T> : IDisposable
    {
        private static EventManagerBase<T> _instance;

        private Dictionary<Type, IList<object>> _eventSubscribers = new Dictionary<Type, IList<object>>();

        public EventManagerBase()
        {
            //Debug.Log("Create Event Dispatcher");

            if (_instance == null)
                _instance = this;
            else
                Debug.LogError("Event Dispatcher Instance Error");

            _eventSubscribers = new Dictionary<Type, IList<object>>();
            RegisterEventStructs();
        }

        //~EventManagerBase() => Debug.Log($"The {ToString()} finalizer is executing.");



        // Reflection ile event struct'larını bul ve kaydet
        private static void RegisterEventStructs()
        {
            //
            //
            //Event sistemi şimdilik Reflection ile yapılıyor. Eventler çoğaldığında manual Declare yöntemi eklemek gerekebilir. Optimizasyon farkına bakarız
            //
            //

            var eventTypes = Assembly.GetExecutingAssembly()
                .GetTypes()
                .Where(t => t.IsValueType && !t.IsEnum && !t.IsPrimitive && t.Name.EndsWith("Event"));

            foreach (var eventType in eventTypes)
            {
                if (!_instance._eventSubscribers.ContainsKey(eventType))
                {
                    _instance._eventSubscribers[eventType] = new List<object>();
                }
            }

            //Debug.Log("Registered Event Types:");
            //foreach (var eventType in _instance._eventSubscribers)
            //{
            //    Debug.Log(eventType.Key.Name);
            //}
        }

        public static void Subscribe<E>(Action<E> callback) where E : struct
        {
            Type eventType = typeof(E);

            //Debug.Log("_instance: "+ _instance);

            if (!_instance._eventSubscribers.ContainsKey(eventType))
            {
                _instance._eventSubscribers[eventType] = new List<object>();
            }

            // Delegate'i nesne olarak saklıyoruz
            _instance._eventSubscribers[eventType].Add(callback);
        }

        public static void Unsubscribe<E>(Action<E> callback) where E : struct
        {
            if (_instance == null)
            {
                Debug.LogWarning("EventManager instance is null. Cannot unsubscribe.");
                return;
            }

            Type eventType = typeof(E);

            if (_instance._eventSubscribers.ContainsKey(eventType))
            {
                // Kayıtlı delegate'i bul ve kaldır
                _instance._eventSubscribers[eventType].Remove(callback);
                //Debug.Log($"Unsubscribed from {eventType.Name}");
            }
            else
            {
                Debug.LogError($"No subscribers found for event {eventType.Name}");
            }
        }

        public static void Fire<E>(E gameEvent = default) where E : struct
        {
            Type eventType = typeof(E);

            if (_instance._eventSubscribers.ContainsKey(eventType))
            {
                foreach (var subscriber in _instance._eventSubscribers[eventType])
                {
                    // Type casting yaparak delegate'i çağırıyoruz
                    ((Action<E>)subscriber)(gameEvent);
                }
            }
        }

        public void Dispose()
        {
            // Tüm eventlerden çıkış yap
            foreach (var key in _eventSubscribers.Keys.ToList())
            {
                _eventSubscribers[key].Clear();
            }

            _eventSubscribers.Clear();
            _eventSubscribers = null;
            _instance = null;
        }
    }
}

using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SpecialEducationGames
{
    public abstract class FactoryBase<T> : MonoBehaviour where T : MonoBehaviour, IFactoryObject<T>
    {
        [SerializeField] private T _prefab;

        public event Action<T> onObjectCreatedEvent;

        public event Action<T> onObjectPooledEvent;


        private Stack<T> _stack;

        private void Awake()
        {
            _stack = new Stack<T>();
        }

        public virtual T Create(Vector2 pos = default, Quaternion quaternion = default, Transform parent = null)
        {
            T marble = Pop(pos, quaternion, parent);

            return marble;
        }

        private T Pop(Vector2 pos = default, Quaternion quaternion = default, Transform parent = null)
        {
            T obj;

            if (_stack != null && _stack.Count > 0)
            {
                obj = _stack.Pop();
                obj.transform.position = pos;
                obj.transform.rotation = quaternion;
                obj.transform.localScale = _prefab.transform.localScale;
                obj.transform.SetParent(parent);
            }
            else
            {
                obj = Instantiate(_prefab, pos, quaternion, parent) as T;
            }
            obj.OnSpawn(this);

            obj.gameObject.SetActive(true);
            onObjectCreatedEvent?.Invoke(obj);

            return obj;
        }

        public void Push(T obj)
        {
            obj.gameObject.SetActive(false);
            _stack.Push(obj);
            onObjectPooledEvent?.Invoke(obj);
        }

    }

    public interface IFactoryObject<T> where T : MonoBehaviour, IFactoryObject<T>
    {
        public void OnSpawn(FactoryBase<T> factory);

        public void Dispose();

    }

}
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

namespace SpecialEducationGames
{
    public abstract class UIManagerBase<T> : MonoBehaviour where T : UIManagerBase<T>
    {
        protected static T _instance;

        [SerializeField] private UIView _startingView;

        [SerializeField] protected UIView[] _views;

        private UIView _currentView;

        protected virtual void Awake()
        {
            _instance = GetComponent<T>();

            for (var i = 0; i < _views.Length; i++)
            {
                if (!_views[i].isFixed)
                    _views[i].HideImmediately();

                _views[i].Initialize();
            }

            if (_startingView != null)
                Show(_startingView);
        }

        public static UIView Show(UIView view,bool isFixed = false)
        {
            if (_instance._currentView != null)
            {
                if (!isFixed)
                    _instance._currentView.Hide();
            }

            view.Show();

            if (!isFixed)
                _instance._currentView = view;

            return view;
        }


        public static T Show<T>(bool isFixed = false) where T : UIView
        {
            for (var i = 0; i < _instance._views.Length; i++)
                if (_instance._views[i] is T)
                {
                    if (_instance._currentView != null)
                    {
                        if (!isFixed)
                            _instance._currentView.Hide();
                    }

                    _instance._views[i].Show();

                    if (!isFixed)
                        _instance._currentView = _instance._views[i];

                    return _instance._views[i] as T;
                }

            return null;
        }

        public static T GetView<T>() where T : UIView
        {
            for (var i = 0; i < _instance._views.Length; i++)
                if (_instance._views[i].GetType() == typeof(T))
                    return (T)_instance._views[i];
            return null;
        }

        private static void Show(UIView view)
        {
            if (_instance._currentView != null)
            {
                _instance._currentView.Hide();
            }

            view.Show();

            _instance._currentView = view;
        }

    }
}
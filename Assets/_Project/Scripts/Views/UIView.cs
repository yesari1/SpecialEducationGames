using System;
using UnityEngine;

namespace SpecialEducationGames
{
    public abstract class UIView<TPresenter> : UIView where TPresenter : class, IPresenterView, new()
    {
        protected TPresenter Presenter { get; set; }

        public override void Initialize()
        {
            Presenter = new TPresenter();
            InitializeView();
        }

        public abstract void InitializeView();

        protected virtual void OnDestroy()
        {
            if (Presenter != null)
            {
                Presenter.Dispose();
                Presenter = default;
            }
        }
    }

    public abstract class UIView : MonoBehaviour
    {
        public bool isFixed;
        public bool IsActive { get; protected set; }
        public abstract void Initialize();

        public virtual void Show()
        {
            gameObject.SetActive(true);
            IsActive = true;
        }

        public virtual void Hide()
        {
            gameObject.SetActive(false);
            IsActive = false;
        }

        public virtual bool Toggle()
        {
            if (IsActive)
                Hide();
            else
                Show();

            return IsActive;
        }

        public void HideImmediately()
        {
            gameObject.SetActive(false);
            IsActive = false;
        }
    }
}
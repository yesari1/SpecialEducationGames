using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;

namespace SpecialEducationGames
{
    public abstract class UIView<TPresenter> : UIView where TPresenter : IPresenterView, new()
    {
        protected TPresenter Presenter { get; set; }

        public override void Initialize()
        {
            Presenter = new TPresenter();
            InitializeView();
        }

        public abstract void InitializeView();

        public void OnDestroy()
        {
            Presenter = default(TPresenter);
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

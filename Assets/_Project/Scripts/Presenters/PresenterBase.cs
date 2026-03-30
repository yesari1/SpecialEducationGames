using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Unity.VisualScripting;
using UnityEngine;

namespace SpecialEducationGames
{
    public abstract class PresenterBase<TView> : IPresenterView where TView : UIView
    {
        protected TView View { get; set; }

        public PresenterBase()
        {
            View = UIManager.GetView<TView>();
            InitializePresenter();
        }

        public abstract void InitializePresenter();

        public abstract void Dispose();

    }

    /// <summary>
    ///     <para>
    ///         Just a placeholder for <seealso cref="PresenterBase{TView}">PresenterBase{TView}</seealso>
    ///     </para>
    /// </summary>
    public interface IPresenterView : IDisposable
    {
    }
}

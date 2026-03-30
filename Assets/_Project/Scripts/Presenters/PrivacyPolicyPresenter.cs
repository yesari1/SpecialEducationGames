using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;

namespace SpecialEducationGames
{
    public class PrivacyPolicyPresenter : PresenterBase<PrivacyPolicyView>
    {
        public const string POLICY = "Policy";

        public override void InitializePresenter()
        {
            CheckForPrivacyView();
        }

        private void CheckForPrivacyView()
        {
            if(!PlayerPrefs.HasKey(POLICY))
            {
                PlayerPrefs.SetInt(POLICY, 1);
                View.Show();
            }
        }

        public override void Dispose()
        {
        }

        
    }
}

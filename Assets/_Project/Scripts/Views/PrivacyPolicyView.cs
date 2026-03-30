using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SpecialEducationGames
{
    public class PrivacyPolicyView : UIView<PrivacyPolicyPresenter>
    {
        [SerializeField] private Button _privacyPolicyButton;

        [SerializeField] private Button _termsButton;

        [SerializeField] private Button _okButton;

        public override void InitializeView()
        {
            _privacyPolicyButton.onClick.AddListener(OnPrivacyPolicyButtonClicked);
            _termsButton.onClick.AddListener(OnTermsButtonClicked);
            _okButton.onClick.AddListener(OnOkButtonClicked);
        }
        private void OnOkButtonClicked()
        {
            Hide();
        }

        private void OnTermsButtonClicked()
        {
            Application.OpenURL("https://www.freeprivacypolicy.com/live/94d41ced-f68e-47d4-932d-3773be978894");
        }

        private void OnPrivacyPolicyButtonClicked()
        {
            Application.OpenURL("https://doc-hosting.flycricket.io/ozel-egitim-oyunlari-privacy-policy/56c86e4b-0750-4c65-b488-0f40dd6aedcf/privacy");
        }

    }
}

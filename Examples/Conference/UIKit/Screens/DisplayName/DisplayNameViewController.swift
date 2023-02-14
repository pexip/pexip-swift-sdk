//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit

final class DisplayNameViewController: UIViewController {
    @UserDefaultsBacked(key: "displayName")
    private var displayName = ""

    private var isValid: Bool {
        !displayName.isEmpty
    }

    // MARK: - Subviews

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome"
        label.textColor = .label
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title1)
        return label
    }()

    private lazy var textField: UITextField = {
        let textField = LargeTextField()
        textField.placeholder = "Type your name here"
        textField.returnKeyType = .next
        textField.addTarget(
            self,
            action: #selector(onTextFieldChange),
            for: .editingChanged
        )
        return textField
    }()

    private lazy var nextButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.buttonSize = .large
        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.setTitle("Next", for: .normal)
        button.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        return button
    }()

    private lazy var containerView = FormContainerView(
        arrangedSubviews: [
            titleLabel,
            textField,
            nextButton
        ]
    )

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(containerView)
        containerView.fillInSuperview()
        hideKeyboardWhenTappedAround()
        updateNextButton()
    }

    // MARK: - Actions

    @objc
    private func onTextFieldChange() {
        displayName = textField.text ?? ""
        updateNextButton()
    }

    @objc
    private func onNext() {}

    // MARK: - Private

    private func updateNextButton() {
        nextButton.isEnabled = isValid
    }
}

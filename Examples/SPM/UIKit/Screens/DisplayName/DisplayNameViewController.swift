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

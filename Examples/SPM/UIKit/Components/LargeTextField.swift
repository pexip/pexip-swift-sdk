import UIKit

final class LargeTextField: UITextField {
    var textPadding = UIEdgeInsets(
        top: 15,
        left: 20,
        bottom: 15,
        right: 20
    )

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: - Overrides

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    // MARK: - Private

    private func setup() {
        backgroundColor = .tertiarySystemFill
        textColor = .label
        autocorrectionType = .no
        textAlignment = .center
        layer.cornerRadius = 10
    }
}

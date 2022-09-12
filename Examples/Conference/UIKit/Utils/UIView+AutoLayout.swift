import UIKit

extension UIView {
    func fillInSuperview(insets: UIEdgeInsets = .zero) {
        guard let superview = self.superview else {
            return
        }

        translatesAutoresizingMaskIntoConstraints = false

        var constraints = [NSLayoutConstraint]()
        constraints.append(
            topAnchor.constraint(
                equalTo: superview.topAnchor,
                constant: insets.top
            )
        )
        constraints.append(
            leadingAnchor.constraint(
                equalTo: superview.leadingAnchor,
                constant: insets.left
            )
        )
        constraints.append(
            bottomAnchor.constraint(
                equalTo: superview.keyboardLayoutGuide.topAnchor,
                constant: insets.bottom
            )
        )
        constraints.append(
            trailingAnchor.constraint(
                equalTo: superview.trailingAnchor,
                constant: insets.right
            )
        )

        NSLayoutConstraint.activate(constraints)
    }
}

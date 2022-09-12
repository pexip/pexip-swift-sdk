import UIKit

final class FormContainerView: UIView {
    private let arrangedSubviews: [UIView]

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 20
        return stackView
    }()

    // MARK: - Init

    required init(arrangedSubviews: [UIView]) {
        self.arrangedSubviews = arrangedSubviews
        super.init(frame: .zero)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setup() {
        let scrollView = UIScrollView()
        scrollView.addSubview(stackView)
        addSubview(scrollView)
        scrollView.fillInSuperview()

        var constraints: [NSLayoutConstraint] = [
            scrollView.contentLayoutGuide.heightAnchor.constraint(
                greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor
            ),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.centerYAnchor
            ),
            stackView.topAnchor.constraint(
                greaterThanOrEqualTo: scrollView.contentLayoutGuide.topAnchor
            ),
            stackView.bottomAnchor.constraint(
                lessThanOrEqualTo: scrollView.contentLayoutGuide.bottomAnchor
            )
        ]

        let stackViewWidth1 = stackView.widthAnchor
            .constraint(lessThanOrEqualToConstant: 400)
        stackViewWidth1.priority = .required
        constraints.append(stackViewWidth1)

        let stackViewWidth2 = stackView.widthAnchor
            .constraint(equalTo: widthAnchor, constant: -50)
        stackViewWidth2.priority = .defaultHigh
        constraints.append(stackViewWidth2)

        for subview in arrangedSubviews {
            subview.translatesAutoresizingMaskIntoConstraints = false
            constraints.append(contentsOf: [
                subview.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                subview.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
            ])
        }

        NSLayoutConstraint.activate(constraints)
    }
}

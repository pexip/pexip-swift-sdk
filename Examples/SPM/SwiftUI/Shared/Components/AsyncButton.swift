import SwiftUI

struct AsyncButton<Label: View>: View {
    var action: () async -> Void
    @ViewBuilder var label: () -> Label

    @State private var isDisabled = false
    @State private var showProgressView = false

    var body: some View {
        Button(
            action: {
                isDisabled = true
                showProgressView = true
                Task {
                    let progressTask = Task {
                        try await Task.sleep(nanoseconds: 150_000_000)
                        showProgressView = true
                    }
                    await action()
                    progressTask.cancel()

                    isDisabled = false
                    showProgressView = false
                }
            },
            label: {
                ZStack {
                    label().opacity(showProgressView ? 0 : 1)

                    if showProgressView {
                        ProgressView()
                            .frame(width: 5, height: 5)
                    }
                }
            }
        )
        .disabled(isDisabled)
    }
}

extension AsyncButton where Label == Text {
    init(_ label: String, action: @escaping () async -> Void) {
        self.init(action: action) {
            Text(label)
        }
    }
}

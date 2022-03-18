enum CallKind: Hashable {
    case call(presentationInMix: Bool)
    case presentationReceiver
    case presentationSender

    var isPresentation: Bool {
        self == .presentationReceiver || self == .presentationSender
    }
}

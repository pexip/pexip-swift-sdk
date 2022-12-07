import Combine

public final class SecureCheckCode: ObservableObject {
    public static let invalidValue = "INVALID"

    @Published public internal(set) var value = SecureCheckCode.invalidValue
}

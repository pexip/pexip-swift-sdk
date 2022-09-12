import Foundation

struct Utils {
    private init() {}

    static func abbreviation(forName name: String) -> String {
        let components = name.components(separatedBy: " ")
        let firstName = components.first?.first.map(String.init)
        let lastName = components.last?.last.map(String.init)
        return (firstName ?? "") + (lastName ?? "")
    }
}

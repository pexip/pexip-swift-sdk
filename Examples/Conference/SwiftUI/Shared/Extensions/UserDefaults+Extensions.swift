import Foundation

extension UserDefaults {
    enum StringKey: String {
        case displayName
        case deviceAlias
        case conferenceAlias
    }

    subscript(string key: StringKey) -> String? {
        get { string(forKey: key.rawValue) }
        set { setValue(newValue, forKey: key.rawValue) }
    }
}

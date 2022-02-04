import Foundation

final class EventStreamParser {
    var bufferString: String? { String(data: buffer, encoding: .utf8) }

    private var buffer = Data()
    private let delimeters = Delimiter.stringValues.compactMap {
        "\($0)\($0)".data(using: .utf8)
    }

    // MARK: - Internal methods

    func events(from data: Data) -> [MessageEvent] {
        buffer.append(data)

        var events = [String]()
        var searchRange = buffer.startIndex..<buffer.endIndex

        while let delimiterRange = buffer.delimiterRange(
            in: searchRange,
            possibleDelimeters: delimeters
        ) {
            let eventRange = searchRange.startIndex..<delimiterRange.endIndex
            let eventData = buffer.subdata(in: eventRange)

            if let eventString = String(bytes: eventData, encoding: .utf8) {
                events.append(eventString)
            }

            searchRange = delimiterRange.endIndex..<buffer.endIndex
        }

        buffer.removeSubrange(buffer.startIndex..<searchRange.startIndex)

        return events.compactMap(EventStreamParser.messageEvent(from:))
    }

    func clear() {
        buffer = Data()
    }

    static func messageEvent(from string: String) -> MessageEvent? {
        guard !string.hasPrefix(":") else {
            return nil
        }

        var event = [Field.Key: String?]()
        let fields = string
            .components(separatedBy: .newlines)
            .compactMap(field(from:))

        for field in fields {
            if let value = field.value, let currentValue = event[field.key] ?? nil {
                event[field.key] = "\(currentValue)\n\(value)"
            } else if let value = field.value {
                event[field.key] = value
            }
        }

        return MessageEvent(
            id: event[.id] ?? nil,
            name: event[.event] ?? nil,
            data: event[.data] ?? nil,
            retry: event[.retry] ?? nil
        )
    }

    // MARK: - Private methods

    private static func field(from string: String) -> Field? {
        let scanner = Scanner(string: string)
        let keyString = scanner.scanUpToString(":")

        guard let key = keyString.flatMap(Field.Key.init(rawValue:)) else {
            return nil
        }

        _ = scanner.scanString(":")

        var value = key != .event ? "" : nil

        for newline in Delimiter.stringValues {
            if let scanResult = scanner.scanUpToString(newline) {
                value = scanResult
                break
            }
        }

        return Field(key: key, value: value)
    }
}

// MARK: - Private types

private enum Delimiter: String, CaseIterable {
    case carriageReturn = "\r"
    case lineFeed = "\n"
    case pair  = "\r\n"

    static let stringValues = allCases.map(\.rawValue)
}

private struct Field {
    enum Key: String {
        case id
        case event
        case data
        case retry
    }

    let key: Key
    let value: String?
}

// MARK: - Private extensions

private extension Data {
    func delimiterRange(
        in range: Range<Data.Index>,
        possibleDelimeters: [Data]
    ) -> Range<Data.Index>? {
        for delimiter in possibleDelimeters {
            if let foundRange = self.range(of: delimiter, in: range) {
                return foundRange
            }
        }

        return nil
    }
}

import Foundation

protocol DNSRecord {
    static var serviceType: Int { get }
    init(data: Data) throws
}

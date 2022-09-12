/// ``MediaConnectionFactory`` provides factory methods to create media connection.
public protocol MediaConnectionFactory {
    /**
     Create a new instance of ``MediaConnection`` type.
     - Parameters:
        - config: media connection config
     - Returns: A new instance of ``MediaConnection``
     */
    func createMediaConnection(config: MediaConnectionConfig) -> MediaConnection
}

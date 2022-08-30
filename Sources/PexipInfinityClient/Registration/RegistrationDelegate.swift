/// The object that acts as the delegate of the registration.
public protocol RegistrationDelegate: AnyObject {
    /**
     Tells the delegate about a new registration event.
     - Parameters:
        - registration: The registration
        - event: The registration event
     */
    func registration(
        _ registration: Registration,
        didReceiveEvent event: RegistrationEvent
    )
}

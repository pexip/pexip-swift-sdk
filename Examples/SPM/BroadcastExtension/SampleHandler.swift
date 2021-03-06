import ReplayKit
import PexipMedia

final class SampleHandler: RPBroadcastSampleHandler, BroadcastSampleHandlerDelegate {
    private lazy var handler: BroadcastSampleHandler = {
        let handler = BroadcastSampleHandler(appGroup: Constants.appGroup)
        handler.delegate = self
        return handler
    }()

    // MARK: - RPBroadcastSampleHandler

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        handler.broadcastStarted()
    }

    override func broadcastPaused() {
        handler.broadcastPaused()
    }

    override func broadcastResumed() {
        handler.broadcastResumed()
    }

    override func broadcastFinished() {
        handler.broadcastFinished()
    }

    override func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) {
        handler.processSampleBuffer(sampleBuffer, with: sampleBufferType)
    }

    // MARK: - BroadcastSampleHandlerDelegate

    func broadcastSampleHandler(
        _ handler: BroadcastSampleHandler,
        didFinishWithError error: Error
    ) {
        // Finish broadcast with user-friendly message.
        super.finishBroadcastWithError(error)
    }
}

Pod::Spec.new do |s|
    s.name         = 'PexipScreenCapture'
    s.version      = '0.7.0'
    s.summary      = 'High level APIs for screen capture on iOS and macOS.'
    s.description  = <<-DESC
                     Pexip Swift SDK is designed for use by iOS/macOS voice/video applications 
                     that want to initiate or connect to conferences hosted on the Pexip Infinity platform.
                     DESC
    s.homepage     = 'https://github.com/pexip'
    s.license      = { :type => 'Apache-2.0', :file => 'LICENSE' }
    s.author       = 'Pexip AS'
    s.platform     = :ios, :osx
    s.ios.deployment_target = '13.0'
    s.osx.deployment_target = '10.15'
    s.source       = { :git => 'https://github.com/pexip/pexip-swift-sdk.git', :tag => "#{s.version}" }
    s.source_files = [
        'Sources/PexipScreenCapture/**/*.swift'
    ]
end

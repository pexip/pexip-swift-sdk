Pod::Spec.new do |s|
    s.name         = 'PexipRTC'
    s.version      = '0.9.0'
    s.summary      = 'Pexip WebRTC-based media stack for sending and receiving video streams.'
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
    s.swift_versions = ['5']
    s.source       = { :git => 'https://github.com/pexip/pexip-swift-sdk.git', :tag => "#{s.version}" }
    s.source_files = [
        'Sources/PexipRTC/**/*.swift'
    ]
    s.dependency 'WebRTCObjc', '105.0.0'
    s.dependency 'PexipCore', "#{s.version}"
    s.dependency 'PexipMedia', "#{s.version}"
end

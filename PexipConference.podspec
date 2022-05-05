Pod::Spec.new do |s|
    s.name         = 'PexipConference'
    s.version      = '0.1.1'
    s.summary      = 'Core components for working with conferences hosted on the Pexip Infinity platform'
    s.description  = <<-DESC
                     Pexip Apple SDK is designed for use by iOS/macOS voice/video applications 
                     that want to initiate or connect to conferences hosted on the Pexip Infinity platform.
                     DESC
    s.homepage     = 'https://github.com/pexip'
    s.license      = {
      type: 'The Apache Software License, Version 1.1',
      file: 'LICENSE'
    }
    s.author       = 'Pexip'
    s.platform     = :ios, :osx
    s.ios.deployment_target = '13.0'
    s.osx.deployment_target = '10.15'
    s.source = {
      http: 'https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64462957.zip',
      sha256: '28e37d022ac72eb893ecae363a9b5c5b854765e87ca833bd9f7351e7c15d88e9'
    }
    s.vendored_frameworks = 'PexipInfinityClient.xcframework'
    s.dependency 'PexipInfinityClient', "#{s.version}"
    s.dependency 'PexipMedia', "#{s.version}"
end
Pod::Spec.new do |s|
    s.name         = 'PexipConference'
    s.version      = '0.1.0'
    s.summary      = 'Core components for working with conferences hosted on the Pexip Infinity platform'
    s.description  = <<-DESC
                     Pexip Apple SDK is designed for use by iOS/macOS voice/video applications 
                     that want to initiate or connect to conferences hosted on the Pexip Infinity platform.
                     DESC
    s.homepage     = 'https://github.com/pexip'
    s.license      = {
      type: 'The Apache Software License, Version 1.1',
      text: <<-LICENSE
      test
      LICENSE
    }
    s.author       = 'Pexip'
    s.platform     = :ios, :osx
    s.ios.deployment_target = '13.0'
    s.osx.deployment_target = '10.15'
    s.source = {
      http: 'https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64679300.zip',
      sha256: '11b66f28b453ab210dd9df919848dea404c74660d85ed37fd7a0a0aa2e0e2032',
      type: 'zip',
      headers: ['Accept: application/octet-stream']
    }
    s.vendored_frameworks = 'PexipConference.xcframework'
    s.dependency 'PexipInfinityClient', "#{s.version}"
    s.dependency 'PexipMedia', "#{s.version}"
end
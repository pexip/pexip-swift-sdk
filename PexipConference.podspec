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
      http: 'https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64683696.zip',
      sha256: '042df7a6d3ac701ac4512390a758d6b7f69507ea8458a33dfcff14849663db34',
      type: 'zip',
      headers: ['Accept: application/octet-stream']
    }
    s.vendored_frameworks = 'PexipConference.xcframework'
    s.dependency 'PexipInfinityClient', "#{s.version}"
    s.dependency 'PexipMedia', "#{s.version}"
end
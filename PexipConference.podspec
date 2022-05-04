Pod::Spec.new do |s|
    s.name         = 'PexipConference'
    s.version      = "0.1.0"
    s.summary      = 'Core components for working with conferences hosted on the Pexip Infinity platform'
    s.description  = <<-DESC
                     Pexip Apple SDK is designed for use by iOS/macOS voice/video applications 
                     that want to initiate or connect to conferences hosted on the Pexip Infinity platform.
                     DESC
    s.homepage     = 'https://github.com/pexip/pexip-ios-sdk-builds'
    s.license      = {
      type: 'The Apache Software License, Version 1.1',
      file: 'LICENSE'
    }
    s.author       = 'Pexip'
    s.platform     = :ios, :osx
    s.ios.deployment_target = '13.0'
    s.osx.deployment_target = '10.15'
    s.source = {
      http: "https://api.github.com/repos/pexip/pexip-ios-sdk-builds/releases/assets/64440621.zip"
      sha256: "3df7478f2f3d8353f6ad9659c52fe3eae572d2681c2e802023b6bf11422ad600"
    }
    s.vendored_frameworks = 'PexipInfinityClient.xcframework'
    s.dependency "PexipInfinityClient", "#{s.version}"
    s.dependency "PexipMedia", "#{s.version}"
end
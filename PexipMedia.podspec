Pod::Spec.new do |s|
    s.name         = 'PexipMedia'
    s.version      = "0.1.0"
    s.summary      = 'Core components for working with audio and video in the Pexip SDK'
    s.description  = <<-DESC
                     Core components for working with audio and video in the Pexip SDK.
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
      http: "https://api.github.com/repos/pexip/pexip-ios-sdk-builds/releases/assets/64440625.zip"
      sha256: "1a74aa798d7058d1fdd0a42a4a1449fb9616072b0916988fad11f6c1011a28ec"
    }
    s.vendored_frameworks = 'PexipMedia.xcframework'
end
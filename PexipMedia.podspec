Pod::Spec.new do |s|
    s.name         = 'PexipMedia'
    s.version      = '0.1.1'
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
      http: 'https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64463025.zip',
      sha256: 'bde85f3062f9d1211cd222a6812dfeafc4fbd3e60db81436132c97e04a288240',
      type: 'zip',
      headers: ['Accept: application/octet-stream']
    }
    s.vendored_frameworks = 'PexipMedia.xcframework'
end
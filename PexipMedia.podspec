Pod::Spec.new do |s|
    s.name         = 'PexipMedia'
    s.version      = '0.1.0'
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
      http: '',
      sha1: ''
    }
    s.vendored_frameworks = 'PexipMedia.xcframework'
end
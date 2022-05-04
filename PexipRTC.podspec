Pod::Spec.new do |s|
    s.name         = 'PexipRTC'
    s.version      = '0.1.0'
    s.summary      = 'Pexip WebRTC-based media stack.'
    s.description  = <<-DESC
                     Pexip SDK utilities
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
      http: 'https://api.github.com/repos/pexip/pexip-ios-sdk-builds/releases/assets/64440632.zip',
      sha256: '1f8681918fac30b41ad91206d02b03570a460548663c738007adc08ff224fc6b'
    }
    s.vendored_frameworks = 'PexipRTC.xcframework'
    s.dependency 'WebRTC', ''
    s.dependency 'PexipUtils', "#{s.version}"
    s.dependency 'PexipMedia', "#{s.version}"
end

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
      http: https://api.github.com/repos/pexip/pexip-ios-sdk-builds/releases/assets/64400582.zip
      sha256: ccd19e76be3a46c1ac50bd834bba07a2b7f4b94e8c0f866a291169a5c8b7e250
    }
    s.vendored_frameworks = 'PexipRTC.xcframework'
    s.dependency "WebRTC", "100.0.0"
    s.dependency "PexipUtils", "#{s.version}"
    s.dependency "PexipMedia", "#{s.version}"
end
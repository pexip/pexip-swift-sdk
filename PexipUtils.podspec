Pod::Spec.new do |s|
    s.name         = 'PexipUtils'
    s.version      = '0.1.0'
    s.summary      = 'Pexip SDK utilities'
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
      http: https://api.github.com/repos/pexip/pexip-ios-sdk-builds/releases/assets/64400586.zip
      sha256: e2d7ae3b8b63386c0a7b2194420438fa32dc714707c3eb04e2bc18ac8e6b29b3
    }
    s.vendored_frameworks = 'PexipUtils.xcframework'
end
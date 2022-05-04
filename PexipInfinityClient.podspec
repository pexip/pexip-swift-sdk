Pod::Spec.new do |s|
    s.name         = 'PexipInfinityClient'
    s.version      = '0.1.0'
    s.summary      = 'Pexip Infinity client API'
    s.description  = <<-DESC
                     Pexip Infinity client API.
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
      http: 'https://api.github.com/repos/pexip/pexip-ios-sdk-builds/releases/assets/64440624.zip',
      sha256: '0932c5c8fb88bd851abc22f5d94287307aa7f04d34e7042814af7e0d154b91d0'
    }
    s.vendored_frameworks = 'PexipInfinityClient.xcframework'
    s.dependency 'PexipUtils', "#{s.version}"
end
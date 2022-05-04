Pod::Spec.new do |s|
    s.name         = 'PexipInfinityClient'
    s.version      = '0.1.1'
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
      http: 'https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64462996.zip',
      sha256: 'fb68522539aa7acbb59be580efe8a80736a925ace96e057ffa426ef3445fdbb4'
    }
    s.vendored_frameworks = 'PexipInfinityClient.xcframework'
    s.dependency 'PexipUtils', "#{s.version}"
end
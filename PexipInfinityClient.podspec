Pod::Spec.new do |s|
    s.name         = 'PexipInfinityClient'
    s.version      = '0.1.0'
    s.summary      = 'Pexip Infinity client API'
    s.description  = <<-DESC
                     Pexip Infinity client API.
                     DESC
    s.homepage     = 'https://github.com/pexip'
    s.license      = {
      type: 'The Apache Software License, Version 1.1',
      file: 'LICENSE'
    }
    s.author       = 'Pexip'
    s.platform     = :ios, :osx
    s.ios.deployment_target = '13.0'
    s.osx.deployment_target = '10.15'
    s.source = {
      http: 'https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64679307.zip',
      sha256: '2350d6ed0100c95fd722c21940f27e358b24c9d8d8665e54c90f0f89c2fa9acf',
      type: 'zip',
      headers: ['Accept: application/octet-stream']
    }
    s.vendored_frameworks = 'PexipInfinityClient.xcframework'
    s.dependency 'PexipUtils', "#{s.version}"
end
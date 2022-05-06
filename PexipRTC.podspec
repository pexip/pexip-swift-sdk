Pod::Spec.new do |s|
    s.name         = 'PexipRTC'
    s.version      = '0.1.0'
    s.summary      = 'Pexip WebRTC-based media stack.'
    s.description  = <<-DESC
                     Pexip SDK utilities
                     DESC
    s.homepage     = 'https://github.com/pexip'
    s.license      = {
      type: 'The Apache Software License, Version 1.1',
      text: <<-LICENSE
      LICENSE
    }
    s.author       = 'Pexip'
    s.platform     = :ios, :osx
    s.ios.deployment_target = '13.0'
    s.osx.deployment_target = '10.15'
    s.source = {
      http: 'https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64683719.zip',
      sha256: '77df20a0a5e75a40e016a6ea26a6438cd632873e3d960bbfdb82f7ea473d5739',
      type: 'zip',
      headers: ['Accept: application/octet-stream']
    }
    s.vendored_frameworks = 'PexipRTC.xcframework'
    s.dependency 'WebRTC', '96.0.4664'
    s.dependency 'PexipUtils', "#{s.version}"
    s.dependency 'PexipMedia', "#{s.version}"
end

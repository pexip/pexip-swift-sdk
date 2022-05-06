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
      file: 'LICENSE'
    }
    s.author       = 'Pexip'
    s.platform     = :ios, :osx
    s.ios.deployment_target = '13.0'
    s.osx.deployment_target = '10.15'
    s.source = {
      http: 'https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64679342.zip',
      sha256: '24d4b39ac5719fb68125cb572f0c00f7b5d88ad76c92f3a95f1151d686d4e64a',
      type: 'zip',
      headers: ['Accept: application/octet-stream']
    }
    s.vendored_frameworks = 'PexipRTC.xcframework'
    s.dependency 'WebRTC', '96.0.4664'
    s.dependency 'PexipUtils', "#{s.version}"
    s.dependency 'PexipMedia', "#{s.version}"
end

Pod::Spec.new do |s|
    s.name         = 'PexipRTC'
    s.version      = '0.1.1'
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
      http: 'https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64463032.zip',
      sha256: 'ad0f6638fbc595f6027b27a444b6c4c96551848d0c943db9241e6b2bc66d0e5d',
      type: 'zip',
      headers: ['Accept: application/octet-stream']
    }
    s.vendored_frameworks = 'PexipRTC.xcframework'
    s.dependency 'WebRTC', '100.0.4896'
    s.dependency 'PexipUtils', "#{s.version}"
    s.dependency 'PexipMedia', "#{s.version}"
end

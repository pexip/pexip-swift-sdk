Pod::Spec.new do |s|
    s.name         = 'PexipUtils'
    s.version      = '0.1.1'
    s.summary      = 'Pexip SDK utilities'
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
      http: 'https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64463054.zip',
      sha256: '8e6645a6859847fae77fbf9dddbe201cfae8d24f6d27d1b97ca841bdeff125e7',
      type: 'zip',
      headers: ['Accept: application/octet-stream']
    }
    s.vendored_frameworks = 'PexipUtils.xcframework'
end
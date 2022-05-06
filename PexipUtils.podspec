Pod::Spec.new do |s|
    s.name         = 'PexipUtils'
    s.version      = '0.1.0'
    s.summary      = 'Pexip SDK utilities'
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
      http: 'https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64683724.zip',
      sha256: 'd52eaa306d8ca799ea9dfe57cb039c59a7414b2235d6930c64217f77c14342de',
      type: 'zip',
      headers: ['Accept: application/octet-stream']
    }
    s.vendored_frameworks = 'PexipUtils.xcframework'
end
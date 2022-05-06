Pod::Spec.new do |s|
    s.name         = 'PexipInfinityClient'
    s.version      = '0.1.1'
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
      http: 'https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64672458s.zip',
      sha256: 'a82cb76700b46bcb78388fde2ef526ef17a4d2156ffd439fff6326c293d02cfe',
      type: 'zip',
      headers: ['Accept: application/octet-stream']
    }
    s.vendored_frameworks = 'XCFrameworks/PexipInfinityClient.xcframework'
    s.dependency 'PexipUtils', "#{s.version}"
end
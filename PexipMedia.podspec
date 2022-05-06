Pod::Spec.new do |s|
    s.name         = 'PexipMedia'
    s.version      = '0.1.0'
    s.summary      = 'Core components for working with audio and video in the Pexip SDK'
    s.description  = <<-DESC
                     Core components for working with audio and video in the Pexip SDK.
                     DESC
    s.homepage     = 'https://github.com/pexip'
    s.license      = {
      type: 'The Apache Software License, Version 1.1',
      text: <<-LICENSE
      test
      LICENSE
    }
    s.author       = 'Pexip'
    s.platform     = :ios, :osx
    s.ios.deployment_target = '13.0'
    s.osx.deployment_target = '10.15'
    s.source = {
      http: 'https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64683713.zip',
      sha256: '0dfc4d8029ae4f205ec5bd34da12406a0b98c5d39bb557125be053b6604c66e6',
      type: 'zip',
      headers: ['Accept: application/octet-stream']
    }
    s.vendored_frameworks = 'PexipMedia.xcframework'
end
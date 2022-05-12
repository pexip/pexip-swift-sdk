Pod::Spec.new do |s|
    s.name         = 'PexipRTC'
    s.version      = '0.2.0'
    s.summary      = 'Pexip WebRTC-based media stack for sending and receiving video streams.'
    s.description  = <<-DESC
                     Pexip Swift SDK is designed for use by iOS/macOS voice/video applications 
                     that want to initiate or connect to conferences hosted on the Pexip Infinity platform.
                     DESC
    s.homepage     = 'https://github.com/pexip'
    s.license      = {
      type: 'The Apache Software License, Version 1.1',
      text: <<-LICENSE
      The Apache Software License, Version 1.1
      
      Copyright (c) 2022 Pexip AS. All rights reserved.
      
      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:
      
      1. Redistributions of source code must retain the above copyright
         notice, this list of conditions and the following disclaimer.
      
      2. Redistributions in binary form must reproduce the above copyright
         notice, this list of conditions and the following disclaimer in
         the documentation and/or other materials provided with the
         distribution.
      
      3. The end-user documentation included with the redistribution,
         if any, must include the following acknowledgment:
         "This product includes software developed by the
         Pexip AS (https://www.pexip.com/)."
         Alternately, this acknowledgment may appear in the software itself,
         if and wherever such third-party acknowledgments normally appear.
       
      4. The name "Pexip" must not be used to endorse or promote products 
         derived from this software without prior written permission. 
         
      5. Products derived from this software may not be called "Pexip",
         nor may "Pexip" appear in their name, without prior written
         permission of the Pexip AS.
      
      THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED
      WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
      OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
      DISCLAIMED.  IN NO EVENT SHALL PEXIP AS OR ITS CONTRIBUTORS BE 
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,SPECIAL, EXEMPLARY, 
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
      OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
      BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
      WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
      OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
      EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
      LICENSE
    }
    s.author       = 'Pexip'
    s.platform     = :ios, :osx
    s.ios.deployment_target = '13.0'
    s.osx.deployment_target = '10.15'
    s.source = {
      http: 'https://github.com/pexip/pexip-swift-sdk/releases/download/untagged-1c543b808d9d4f62485f/PexipRTC.xcframework.zip',
      sha256: '2990833e960ea03e74614abbc6feccc8895be361dc575f8b205bcd7842f0482c',
      type: 'zip',
      headers: ['Accept: application/octet-stream']
    }
    s.vendored_frameworks = 'PexipRTC.xcframework'
    s.dependency 'WebRTC', '96.0.4664'
    s.dependency 'PexipUtils', "#{s.version}"
    s.dependency 'PexipMedia', "#{s.version}"
end

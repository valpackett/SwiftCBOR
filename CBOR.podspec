Pod::Spec.new do |s|
  s.name = 'CBOR'
  s.version = '0.2.0'
  s.license = { :type => "public domain", :file => 'UNLICENSE' }
  s.summary = 'A CBOR implementation for Swift'
  s.homepage = 'https://github.com/myfreeweb/SwiftCBOR'
  s.authors = { 'Greg' => 'greg@unrelenting.technology' }
  s.source = { :git => 'https://github.com/myfreeweb/SwiftCBOR.git', :tag => 'v0.2.0' }
  s.swift_version = '4.0'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.source_files = 'SwiftCBOR/*.{swift,h}'

  s.requires_arc = true
end

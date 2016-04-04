Pod::Spec.new do |s|
  s.name = 'CBOR'
  s.version = '0.1'
  s.license = { :type => "public domain", :file => 'UNLICENSE' }
  s.summary = 'A CBOR implementation for Swift'
  s.homepage = 'https://github.com/myfreeweb/SwiftCBOR'
  s.social_media_url = 'https://twitter.com/myfreeweb'
  s.authors = { 'Greg' => 'greg@unrelenting.technology' }
  s.source = { :git => 'https://github.com/myfreeweb/SwiftCBOR.git' }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.source_files = 'SwiftCBOR/*.{swift,h}'

  s.requires_arc = true
end

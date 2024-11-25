Pod::Spec.new do |s|
  s.name = 'SwiftCBOR'
  s.version = '0.5.0'
  s.license = { type: 'public domain', file: 'UNLICENSE' }
  s.summary = 'A CBOR implementation for Swift'
  s.homepage = 'https://github.com/unrelentingtech/SwiftCBOR'
  s.authors = {
    'Val' => 'val@packett.cool',
    'Ham' => 'hamchapman@gmail.com'
  }
  s.source = { git: 'https://github.com/unrelentingtech/SwiftCBOR.git', tag: "v#{s.version}" }
  s.swift_version = '5.0'

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.13'
  s.tvos.deployment_target = '13.0'

  s.source_files = 'Sources/**/*.{swift,h}'

  s.requires_arc = true
end

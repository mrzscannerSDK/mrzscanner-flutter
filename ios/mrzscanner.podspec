require 'yaml'

pubspec = YAML.load_file(File.join(__dir__, '..', 'pubspec.yaml'))

# The Flutter plugin's iOS side for CocoaPods: the plugin, the MRZ scanner's iOS SDK and its core in
# one pod (Swift Package Manager: mrzscanner/Package.swift).
Pod::Spec.new do |s|
  s.name = 'mrzscanner'
  s.version = pubspec['version']
  s.summary = pubspec['description']
  s.homepage = pubspec['homepage']
  s.license = { :file => '../LICENSE' }
  s.author = 'Barkoder'
  s.source = { :path => '.' }
  s.platform = :ios, '15.0'
  s.swift_version = '5.9'
  s.source_files = 'mrzscanner/Sources/**/*.swift'
  s.vendored_frameworks = 'mrzscanner/Frameworks/MRZScannerCore.xcframework'
  s.frameworks = 'AVFoundation', 'SwiftUI'
  s.dependency 'Flutter'
  # Flutter.framework has no i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end

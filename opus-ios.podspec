Pod::Spec.new do |s|
  s.name         = "Opus-ios"
  s.version      = "1.9"
  s.summary      = "iOS build scripts for the Opus Codec."
  s.description  = <<-DESC
    iOS build of the Opus audio codec library. Opus is a totally open, 
    royalty-free, highly versatile audio codec designed for interactive 
    speech and audio transmission over the Internet.
    
    This package provides an XCFramework that supports:
    - iOS Device (arm64)
    - iOS Simulator (x86_64 for Intel, arm64 for Apple Silicon)
  DESC
  s.homepage     = "https://github.com/OnBeep/Opus-iOS"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Chris Ballinger" => "chris@chatsecure.org" }
  s.source       = { :git => "https://github.com/OnBeep/Opus-iOS.git", :tag => s.version.to_s }
  
  s.platform     = :ios, '16.0'
  s.ios.deployment_target = '16.0'
  
  # Use XCFramework for proper simulator support
  s.vendored_frameworks = 'dependencies/opus.xcframework'
  
  s.requires_arc = false
  
  # Pod-specific settings
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => ''
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => ''
  }
end

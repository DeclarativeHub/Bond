Pod::Spec.new do |s|

  s.name         = "Bond"
  s.version      = "6.7.0"
  s.summary      = "A Swift binding framework"

  s.description  = <<-DESC
                   Bond is a Swift reactive binding framework that takes binding concept to a whole new level.
                   It's simple, powerful, type-safe and multi-paradigm - just like Swift.

                   Bond is also a framework that bridges the gap between the reactive and imperative paradigms.
                   You can use it as a standalone framework to simplify your state changes with bindings and reactive data sources,
                   but you can also use it with ReactiveKit to complement your reactive data flows with bindings and
                   reactive delegates and data sources.
                   DESC

  s.homepage     = "https://github.com/SwiftBond/Bond"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Srdan Rasic" => "srdan.rasic@gmail.com" }
  s.social_media_url   = "http://twitter.com/srdanrasic"
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/SwiftBond/Bond.git", :tag => "6.7.0" }
  s.source_files  = "Sources/**/*.{h,m,swift}", "Supporting Files/Bond.h"
  s.ios.exclude_files = "Sources/Bond/AppKit"
  s.tvos.exclude_files = "Sources/Bond/AppKit"
  s.osx.exclude_files = "Sources/Bond/UIKit"
  s.pod_target_xcconfig = { "OTHER_SWIFT_FLAGS" => "-DBUILDING_WITH_XCODE $(inherited)" }
  s.requires_arc = true

  s.dependency "ReactiveKit", "~> 3.8"
  s.dependency "Differ", "~> 1.0"

end

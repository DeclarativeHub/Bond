Pod::Spec.new do |s|

  s.name         = "Bond"
  s.version      = "4.3.0"
  s.summary      = "A Swift binding framework"

  s.description  = <<-DESC
                   Bond is a Swift reactive binding framework that takes binding concept to a whole new level - boils it down to just one operator. It's simple, powerful, type-safe and multi-paradigm - just like Swift.

                   Bond was created with two goals in mind: simple to use and simple to understand.
                   One might argue whether the former implies the latter, but Bond will save you some thinking because both are true in this case.
                   Its foundation is one simple class - everything else are extensions and syntactic sugars.
                   DESC

  s.homepage     = "https://github.com/SwiftBond/Bond"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.author             = { "Srdan Rasic" => "srdan.rasic@gmail.com" }
  s.social_media_url   = "http://twitter.com/srdanrasic"
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.tvos.deployment_target = '9.0'
  s.source       = { :git => "https://github.com/SwiftBond/Bond.git", :tag => "v4.3.0" }
  s.source_files  = ["Bond", "Bond/Core", "Bond/Extensions/Shared", "Bond/Extensions/OSX", "Bond/Extensions/iOS"]
  s.ios.exclude_files = "Bond/Extensions/OSX"
  s.tvos.exclude_files = "Bond/Extensions/OSX"
  s.osx.exclude_files = "Bond/Extensions/iOS"
  s.framework     = 'SystemConfiguration'
  s.exclude_files = "Classes/Exclude"
  s.requires_arc = true

end

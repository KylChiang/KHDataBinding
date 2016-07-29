
Pod::Spec.new do |s|
  s.name         = "KHDataBind"
  s.version      = "1.4.13"
  s.summary      = "using swizzle method to binding an array with table view or collection view"
  s.description  = <<-DESC
					to sync table view display with an array
                   DESC
  s.homepage     = "https://github.com/gevin/KHDataBind"
  s.license      = { :type => 'MIT' }
  s.author             = { "GevinChen" => "lowgoo@gmail.com" }
  # s.social_media_url   = "http://twitter.com/GevinChen"
  s.platform     = :ios, '8.0'
  # s.ios.deployment_target = "5.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/gevin/KHDataBind.git", :tag => "1.4.13" }
  s.source_files  = "KHDataBind/*"
#  s.public_header_files = "KHDataBind/TableViewBindHelper.h"
#  s.exclude_files = "Classes/Exclude"
  s.ios.frameworks = 'Foundation', 'UIKit'
  s.requires_arc = true
  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  s.dependency 'CCBottomRefreshControl'
end

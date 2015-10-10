
Pod::Spec.new do |s|
  s.name         = "DataBindTest"
  s.version      = "0.0.3"
  s.summary      = "using KVO to binding a data model with view"
  s.description  = <<-DESC
  			 讓 table view 的內容 bind 一個 array
                   DESC
  s.homepage     = "https://github.com/gevin/DataBindTest"
  s.license      = { :type => 'MIT' }
  s.author             = { "GevinChen" => "lowgoo@gmail.com" }
  # s.social_media_url   = "http://twitter.com/GevinChen"
  s.platform     = :ios, '8.0'
  # s.ios.deployment_target = "5.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/gevin/DataBindTest.git", :tag => '0.0.4' }
  s.source_files  = "DataBind/*"
#  s.public_header_files = "DataBind/TableViewBindHelper.h"
#  s.exclude_files = "Classes/Exclude"
  s.ios.frameworks = 'Foundation', 'UIKit'
  s.requires_arc = true
  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end

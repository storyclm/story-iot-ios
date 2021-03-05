#
#  Be sure to run `pod spec lint SCLMManaging.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name        = "StoryIoT"
  s.version     = "1.6.3"
  s.summary     = "StoryIoT"

  s.description = "StoryIoT library"
  s.homepage    = "https://breffi.ru/en/storyclm"

  s.license     = { :type => "MIT", :file => "LICENSE" }

  s.author      = { "Alexander Yolkin" => "alexander.yolkin@gmail.com" }
  s.platform    = :ios, "11.0"

  s.source      = { :git => "https://github.com/storyclm/story-iot-ios.git", :tag => "#{s.version}" }


  s.source_files  = "StoryIoT", "StoryIoT/**/*.{swift}"
  s.exclude_files = "StoryIoT/Exclude"
  s.public_header_files = "StoryIoT/**/*.h"

  s.swift_version = "5.0"
  s.requires_arc = true

  s.dependency 'Alamofire', '~> 4.9'
  
end

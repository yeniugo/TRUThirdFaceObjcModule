#
# Be sure to run `pod lib lint TRUThirdFaceObjcModule.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TRUThirdFaceObjcModule'
  s.version          = '0.0.1'
  s.summary          = 'A short description of TRUThirdFaceObjcModule.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/yeniugo/TRUThirdFaceObjcModule'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yeniugo' => 'hukaihope@gmail.com' }
  s.source           = { :git => 'https://github.com/yeniugo/TRUThirdFaceObjcModule.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'TRUThirdFaceObjcModule/Classes/**/*'
  
  s.requires_arc = true
  s.libraries = 'c++'
  s.resource_bundles = {
    'TRUThirdFaceModule' => ['TRUThirdFaceObjcModule/Assets/*']
  }
  s.ios.vendored_frameworks = 'TRUThirdFaceObjcModule/Frameworks/AuthenAnti_SpoofingSDK.framework'
  #s.vendored_frameworks = 'TRUThirdFaceObjcModule/Frameworks/AuthenAnti_SpoofingSDK.framework'
  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'CoreMedia','AVFoundation','AssetsLibrary','Accelerate','CoreGraphics'
  # s.dependency 'AFNetworking', '~> 2.3'
end

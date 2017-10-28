#
# Be sure to run `pod lib lint SimpleMarkdownParser.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SimpleMarkdownParser'
  s.version          = '0.5.5'
  s.summary          = 'A multi-functional and easy way to integrate markdown formatting within mobile apps.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Easy to use, convert markdown to attributed strings and place it on a UILabel. Highly customizable to implement custom styling. Supports a basic set of commonly used markdown.
                       DESC

  s.homepage         = 'https://github.com/crescentflare/SimpleMarkdownParser'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Crescent Flare' => 'info@crescentflare.com' }
  s.source           = { :git => 'https://github.com/crescentflare/SimpleMarkdownParser.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'MarkdownIOS/SimpleMarkdownParser/Classes/**/*'
  
  # s.resource_bundles = {
  #   'SimpleMarkdownParser' => ['MarkdownIOS/SimpleMarkdownParser/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

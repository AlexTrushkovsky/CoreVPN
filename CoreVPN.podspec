#
# Be sure to run `pod lib lint CoreVPN.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CoreVPN'
  s.version          = '1.0.4'
  s.summary          = 'Easy VPN connection.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Easy VPN connection with IKEv2, L2TP protocols support
  with optimal server selection based on ping.
                       DESC

  s.homepage         = 'https://github.com/AlexTrushkovsky/CoreVPN'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alexey Trushkovsky' => 'trushkovskya@gmail.com' }
  s.source           = { :git => 'https://github.com/AlexTrushkovsky/CoreVPN.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.swift_versions = '5.1'
  s.source_files = 'CoreVPN/Classes/**/*'
  
  # s.resource_bundles = {
  #   'CoreVPN' => ['CoreVPN/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'PlainPing'
end

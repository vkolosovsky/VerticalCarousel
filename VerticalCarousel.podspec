#
# Be sure to run `pod lib lint VerticalCarousel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'VerticalCarousel'
  s.version          = '0.1.1'
  s.summary          = 'One more ugly UICollectionView'

  s.description      = <<-DESC
PDF like cards swiper with "stick-to card edge" physics. Built with a UICollectionView and a custom flowLayout
                       DESC


  s.homepage         = 'https://github.com/alyona-bachurina/VerticalCarousel'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'alyona-bachurina' => 'a.bachurina@gmail.com' }
  s.source           = { :git => 'https://github.com/alyona-bachurina/VerticalCarousel.git', :tag => s.version.to_s }
    
  s.swift_version = '5.2'
  s.ios.deployment_target = '14.0'
  s.source_files = 'Sources/*.swift'

end

Pod::Spec.new do |s|
  s.name          = 'WTURLImageView'
  s.version       = '0.0.1'
  s.license       = 'proprietary'
  s.summary       = 'UIImageView that get image using AFNetworking with various featuresi.'
  s.homepage      = 'http://www.waterworld.com.hk'
  s.author        = { 'waterlou' => 'https://github.com/waterlou' }

  s.platform      = :ios, '5.0'
  s.requires_arc  = true
  s.source        = { :git => 'ssh://git.waterworld.com.hk/WTURLImageView.git', :tag => '0.0.1' }
  s.frameworks    = 'UIKit', 'QuartzCore'
  s.source_files  = 'WTURLImageView/*.{h,m}'

  s.dependency 'AFNetworking', '~>1.0'
  s.dependency 'GVCache', '~>1.0'
end

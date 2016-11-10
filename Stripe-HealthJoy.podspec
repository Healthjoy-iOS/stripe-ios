Pod::Spec.new do |s|
  s.name                           = 'Stripe-HealthJoy'
  s.version                        = '10.0.2'
  s.summary                        = 'Stripe is a web-based API for accepting payments online.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Jack Flintermann' => 'jack@stripe.com', 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/nekromarko/stripe-ios-HealthJoy.git', :tag => "10.0.2" }
  s.frameworks                     = 'Foundation', 'Security', 'WebKit', 'PassKit', 'AddressBook'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '8.0'
  s.public_header_files            = 'Stripe/PublicHeaders/*.h'
  s.source_files                   = 'Stripe/PublicHeaders/*.h', 'Stripe/*.{h,m}'
  s.ios.resource_bundle            = { 'Stripe' => 'Stripe/Resources/**/*' }
end

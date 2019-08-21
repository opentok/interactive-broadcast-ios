platform :ios, '9.0'

target 'IBDemo' do
  pod 'Fabric'
  pod 'Crashlytics'
end

target 'IBKit' do
  pod 'DGActivityIndicatorView'
  pod 'SVProgressHUD'
  pod 'Reachability'
  pod 'OpenTok', '= 2.16.2'
  pod 'OTKAnalytics', '~> 1.0.0'
  
  # we use this version for fixing a bug: https://stackoverflow.com/questions/40304432/exc-bad-access-code-2-on-including-firebase-auth-in-podfile/40315339#40315339
  pod 'Firebase/Core', '~> 3.7.1'
  pod 'Firebase/Auth'
  pod 'Firebase/Database'
end

target 'IBKitTests' do
	pod 'Kiwi'
end

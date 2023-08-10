# Uncomment the next line to define a global platform for your project
# platform :ios, '15.0'

target 'WakeApp' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  pod 'FirebaseAuth'
  pod 'FirebaseFirestore'
  pod 'FirebaseStorage'
  pod 'FirebaseFunctions'
  pod 'GoogleSignIn'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'Kingfisher'
  pod 'CropViewController'
  pod 'IQKeyboardManagerSwift'
  pod 'RxDataSources'
  pod 'Google-Mobile-Ads-SDK'
  pod 'Firebase/Analytics'
  pod 'LicensePlist'

  # Pods for WakeApp

  target 'WakeAppTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'WakeAppUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end

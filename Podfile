use_frameworks!

workspace 'shoppin.xcworkspace'

project 'shoppin.xcodeproj'
project 'Providers/Providers.xcodeproj'


def providersdeps
    pod 'Reachability', '~> 3.2'
    pod 'RealmSwift', '~> 3.13.1'
    pod 'SwiftyBeaver', '~> 1.5.0'

    # fixme - shouldn't be necessary to have these dependencies here see http://stackoverflow.com/q/41191028/930450
    pod 'Alamofire', '~> 4.5'
    pod 'Valet', '~> 3.2.3'
    pod 'Starscream', '3.0.2'
end

# Shared by app and ui tests
def gromadeps
    pod 'SwiftValidator', :git => 'https://github.com/i-schuetz/SwiftValidator.git', :branch => 'remove_delegate_callback'
    pod 'SwiftCharts', '~> 0.6.3'
    pod 'GoogleSignIn'
    pod 'SwipeView', '~> 1.3.2'
    pod 'CMPopTipView', '~> 2.0'
    pod 'KLCPopup', '~> 1.0'
    pod 'ChameleonFramework/Swift', :git => 'https://github.com/ViccAlexander/Chameleon.git'
    pod 'HockeySDK'
    pod 'ASValueTrackingSlider', '~> 0.12.1'
    pod 'ChartLegends', :git => 'https://github.com/i-schuetz/ChartLegends.git'
    pod 'lottie-ios'
    pod 'FBSDKCoreKit'
    pod 'FBSDKLoginKit'
    pod 'FBSDKShareKit'
    providersdeps
end

#target 'shoppin_osx' do
#    platform :osx, '10.10'
#    shared
#end

target 'Providers' do
    project 'Providers/Providers.xcodeproj'
    providersdeps
end

target 'groma' do
    project 'shoppin.xcodeproj'
    platform :ios, '9.0'
    gromadeps
end

target 'shoppinUITests' do
    project 'shoppin.xcodeproj'
    platform :ios, '9.0'
    gromadeps
end

target 'ProvidersTests' do
    project 'Providers/Providers.xcodeproj'
    platform :ios, '9.0'
    providersdeps
end


target 'Siri' do
    project 'shoppin.xcodeproj'
    platform :ios, '10.0'
    providersdeps
end


#target 'shoppin_osxTests' do
#    platform :osx, '10.10'
#    shared
#    pod 'Nimble', '~> 5.0.0'
#end


#post_install do |installer|
#    puts("Update debug pod settings to speed up build time")
#    Dir.glob(File.join("Pods", "**", "Pods*{debug,Private}.xcconfig")).each do |file|
#        File.open(file, 'a') { |f| f.puts "\nDEBUG_INFORMATION_FORMAT = dwarf" }
#    end
#end

# Fix "too many symbols" on app submission https://stackoverflow.com/a/48518656/930450
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
    end
  end
end

use_frameworks!

def shared
    pod 'Alamofire', '~> 3.0'
    pod 'Valet', '~> 1.3'
    pod 'RealmSwift'
    pod 'Reachability', '~> 3.2'
end


target 'shoppin_osx' do
    platform :osx, '10.10'
    shared
end

target 'shoppin' do
    platform :ios, '8.0'
    pod 'SwiftValidator', :git => 'https://github.com/i-schuetz/SwiftValidator', :branch => 'swift2.0_remove_delegate_callback'
    pod 'SwiftCharts', :git => 'https://github.com/i-schuetz/SwiftCharts.git'
    pod 'Google/SignIn'
    pod 'SwipeView', '~> 1.3.2'
    pod 'CMPopTipView', '~> 2.0'
    pod 'KLCPopup', '~> 1.0'
    pod 'ChameleonFramework/Swift'
    pod 'Starscream'
    pod 'HockeySDK', '~> 3.8.5'
    pod 'QorumLogs', :git => 'https://github.com/i-schuetz/QorumLogs', :branch => 'only_show_array_files'
    shared
end

target 'shoppin_osxTests' do
    platform :osx, '10.10'
    shared
    pod 'Nimble', :git => 'https://github.com/Quick/Nimble.git', :branch => 'swift-2.0'
end

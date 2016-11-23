use_frameworks!

def shared
    pod 'Alamofire', '~> 4.0'
    pod 'Valet'
    pod 'RealmSwift'
    pod 'Reachability', '~> 3.2'
end


target 'shoppin_osx' do
    platform :osx, '10.10'
    shared
end

target 'shoppin' do
    platform :ios, '8.0'
    pod 'SwiftValidator', :git => 'https://github.com/i-schuetz/SwiftValidator.git', :branch => 'remove_delegate_callback'
    pod 'SwiftCharts', :git => 'https://github.com/i-schuetz/SwiftCharts.git'
    pod 'Google/SignIn'
    pod 'SwipeView', '~> 1.3.2'
    pod 'CMPopTipView', '~> 2.0'
    pod 'KLCPopup', '~> 1.0'
    pod 'ChameleonFramework/Swift', :git => 'https://github.com/ViccAlexander/Chameleon.git'
    pod 'Starscream'
    pod 'HockeySDK'
    pod 'QorumLogs'
    shared
end

target 'shoppin_osxTests' do
    platform :osx, '10.10'
    shared
    pod 'Nimble', '~> 5.0.0'
end

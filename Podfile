def shared
    use_frameworks!
    pod 'Alamofire', :git => 'https://github.com/Alamofire/Alamofire.git', :branch => 'swift-2.0'
    pod 'Valet', '~> 1.3'
    pod 'Realm', :git => 'https://github.com/realm/realm-cocoa.git', :branch => 'swift-2.0'
    pod 'RealmSwift', :git => 'https://github.com/realm/realm-cocoa.git', :branch => 'swift-2.0'
end


target 'shoppin_osx' do
    platform :osx, '10.10'
    shared
end

target 'shoppin' do
    platform :ios, '8.0'
    shared
end

target 'shoppin_osxTests' do
    platform :osx, '10.10'
    shared
    pod 'Nimble', :git => 'https://github.com/Quick/Nimble.git', :branch => 'swift-2.0'
end

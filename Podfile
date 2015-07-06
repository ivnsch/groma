def shared
    use_frameworks!
    pod 'Alamofire', '~> 1.2'
    pod 'Valet', '~> 1.3'
end


target 'shoppin_osx' do
    platform :osx, '10.10'
    shared
end

target 'shoppin' do
    platform :ios, '8.0'
    pod 'WYPopoverController', '~> 0.2.2'
    shared
end

target 'shoppin_osxTests' do
    platform :osx, '10.10'
    shared
    pod 'Quick', '~> 0.3.0'
    pod 'Nimble', '~> 0.4.0'

end

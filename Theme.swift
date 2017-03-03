//
//  Theme.swift
//  shoppin
//
//  Created by ischuetz on 04/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import ChameleonFramework

struct Theme {

//    static let lightGrey = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
//    static let lightGrey2 = UIColor(hexString: "D4D4D4") // darker than lightGrey

    
    static let lightGrey = UIColor(hexString: "ACACAC")
    static let lightGrey2 = UIColor(hexString: "D4D4D4")
    
    static let grey = UIColor(hexString: "7D8B8C")
    
    static let cellBottomBorderColor = UIColor(hexString: "EADFE4")
    
    static let blue = UIColor(hexString: "0E95E0")
    static let orange = UIColor(hexString: "FFA83E")
    static var black = UIColor(hexString: "222222")
    
    static var navigationBarTextColor = UIColor.black
    static var navigationBarBackgroundColor = UIColor(hexString: "FFFFFF")
    static var tabBarBackgroundColor = blue
    static var navBarAddColor = blue
    static var tabBarSelectedColor = UIColor.white
    static var tabBarIconsColor = UIColor.black
    static var tabBarTextColor = UIColor.black
    
    static var mainViewsBGColor = lightGrey
    static var topSettingsBarsBackgroundColor = UIColor.white
    static var interleavedCellsBackgroundColor = UIColor.white
    
    static let lightBlue = UIColor(hexString: "e8f0f9")
    static let lightGreyBackground = UIColor(hexString: "F0F0F0")
    static let lightPink = UIColor(hexString: "f9eaf1")
    static let green = UIColor(hexString: "1FAC6A")
    static let lighterGreen = UIColor(hexString: "28c75d")
    static let lightGray = UIColor.lightGray
    
    static let fractionsBGColor = UIColor.gray
    static let unitsBGColor = UIColor.white
    static let unitsFGColor = UIColor.black
    static let fractionsFGColor = UIColor.white
    static let baseQuantitiesBGColor = UIColor.white
    static let baseQuantitiesFGColor = UIColor.black
    static let unitsSelectedColor = blue
    static let fractionsSelectedColor = blue
    
    static let defaultTableViewBGColor = lightGreyBackground
    
    static let popupCornerRadius: CGFloat = 10
    
    static let defaultAnimDuration: Double = 0.2
    
    static let defaultRowAnimation = UITableViewRowAnimation.top
    static let defaultRowPosition = UITableViewScrollPosition.top

    static let submitViewHeight: CGFloat = 60
}

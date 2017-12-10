//
//  Theme.swift
//  shoppin
//
//  Created by ischuetz on 04/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import ChameleonFramework

public struct Theme {

//    public static let lightGrey = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
//    public static let lightGrey2 = UIColor(hexString: "D4D4D4") // darker than lightGrey

    public static let defaultNavBarHeight: CGFloat = 64
    public static var notchNavBarHeight: CGFloat = 88
    public static var navBarHeight: CGFloat = defaultNavBarHeight
    public static var notchHeight: CGFloat = 44

    public static let lightGrey = UIColor(hexString: "ACACAC")
    public static let lightGrey2 = UIColor(hexString: "D4D4D4")
    
    public static let grey = UIColor(hexString: "7D8B8C")
    
    public static let cellBottomBorderColor = UIColor(hexString: "EADFE4")
    
    public static let blue = UIColor(hexString: "0E95E0")
    public static let orange = UIColor(hexString: "FFA83E")
    public static var black = UIColor(hexString: "222222")
    
    public static var navigationBarTextColor = UIColor.black
    public static var navigationBarBackgroundColor = UIColor(hexString: "FFFFFF")
    public static var tabBarBackgroundColor = blue
    public static var navBarAddColor = blue
    public static var tabBarSelectedColor = UIColor.white
    public static var tabBarIconsColor = UIColor.black
    public static var tabBarTextColor = UIColor.black
    
    public static var mainViewsBGColor = lightGrey
    public static var topSettingsBarsBackgroundColor = UIColor.white
    public static var interleavedCellsBackgroundColor = UIColor.white
    
    public static let lightBlue = UIColor(hexString: "e8f0f9")
    public static let lightGreyBackground = UIColor(hexString: "F0F0F0")
    public static let lightPink = UIColor(hexString: "f9eaf1")
    public static let green = UIColor(hexString: "1FAC6A")
    public static let lighterGreen = UIColor(hexString: "28c75d")
    public static let lightGray = UIColor.lightGray
    
    public static let fractionsBGColor = UIColor.gray
    public static let unitsBGColor = UIColor.white
    public static let unitsFGColor = UIColor.black
    public static let fractionsFGColor = UIColor.white
    public static let baseQuantitiesBGColor = UIColor.white
    public static let baseQuantitiesFGColor = UIColor.black
    public static let unitsSelectedColor = blue
    public static let fractionsSelectedColor = blue
    public static let deleteRed = UIColor(hexString: "F66823")
    
    public static let defaultTableViewBGColor = lightGreyBackground
    
    public static let popupCornerRadius: CGFloat = 10
    
    public static let defaultAnimDuration: Double = 0.2
    
    public static let defaultRowAnimation = UITableViewRowAnimation.top
    public static let defaultRowPosition = UITableViewScrollPosition.top

    public static let submitViewHeight: CGFloat = 60
    
    public static let topControllerOverlayAlpha: CGFloat = 0.2

}

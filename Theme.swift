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

//    private static var navAndTabBG = UIColor.flatBlackColorDark()
//    private static var navAndTabFG = UIColor.flatBlackColor()
    
    static let lightGrey = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
    static let blue = UIColor(hexString: "0097D9")
    static let orange = UIColor(hexString: "FFA83E")
    
    static var navigationBarTextColor = UIColor.blackColor()
//    static var navigationBarBackgroundColor = UIColor(gradientStyle: UIGradientStyle.TopToBottom, withFrame:CGRectMake(0, 0, 600, 64), andColors:[UIColor.flatNavyBlueColorDark(), UIColor.flatNavyBlueColor()])
//    static var navigationBarBackgroundColor = UIColor.flatNavyBlueColor()
    static var navigationBarBackgroundColor = UIColor(hexString: "F8F8F8")
    static var tabBarBackgroundColor = blue
    static var navBarAddColor = blue
    static var tabBarSelectedColor = UIColor.whiteColor()
    static var tabBarIconsColor = UIColor.blackColor()
    static var tabBarTextColor = UIColor.blackColor()
    
    static var mainViewsBGColor = lightGrey
//    static var topSettingsBarsBackgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
    static var topSettingsBarsBackgroundColor = UIColor.whiteColor()
    static var interleavedCellsBackgroundColor = UIColor.whiteColor()
}

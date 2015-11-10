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
    
    private static let lightGrey = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
    
    static var navigationBarTextColor = UIColor.blackColor()
//    static var navigationBarBackgroundColor = UIColor(gradientStyle: UIGradientStyle.TopToBottom, withFrame:CGRectMake(0, 0, 600, 64), andColors:[UIColor.flatNavyBlueColorDark(), UIColor.flatNavyBlueColor()])
//    static var navigationBarBackgroundColor = UIColor.flatNavyBlueColor()
    static var navigationBarBackgroundColor = UIColor.whiteColor()
    static var tabBarBackgroundColor = UIColor.whiteColor()
    static var tabBarSelectedColor = UIColor.blackColor()
    static var mainViewsBGColor = lightGrey
//    static var topSettingsBarsBackgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
    static var topSettingsBarsBackgroundColor = UIColor.whiteColor()
    static var interleavedCellsBackgroundColor = UIColor.whiteColor()
}

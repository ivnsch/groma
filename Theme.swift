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

    static let lightGrey = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
    static let blue = UIColor(hexString: "0097D9")
    static let orange = UIColor(hexString: "FFA83E")
    
    static var navigationBarTextColor = UIColor.blackColor()
    static var navigationBarBackgroundColor = UIColor(hexString: "FFFFFF")
    static var tabBarBackgroundColor = blue
    static var navBarAddColor = blue
    static var tabBarSelectedColor = UIColor.whiteColor()
    static var tabBarIconsColor = UIColor.blackColor()
    static var tabBarTextColor = UIColor.blackColor()
    
    static var mainViewsBGColor = lightGrey
    static var topSettingsBarsBackgroundColor = UIColor.whiteColor()
    static var interleavedCellsBackgroundColor = UIColor.whiteColor()
}

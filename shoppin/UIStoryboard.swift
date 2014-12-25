//
//  Storyboard.swift
//  shoppin
//
//  Created by ischuetz on 25.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation
import UIKit

extension UIStoryboard {
    class func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()) }
    
    //    class func rightViewController() -> SidePanelViewController? {
    //        return mainStoryboard().instantiateViewControllerWithIdentifier("RightViewController") as? SidePanelViewController
    //    }
    
    //TODO rename...
    class func centerViewController() -> ViewController? {
        return mainStoryboard().instantiateViewControllerWithIdentifier("ViewController") as? ViewController
    }
    
    
    class func doneItemsViewController() -> ListItemsTableViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("ListItemsTableViewController") as ListItemsTableViewController
    }
}
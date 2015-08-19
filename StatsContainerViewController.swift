//
//  StatsContainerViewController.swift
//  shoppin
//
//  Created by ischuetz on 17/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class StatsContainerViewController: UIViewController {

    private var statsViewController = UIStoryboard.statsViewController()
    private var historyViewController = UIStoryboard.historyViewController()
    
     // TODO can it be initialized here with statsViewController instead of in viewDidLoad()?
    private var currentViewController: UIViewController? {
        didSet {
            oldValue?.removeFromParentViewController()
            oldValue?.view.removeFromSuperview()
            if let viewController = self.currentViewController {
                self.addChildViewControllerAndView(viewController, viewIndex: 0)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.currentViewController = self.statsViewController
    }
    
    @IBAction func onToggleHistoryStatsPress(sender: UIButton) {
    
        let (currentViewController, buttonTitle): (UIViewController, String) = {
            if self.currentViewController is StatsViewController {
                return (self.historyViewController, "Stats")
            } else {
                return (self.statsViewController, "History")
            }
        }()
        
        self.currentViewController = currentViewController
        sender.setTitle(buttonTitle, forState: UIControlState.Normal)
    }
}
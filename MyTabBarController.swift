//
//  MyTabBarController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 11/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit


class MyTabBarController: UITabBarController {

    // Animating the imageView (first child of these views) doesn't work (nothing happens) so we animate the complete item. Since we don't have labels it's ok.
//    var inventoryView: UIView?
//    var statsView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // instance variables don't work. Must access item directly when running animation.
        // TODO verify programmatically tab item is correct (in case possible app or UIKit changes), if its not possible using tabs maybe the name of the image?
//        inventoryView = tabBar.subviews[safe: 3]
//        statsView = tabBar.subviews[safe: 4]
    }
    
    func buyAnimation() {
        
        let scale: CGFloat = 1.4
        let duration: Double = Theme.defaultAnimDuration
        
        // we start with a delay of 0.3 because this is about what it takes for the animate-cart-view-down animation to complete
        let initDelay: Double = 0.3
        
        
        UIView.animate(withDuration: duration, delay: initDelay, options: [], animations: {
            self.tabBar.subviews[safe: 3]?.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) {finished in
            UIView.animate(withDuration: duration) {
                self.tabBar.subviews[safe: 3]?.transform = CGAffineTransform.identity
            }
        }
        
        // Stats starts a little later giving a sequence effect
        UIView.animate(withDuration: duration, delay: initDelay + 0.2, options: [], animations: {
            self.tabBar.subviews[safe: 4]?.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) {finished in
            UIView.animate(withDuration: duration) {
                self.tabBar.subviews[safe: 4]?.transform = CGAffineTransform.identity
            }
        }
    }
}

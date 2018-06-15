//
//  AddRecipeToListNotificationHelper.swift
//  groma
//
//  Created by Ivan Schuetz on 15.06.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class AddRecipeToListNotificationHelper {
    
    static func show(tabBarHeight: CGFloat, parent: UIView, recipeData: RecipeData) {
        let notificationY = Theme.navBarHeight + DimensionsManager.quickAddHeight
        let notificationHeight = UIScreen.main.bounds.height - notificationY - tabBarHeight

        let notification = UILabel(frame: CGRect(x: 0, y: notificationY, width: parent.width, height: notificationHeight))
        notification.backgroundColor = recipeData.color
        notification.textColor = UIColor.white
        notification.textAlignment = .center

        if let fontSize = LabelMore.mapToFontSize(40) {
            let font = UIFont.systemFont(ofSize: fontSize)
            notification.attributedText = trans("recipe_added_to_list", recipeData.name).applyBold(substring: recipeData.name, font: font, color: UIColor.white)
        } else {
            logger.e("An error ocurred loading font/font size - defaulting to plain label", .ui)
            notification.text = recipeData.name
        }

        notification.alpha = 0
        parent.addSubview(notification)
        UIView.animate(withDuration: 0.3, delay: 0.3, animations: { // TODO use exact delay from hide add recipe controller animation
            notification.alpha = 1
        }) { (finished) in
            UIView.animate(withDuration: 0.3, delay: 0.6, animations: {
                notification.alpha = 0
            }) { (finished) in
                notification.removeFromSuperview()
            }
        }
    }
}

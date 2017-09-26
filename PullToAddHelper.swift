//
//  PullToAddHelper.swift
//  shoppin
//
//  Created by ischuetz on 21/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers


// TODO object oriented
class PullToAddHelper {

    
    var onPull: ((MyRefreshControl) -> Void)?
    
    let refreshControl: MyRefreshControl
    
    init(tableView: UITableView, onPull: @escaping (MyRefreshControl) -> Void) {
        self.onPull = onPull
        
        let refreshControl = MyRefreshControl(frame: CGRect(x: 0, y: tableView.y, width: tableView.width, height: 200), backgroundColor: tableView.backgroundColor)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.backgroundView = refreshControl
        }
        
        self.refreshControl = refreshControl
        
        refreshControl.addTarget(self, action: #selector(onPullRefresh(_:)), for: .valueChanged)
        
    }
    
    @objc func onPullRefresh(_ sender: UIRefreshControl) {
        onPull?(refreshControl)
    }
    
    
    // backwards compatibility - TODO remove
    // Creates default refresh control
    // backgroundColor: Overrides parentController's view background color as background color of pull to add
    static func createPullToAdd(_ parentController: UIViewController, backgroundColor: UIColor? = nil) -> MyRefreshControl {
        let refreshControl = MyRefreshControl(frame: CGRect.zero, backgroundColor: backgroundColor ?? parentController.view.backgroundColor)
        return refreshControl
    }
}


class MyRefreshControl: UIRefreshControl {
    
    var arrow: UIImageView?
    
    init(frame: CGRect, backgroundColor: UIColor?) {
        super.init(frame: frame)
        
        let bgView = UIView()
        bgView.translatesAutoresizingMaskIntoConstraints = false
        bgView.backgroundColor = backgroundColor
        addSubview(bgView)
        bgView.fillSuperview()
        
        let label = UILabel()
        label.font = Fonts.fontForSizeCategory(40)
        label.textColor = Theme.grey
        label.text = trans("pull_to_add")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        bgView.addSubview(label)
        
        _ = label.alignTop(bgView, constant: 35)
        _ = label.alignRight(bgView)
        _ = label.alignLeft(bgView)
        _ = label.alignBottom(bgView)
        
        if let arrowImage = UIImage(named: "pull_to_add") {
            let imageView = UIImageView(image: arrowImage)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            bgView.addSubview(imageView)
            
            _ = imageView.positionAboveView(label, constant: -10)
            _ = imageView.centerXInParent()

            self.arrow = imageView
            
            
            imageView.transform = CGAffineTransform(rotationAngle: 180.degreesToRadians)

            
        } else {
            logger.e("No arrow image!")
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func updateForScrollOffset(offset: CGFloat, startOffset: CGFloat = 0) {
        let startOffset: CGFloat = startOffset
        
        let totalAngle: CGFloat = 180
        let distanceForTotalAngle: CGFloat = 75
        
        let ratio = totalAngle / distanceForTotalAngle
        
        let currentDistance = offset - startOffset
        let currentAngle = min(0, currentDistance * ratio) // TODO when scrolling back (lifting finger) we get here 0 and arrow jumps back. Should revert gradually. When scrolling manually back this doesn't happen.
    
        arrow?.transform = CGAffineTransform(rotationAngle: 180.degreesToRadians + min(180.degreesToRadians, abs(currentAngle.degreesToRadians)))
    }
}

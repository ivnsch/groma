//
//  QuickAddItemCell.swift
//  shoppin
//
//  Created by ischuetz on 13/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import ChameleonFramework
import Providers
import QorumLogs

class QuickAddItemCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var brandLabel: UILabel!
    @IBOutlet weak var storeLabel: UILabel!
    
    @IBOutlet weak var nameLabelVerticalCenterContraint: NSLayoutConstraint!
    
    var item: QuickAddItem? {
        didSet {
            if let item = item {
                if let boldRange = item.boldRange {
                    nameLabel.attributedText = item.labelText.makeAttributed(boldRange, normalFont: Fonts.verySmallLight, font: Fonts.verySmallBold)
                } else {
                    nameLabel.text = item.labelText
                }

                let nameCenterConstant: CGFloat = {
                    if item.label2Text.isEmpty && item.label3Text.isEmpty { // no brand and store - show name in the middle
                        return 0
                    } else if !item.label2Text.isEmpty && !item.label3Text.isEmpty { // brand and store - show name at the top
                        return -12
                    } else { // brand or store (only one of them) - show name a bit up
                        return -6
                    }
                }()
                
                contentView.layer.cornerRadius = DimensionsManager.quickAddCollectionViewCellCornerRadius
                contentView.backgroundColor = item.color
                
                let color = UIColor(contrastingBlackOrWhiteColorOn: item.color, isFlat: true)
//                let color = UIColor.whiteColor()
                
                nameLabel.textColor = color
                brandLabel.textColor = color
                storeLabel.textColor = color
                
                brandLabel.text = item.label2Text
                storeLabel.text = item.label3Text
                
                    
                nameLabelVerticalCenterContraint.constant = nameCenterConstant
//                    item.label2Text.isEmpty ? 0 : -6
            }
        }
    }
    
    func copyCell(quantifiableProduct: QuantifiableProduct) -> QuickAddItemCellAnimatableCopy {
        return QuickAddItemCellAnimatableCopy(cell: self, quantifiableProduct: quantifiableProduct)
    }
}



class QuickAddItemCellAnimatableCopy: UIView {
    
    var nameLabel: UILabel!
    var brandLabel: UILabel!
    var baseLabel: UILabel!
    
    var overlay: UIView!
    var baseQuantityLabel: UILabel!
    
    
    init(cell: QuickAddItemCell, quantifiableProduct: QuantifiableProduct) {
        
        super.init(frame: cell.frame)
        
        layer.cornerRadius = cell.contentView.layer.cornerRadius
        backgroundColor = cell.contentView.backgroundColor
        
        let nameLabel = UILabel()
        nameLabel.text = cell.nameLabel.text
        nameLabel.frame = cell.nameLabel.frame
        nameLabel.font = cell.nameLabel.font
        nameLabel.textColor = cell.nameLabel.textColor
        addSubview(nameLabel)
        self.nameLabel = nameLabel
        nameLabel.sizeToFit()
        
        
        let brandLabel = UILabel()
        brandLabel.text = cell.brandLabel.text
        brandLabel.frame = cell.brandLabel.frame
        brandLabel.font = cell.brandLabel.font
        brandLabel.textColor = cell.brandLabel.textColor
        addSubview(brandLabel)
        self.brandLabel = brandLabel
        
        
        let baseLabel = UILabel()
        baseLabel.text = quantifiableProduct.unitText
        baseLabel.frame = CGRect(x: nameLabel.frame.maxX + 5, y: nameLabel.y, width: nameLabel.width, height: nameLabel.height)
        baseLabel.font = cell.brandLabel.font
        baseLabel.textColor = Theme.grey
//        addSubview(baseLabel)
        self.baseLabel = baseLabel
        baseLabel.alpha = 0 // not present in quick add view, so fades in
        
        
        let overlay = UIView(frame: bounds)
        addSubview(overlay)
        self.overlay = overlay
        overlay.backgroundColor = UIColor.clear
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func animateAddToList(targetFrame: CGRect, onFinish: @escaping () -> Void) {
        nameLabel.frame.origin = CGPoint(x: 0, y: 0)
        
        // anchor at the left so it will scale only to the right
        _ = nameLabel.setAnchorWithoutMoving(CGPoint(x: 0, y: nameLabel.layer.anchorPoint.y))
        _ = baseLabel.setAnchorWithoutMoving(CGPoint(x: 0, y: baseLabel.layer.anchorPoint.y))
        
        anim(0.3, {
            self.frame = targetFrame
            self.overlay.frame = targetFrame.bounds
            self.layer.cornerRadius = 0

            self.backgroundColor = UIColor.white
            self.overlay.backgroundColor = UIColor.black.withAlphaComponent(Theme.topControllerOverlayAlpha)
            //                    copy.frame.origin = CGPoint(x: 0, y: quickAddFrameRelativeToWindow.maxY)
            
            let scale: CGFloat = 1.3
            
            let categoryColorViewWidth: CGFloat = 4
            self.nameLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.nameLabel.frame.origin.x = DimensionsManager.leftRightPaddingConstraint + categoryColorViewWidth
            self.nameLabel.center.y = DimensionsManager.defaultCellHeight / 2
            self.nameLabel.textColor = Theme.black
            
            
//            QL3("maxX: \(self.nameLabel.frame.maxX)")
//            
//            self.baseLabel.frame.origin.x = self.nameLabel.width * scale + 4
//            self.baseLabel.center.y = self.nameLabel.center.y
//            self.baseLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
//            self.baseLabel.alpha = 1
            
            
        }, onFinish: {
            delay(0.1) {
                self.removeFromSuperview()
                onFinish()
            }
        })
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

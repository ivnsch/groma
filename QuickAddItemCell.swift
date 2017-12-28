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
    
    func copyCell(quantifiableProduct: QuantifiableProduct, quantity: Float) -> QuickAddItemCellAnimatableCopy {
        return QuickAddItemCellAnimatableCopy(cell: self, quantifiableProduct: quantifiableProduct, quantity: quantity)
    }

    func copyCell(ingredient: Item) -> QuickAddIngredientCellAnimatableCopy {
        return QuickAddIngredientCellAnimatableCopy(cell: self, item: ingredient)
    }
}

protocol QuickAddItemAnimatableCellCopy {
    func animateAddToList(targetFrame: CGRect, targetNameLabelX: CGFloat, onFinish: @escaping () -> Void)
}

class QuickAddItemCellAnimatableCopy: UIView, QuickAddItemAnimatableCellCopy {
    
    fileprivate var nameLabel: UILabel!
    fileprivate var brandLabel: UILabel!
    fileprivate var baseLabel: UILabel!
    fileprivate var quantityLabel: UILabel!
    
    fileprivate var overlay: UIView!
    fileprivate var baseQuantityLabel: UILabel!
    
    
    init(cell: QuickAddItemCell, quantifiableProduct: QuantifiableProduct, quantity: Float) {
        
        super.init(frame: cell.frame)
        
        layer.cornerRadius = cell.contentView.layer.cornerRadius
        backgroundColor = cell.contentView.backgroundColor
        
        let nameLabel = UILabel()
        nameLabel.text = cell.nameLabel.text
        nameLabel.frame = cell.nameLabel.frame
//        nameLabel.font = cell.nameLabel.font
        nameLabel.font = UIFont.systemFont(ofSize: LabelMore.mapToFontSize(50) ?? 20)
        
        
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
        baseLabel.text = quantifiableProduct.baseText
        baseLabel.frame = CGRect(x: nameLabel.frame.maxX + 5, y: nameLabel.y, width: nameLabel.width, height: nameLabel.height)
        baseLabel.font = cell.brandLabel.font
        baseLabel.textColor = Theme.grey
//        addSubview(baseLabel)
        self.baseLabel = baseLabel
        baseLabel.alpha = 0 // not present in quick add view, so fades in
        
        let quantityLabel = UILabel()
        quantityLabel.text = quantity.quantityString
        quantityLabel.frame = CGRect(x: cell.bounds.maxX - 5, y: nameLabel.y, width: nameLabel.width, height: nameLabel.height)
        quantityLabel.font = UIFont.systemFont(ofSize: LabelMore.mapToFontSize(60) ?? 20)
        quantityLabel.textColor = Theme.black
        addSubview(quantityLabel)
        self.quantityLabel = quantityLabel
        quantityLabel.sizeToFit()
        quantityLabel.alpha = 0 // not present in quick add view, so fades in
        
        
        // anchor at the left so it will scale only to the right
        _ = nameLabel.setAnchorWithoutMoving(CGPoint(x: 0, y: nameLabel.layer.anchorPoint.y))
        _ = baseLabel.setAnchorWithoutMoving(CGPoint(x: 0, y: baseLabel.layer.anchorPoint.y))
        
        let scale: CGFloat = 0.7
        
        self.nameLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
        self.quantityLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
        
        addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.defaultCellHeight)
        
        
        let overlay = UIView(frame: bounds)
        addSubview(overlay)
        self.overlay = overlay
        overlay.backgroundColor = UIColor.clear
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    fileprivate func calculateOriginalQuantityLabelSize() -> CGSize {
        let quantityView = QuantityView(frame: CGRect(x: 0, y: 0, width: 1000, height: 1000))
        quantityView.quantity = 1
        quantityView.setNeedsLayout()
        quantityView.layoutIfNeeded()
        return quantityView.quantityLabel.frame.size
    }
    
    func animateAddToList(targetFrame: CGRect, targetNameLabelX: CGFloat, onFinish: @escaping () -> Void) {
        nameLabel.frame.origin = CGPoint(x: 0, y: 0) // TODO what's this for ?

        // Fix for: small jump of label position after animation finishes (i.e. there's a delta between the final animated label and the cell's label).
        // Reason: The label in quantity view has a slightly different size, because we add +2 width in TextFieldMore's intrinsic size as workaround to prevent content truncation. We also can't use the +2 value directly, as the final width for some reason isn't exactly text width +2 (maybe auto layout related rounding) - the time it was debugged it was 1.5. So we just create a dummy quantity view here and get the size of it's label and use this to calculate the animated label's target position.
        let quantityViewLabelSize = calculateOriginalQuantityLabelSize()
        
        anim(0.3, {
            self.frame = targetFrame
            self.overlay.frame = targetFrame.bounds
            self.layer.cornerRadius = 0

            self.backgroundColor = UIColor.white
            self.overlay.backgroundColor = UIColor.black.withAlphaComponent(Theme.topControllerOverlayAlpha)
            //                    copy.frame.origin = CGPoint(x: 0, y: quickAddFrameRelativeToWindow.maxY)
            
            let scale: CGFloat = 1
            
            let categoryColorViewWidth: CGFloat = 0
            self.nameLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
//            self.nameLabel.frame.origin.x = DimensionsManager.leftRightPaddingConstraint + categoryColorViewWidth
            self.nameLabel.frame.origin.x = targetNameLabelX
            self.nameLabel.center.y = DimensionsManager.defaultCellHeight / 2
            self.nameLabel.textColor = Theme.black
            
            

            self.quantityLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.quantityLabel.frame.origin.x = targetFrame.width - DimensionsManager.leftRightPaddingConstraint - quantityViewLabelSize.width
            self.quantityLabel.center.y = DimensionsManager.defaultCellHeight / 2
            self.quantityLabel.alpha = 1
            
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



class QuickAddIngredientCellAnimatableCopy: UIView, QuickAddItemAnimatableCellCopy {

    fileprivate var nameLabel: UILabel!
    fileprivate var unitLabel: UILabel!
    fileprivate var fractionLabel: UILabel!
    fileprivate var quantityLabel: UILabel!

    fileprivate var overlay: UIView!
    fileprivate var baseQuantityLabel: UILabel!


    init(cell: QuickAddItemCell, item: Item) {

        super.init(frame: cell.frame)

        layer.cornerRadius = cell.contentView.layer.cornerRadius
        backgroundColor = cell.contentView.backgroundColor

        let nameLabel = UILabel()
        nameLabel.text = cell.nameLabel.text
        nameLabel.frame = cell.nameLabel.frame
        //        nameLabel.font = cell.nameLabel.font
        nameLabel.font = UIFont.systemFont(ofSize: LabelMore.mapToFontSize(50) ?? 20)


        nameLabel.textColor = cell.nameLabel.textColor
        addSubview(nameLabel)
        self.nameLabel = nameLabel
        nameLabel.sizeToFit()

        // anchor at the left so it will scale only to the right
        _ = nameLabel.setAnchorWithoutMoving(CGPoint(x: 0, y: nameLabel.layer.anchorPoint.y))

        let scale: CGFloat = 0.7

        self.nameLabel.transform = CGAffineTransform(scaleX: scale, y: scale)

        addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.ingredientsCellHeight)


        let overlay = UIView(frame: bounds)
        addSubview(overlay)
        self.overlay = overlay
        overlay.backgroundColor = UIColor.clear
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    func animateAddToList(targetFrame: CGRect, targetNameLabelX: CGFloat, onFinish: @escaping () -> Void) {
        nameLabel.frame.origin = CGPoint(x: 0, y: 0) // TODO what's this for ?

        anim(0.3, {
            self.frame = targetFrame
            self.overlay.frame = targetFrame.bounds
            self.layer.cornerRadius = 0

            self.backgroundColor = UIColor.white
            self.overlay.backgroundColor = UIColor.black.withAlphaComponent(Theme.topControllerOverlayAlpha)
            //                    copy.frame.origin = CGPoint(x: 0, y: quickAddFrameRelativeToWindow.maxY)

            let scale: CGFloat = 1

            let categoryColorViewWidth: CGFloat = 0
            self.nameLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
//            self.nameLabel.frame.origin.x = DimensionsManager.leftRightPaddingConstraint + categoryColorViewWidth
            self.nameLabel.frame.origin.x = targetNameLabelX
            self.nameLabel.center.y = DimensionsManager.ingredientsCellHeight / 2
            self.nameLabel.textColor = Theme.black

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

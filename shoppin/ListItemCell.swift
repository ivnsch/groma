//
//  ProductCell.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

class ListItemCell: SwipeableCell {

    var labelColor:UIColor = UIColor.blackColor() {
        didSet {
            self.nameLabel?.textColor = self.labelColor
            self.quantityLabel?.textColor = self.labelColor
        }
    }
//
//    var listItem:ListItem! {
//        didSet {
//            self.nameLabel?.text = listItem.product.name
//            self.quantityLabel?.text = String(listItem.product.quantity)
//        }
//    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
//    init(listItem: ListItem) {
//        super.init()
//        self.listItem = listItem
//    }
//    
//    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
////        self.setupViews()
//    }
//    
//    required init(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
    
    
//    override func didMoveToSuperview() {
//        self.setupLayout()
//    }
//    
//    func setupViews() {
//        self.contentView.setTranslatesAutoresizingMaskIntoConstraints(false)
//        
//        self.selectionStyle = UITableViewCellSelectionStyle.None
//        
//        self.nameLabel = createNameLabel()
//        self.contentView.addSubview(self.nameLabel)
//        
//        self.quantityLabel = createQuantityLabel()
//        self.contentView.addSubview(self.quantityLabel)
//        
//        self.contentView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
//    }
    
//    func createNameLabel() -> UILabel {
//        let label = UILabel()
////        label.font = UIFont.
//        label.textColor = self.labelColor
////        label.numberOfLines = 1
//        label.font = UIFont(name: "Trebuchet MS", size: 15)
//        return label
//    }
//    
//    func createQuantityLabel() -> UILabel {
//        let label = UILabel()
//        //        label.font = UIFont.
//        label.textColor = self.labelColor
//        //        label.numberOfLines = 1
//        label.font = UIFont(name: "Trebuchet MS", size: 15)
//        return label
//    }
    
//    private func addSuperViewDimensionConstraint(view:UIView, attribute:NSLayoutAttribute) {
//        if let sv = view.superview {
//            let constraint = NSLayoutConstraint(item:view,
//                attribute:attribute,
//                relatedBy:.Equal,
//                toItem:sv,
//                attribute:attribute,
//                multiplier:1.0,
//                constant:0);
//            sv.addConstraint(constraint)
//        }
//    }
    
//    func addSuperViewWidthConstraint(view:UIView) {
//        self.addSuperViewDimensionConstraint(view, attribute: .Width)
//    }
//    
//    func addSuperViewHeightConstraint(view:UIView) {
//        self.addSuperViewDimensionConstraint(view, attribute: .Height)
//    }
//    
//    func addSuperViewDimensionsConstraint(view:UIView) {
//        self.addSuperViewHeightConstraint(view)
//        self.addSuperViewWidthConstraint(view)
//    }
    
//    func setupLayout() {
//        let views:Dictionary = ["nameLabel": self.nameLabel, "quantityLabel": self.quantityLabel]
//        for view in views.values {
//            view.setTranslatesAutoresizingMaskIntoConstraints(false)
//        }
//        
//        self.addSuperViewDimensionsConstraint(self.contentView)
//        
//        let metrics:Dictionary = ["padding": 10]
//        
//        for constraint in [
//            "H:|-(padding)-[nameLabel]-[quantityLabel]-(padding)-|",
//            "V:|-(padding)-[nameLabel]-(padding)-|",
//            "V:|-(padding)-[quantityLabel]-(padding)-|"
//            ] {
//                self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(constraint, options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))
//        }
//    }
    
}

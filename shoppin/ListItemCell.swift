//
//  ProductCell.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

protocol ListItemCellDelegate {
    func onItemSwiped(listItem: TableViewListItem)
    func onStartItemSwipe(listItem: TableViewListItem)
    func onButtonTwoTap(listItem: TableViewListItem)
    func onNoteTap(listItem: TableViewListItem)
    func onMinusTap(listItem: TableViewListItem)
    func onPlusTap(listItem: TableViewListItem)
}

class ListItemCell: SwipeableCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var brandLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var centerVerticallyNameLabelConstraint: NSLayoutConstraint!

    @IBOutlet weak var quantityLabelCenterVerticallyConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var noteButton: UIButton!
    
    @IBOutlet weak var plusMinusContainer: UIView!
    @IBOutlet weak var plusMinusWidthConstraint: NSLayoutConstraint!

    private var delegate: ListItemCellDelegate?
    
    private(set) var status: ListItemStatus?
    var mode: ListItemCellMode = .Note {
        didSet {
            updateModeItemsVisibility(true)
        }
    }
    private(set) var labelColor: UIColor = UIColor.blackColor() {
        didSet {
            self.nameLabel?.textColor = self.labelColor
            self.quantityLabel?.textColor = self.labelColor
        }
    }
    private(set) var tableViewListItem: TableViewListItem? {
        didSet {
            if let tableViewListItem = tableViewListItem, status = status {
                
                let listItem = tableViewListItem.listItem
                
                nameLabel.text = NSLocalizedString(listItem.product.name, comment: "")
                quantityLabel.text = String("\(listItem.quantity(status)) \(listItem.product.unit.shortText)")
                
                centerVerticallyNameLabelConstraint.constant = listItem.product.brand.isEmpty ? 0 : 10
                brandLabel.text = listItem.product.brand
                
                updateModeItemsVisibility(false)
                
                setOpen(tableViewListItem.swiped)
                if tableViewListItem.swiped {
                    backgroundColor = UIColor.clearColor()
                } else {
                    backgroundColor = UIColor.whiteColor()
                }
            }
        }
    }

    func setup(status: ListItemStatus, mode: ListItemCellMode, labelColor: UIColor, tableViewListItem: TableViewListItem, delegate: ListItemCellDelegate) {
        self.status = status
        self.mode = mode
        self.labelColor = labelColor
        
        self.tableViewListItem = tableViewListItem

        self.delegate = delegate
    }
    
    private func updateModeItemsVisibility(animated: Bool) {
        if let tableViewListItem = tableViewListItem, status = status {
            updateModeItemsVisibility(mode, status: status, tableViewListItem: tableViewListItem, animated: true)
        }
    }
    
    private func updateModeItemsVisibility(mode: ListItemCellMode, status: ListItemStatus, tableViewListItem: TableViewListItem, animated: Bool) {
        let constant: CGFloat = {
            switch mode {
            case .Note: return 0
            case .Increment: return 65
            }
        }()
        
        let hasNote = tableViewListItem.listItem.note.map{!$0.isEmpty} ?? false
        let showNote = hasNote && mode == .Note
        
        let (itemsDelay, priceDelay): (NSTimeInterval, NSTimeInterval) = {
            if animated {
                return mode == .Note ? (0.1, 0) : (0, 0.3) // for price a different delay to make it animate after/before the other elements (looks better imo)
            } else {
                return (0, 0)
            }
        }()

        func update() {
            layoutIfNeeded()
            switch mode {
            case .Note:
                noteButton.alpha = showNote ? 1 : 0
                plusMinusContainer.alpha = 0
            case .Increment:
                noteButton.alpha = 0
                plusMinusContainer.alpha = 1
            }
        }
        
        if animated {
            delay(itemsDelay) {[weak self] in
                self?.plusMinusWidthConstraint.constant = constant
                UIView.animateWithDuration(0.2) {
                    update()
                }
            }
        } else {
            update()
        }
        
        showPrice(tableViewListItem, status: status, mode: mode, animated: animated, animDelay: priceDelay)
    }
    
    private func showPrice(tableViewListItem: TableViewListItem, status: ListItemStatus, mode: ListItemCellMode, animated: Bool, animDelay: NSTimeInterval) {
        let price = tableViewListItem.listItem.totalPrice(status)
        let hasPrice = price > 0
        let showPrice = hasPrice && mode == .Increment
        if showPrice {
            priceLabel.text = price.toLocalCurrencyString()
        }
        
        func updateConstraint() {
            quantityLabelCenterVerticallyConstraint.constant = showPrice ? 10 : 0
        }
        
        func updateAlpha() {
            priceLabel.alpha = showPrice ? 1 : 0
        }
        
        if animated {
            delay(animDelay) {[weak self] in
                updateConstraint()
                UIView.animateWithDuration(0.1) {
                    self?.layoutIfNeeded()
                    updateAlpha()
                }
            }
        } else {
            updateConstraint()
            updateAlpha()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        quantityLabelCenterVerticallyConstraint.constant = 0
        priceLabel.alpha = 0
        
        selectionStyle = UITableViewCellSelectionStyle.None

        // block tapping the cell behind the +/- buttons, otherwise it's easy to open the edit listitem view by mistake
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "onTapPlusMinusContainer:")
        plusMinusContainer.addGestureRecognizer(tapRecognizer)
    }
    
    func onTapPlusMinusContainer(recognizer: UITapGestureRecognizer) {
        // do nothing
    }
    
    @IBAction func onNoteTap(sender: UIButton) {
        if let tableViewListItem = tableViewListItem{
            delegate?.onNoteTap(tableViewListItem)
        } else {
            print("Warn: ListItemCell.onNoteTap: no tableViewListItem")
        }
    }
    
    // TODO when we tap on minus while the item is 0, the item is cleared - this was not intentional but turns to be the desired behaviour. Review why it's cleared
    // TODO! related with above - review that due to the way we manage the quantity of the items (item is shown when todo/done/stash quantity > 0) we don't keep listitems in the database which are never shown and thus can't be deleted.
    @IBAction func onMinusTap(sender: UIButton) {
        if let tableViewListItem = tableViewListItem{
            delegate?.onMinusTap(tableViewListItem)
        } else {
            print("Warn: ListItemCell.onMinusTap: no tableViewListItem")
        }
    }
    
    @IBAction func onPlusTap(sender: UIButton) {
        if let tableViewListItem = tableViewListItem{
            delegate?.onPlusTap(tableViewListItem)
        } else {
            print("Warn: ListItemCell.onPlusTap: no tableViewListItem")
        }
    }
    
    override func onStartItemSwipe() {
        if let tableViewListItem = tableViewListItem{
            delegate?.onStartItemSwipe(tableViewListItem)
        } else {
            print("Warn: ListItemCell.onStartItemSwipe: no tableViewListItem")
        }
    }
    
    override func onButtonTwoTap() {
        if let tableViewListItem = tableViewListItem{
            delegate?.onButtonTwoTap(tableViewListItem)
        } else {
            print("Warn: ListItemCell.onButtonTwoTap: no tableViewListItem")
        }
    }
    
    override func onItemSwiped() {
        if let tableViewListItem = tableViewListItem{
            delegate?.onItemSwiped(tableViewListItem)
        } else {
            print("Warn: ListItemCell.onItemSwiped: no tableViewListItem")
        }
    }
}

//
//  ProductCell.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol ListItemCellDelegate: class {
    func onItemSwiped(listItem: TableViewListItem)
    func onStartItemSwipe(listItem: TableViewListItem)
    func onButtonTwoTap(listItem: TableViewListItem)
    func onNoteTap(cell: ListItemCell, listItem: TableViewListItem)
    func onMinusTap(listItem: TableViewListItem)
    func onPlusTap(listItem: TableViewListItem)
    func onPanQuantityUpdate(tableViewListItem: TableViewListItem, newQuantity: Int)
}

class ListItemCell: SwipeableCell, SwipeToIncrementHelperDelegate {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var brandLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel! // this was a label below the item's quantity in edit mode howing total price for this item. For now disabled as it overlaps with surrounding +/- and maybe a bit too much information for the user.
    
    @IBOutlet weak var centerVerticallyNameLabelConstraint: NSLayoutConstraint!

    @IBOutlet weak var quantityLabelCenterVerticallyConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var noteButton: UIButton!

    @IBOutlet weak var sectionColorView: UIView!

    @IBOutlet weak var plusButton: UIView!
    @IBOutlet weak var minusButton: UIView!
    @IBOutlet weak var plusButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var minusButtonWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var undoLabel1: UILabel!
    @IBOutlet weak var undoLabel2: UILabel!
    
    @IBOutlet weak var minusTrailingConstraint: NSLayoutConstraint!
    
    private weak var delegate: ListItemCellDelegate?
    
    private var swipeToIncrementHelper: SwipeToIncrementHelper?
    
    private var shownQuantity: Int = 0 {
        didSet {
            if let tableViewListItem = tableViewListItem {
                quantityLabel.text = String("\(shownQuantity) \(tableViewListItem.listItem.product.unit.shortText)")
            }
        }
    }
    
    private(set) var status: ListItemStatus?
    var mode: ListItemCellMode = .Note {
        didSet {
            updateModeItemsVisibility(true)
            swipeToIncrementHelper?.enabled = mode == .Increment
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
                
                nameLabel.text = NSLocalizedString(listItem.product.product.name, comment: "")
                shownQuantity = listItem.quantity(status)
                
                centerVerticallyNameLabelConstraint.constant = listItem.product.product.brand.isEmpty ? 0 : 10
                brandLabel.text = listItem.product.product.brand
                
                sectionColorView.backgroundColor = listItem.section.color
                
                updateModeItemsVisibility(false)
                
                undoLabel1.text = listItem.product.product.name
                
                setOpen(tableViewListItem.swiped)
                if tableViewListItem.swiped {
                    backgroundColor = UIColor.clearColor()
                } else {
                    backgroundColor = UIColor.whiteColor()
                }
            }
        }
    }
    
    func update() {
        let tableViewListItem = self.tableViewListItem
        self.tableViewListItem = tableViewListItem
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
                plusButton.alpha = 0
                minusButton.alpha = 0
                sectionColorView.alpha = 1
            case .Increment:
                noteButton.alpha = 0
                plusButton.alpha = 1
                minusButton.alpha = 1
                sectionColorView.alpha = 0
            }
        }
        
        if animated {
            
            let constant: CGFloat = {
                switch mode {
                case .Note: return 0
                case .Increment: return 41
                }
            }()

            let minusConstant: CGFloat = {
                switch mode {
                case .Note: return DimensionsManager.leftRightPaddingConstraint
                case .Increment: return 0
                }
            }()
            
            delay(itemsDelay) {[weak self] in
                self?.plusButtonWidthConstraint.constant = constant
                self?.minusButtonWidthConstraint.constant = constant
                self?.minusTrailingConstraint.constant = minusConstant
                UIView.animateWithDuration(0.2) {
                    update()
                }
            }
            
        } else {
            update()
        }
        
//        showPrice(tableViewListItem, status: status, mode: mode, animated: animated, animDelay: priceDelay)
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
        
        undoLabel2.text = "Undo"
        
        selectionStyle = UITableViewCellSelectionStyle.None

        // When returning cell height programatically (which we need now in order to use different cell heights for different screen sizes), here it's still the height from the storyboard so we have to pass the offset for the line to eb draw at the bottom. Apparently there's no method where we get the cell with final height (did move to superview / window also still have the height from the storyboard)
        contentView.addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.defaultCellHeight)
        
//        // block tapping the cell behind the +/- buttons, otherwise it's easy to open the edit listitem view by mistake
//        let tapRecognizer = UITapGestureRecognizer(target: self, action: "onTapPlusMinusContainer:")
//        minusButton.addGestureRecognizer(tapRecognizer)

        swipeToIncrementHelper = SwipeToIncrementHelper(view: myContentView)
        swipeToIncrementHelper?.delegate = self
    }
    
    func onTapPlusMinusContainer(recognizer: UITapGestureRecognizer) {
        // do nothing
    }
    
    @IBAction func onNoteTap(sender: UIButton) {
        if let tableViewListItem = tableViewListItem{
            delegate?.onNoteTap(self, listItem: tableViewListItem)
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
    
    // MARK: - SwipeToIncrementHelperDelegate
    
    func currentQuantity() -> Int {
        return shownQuantity
    }
    
    func onQuantityUpdated(quantity: Int) {
        shownQuantity = quantity
    }
    
    func onFinishSwipe() {
        if let tableViewListItem = tableViewListItem {
            delegate?.onPanQuantityUpdate(tableViewListItem, newQuantity: shownQuantity)
        } else {
            QL3("Warn: ListItemCell.onStartItemSwipe: no tableViewListItem")
        }
    }
}

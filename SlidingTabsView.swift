//
//  SlidingTabsView.swift
//  shoppin
//
//  Created by ischuetz on 26/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers

protocol SlidingTabsViewDelegate: class {
    func onSlidingViewButtonTap(_ index: Int, button: UIButton)
}

class SlidingTabsView: UIView {

    fileprivate let lineHeight: CGFloat = 2
    fileprivate let lineColor: UIColor = Theme.lightGrey2
    fileprivate let selectedButtonColor: UIColor = UIColor.darkText
    fileprivate let unselectedButtonColor: UIColor = UIColor.gray
    fileprivate let lineBottomOffset: CGFloat = DimensionsManager.quickAddSlidingLineBottomOffset
    fileprivate let lineWidth: CGFloat = 70
    fileprivate let linePadding: CGFloat = DimensionsManager.quickAddSlidingLeftRightPadding
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    fileprivate var line: UIView?
    
    weak var delegate: SlidingTabsViewDelegate?
    
    var buttons: [UIButton] = []
    
    var onViewsReady: VoidFunction?
    
    fileprivate var addedViews: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    // the available space where the center of the line can be located such that the complete line is still in bounds (- lineWidth) and has given padding (-linePadding)
    fileprivate var availableWidthForCenter: CGFloat {
        return bounds.width - lineWidth - linePadding
    }

    // offset to edge such that available width is horizontally centered inside bounds
    fileprivate var availableWidthForCenterOffset: CGFloat {
        return (lineWidth / 2) + (linePadding / 2)
    }
    
    fileprivate func sharedInit() {
    }
    
    // percentage 0...1 of total width, to position the center of the line
    func moveLine(_ percentage: CGFloat) {
        if let line = line {
            let centerX = availableWidthForCenter * percentage // calculate location of center in available space
                + availableWidthForCenterOffset
            line.center = line.center.copy(x: centerX)
            setNeedsDisplay()
        } else {
            QL3("Trying to move line but is not initialised yet")
        }
    }
    
    
    // Called when the view frame is fully calculated. Apparently there's no reliable method for this inside this view? Tried with didMoveToSuperview() and didMoveToWindow() but in some situations they return a wrong frame width.
    func onFinishLayout() {
        
        if !addedViews { // it's possible that onFinishLayout() is called multiple times, e.g. if called from viewDidAppear, so we need a flag to not add the views again
            addedViews = true
            
            heightConstraint.constant = DimensionsManager.quickAddSlidingTabsViewHeight
            setNeedsLayout()
            layoutIfNeeded()
            
            addButtons()
            
            let line = UIView(frame: CGRect(x: 0, y: bounds.height - lineHeight - lineBottomOffset, width: lineWidth, height: lineHeight))
            line.backgroundColor = lineColor
            addSubview(line)
            self.line = line
            
            moveLine(0)
            
            onViewsReady?()
        }
    }
    
    // TODO generic!
    fileprivate func addButtons() {
        func createButton() -> HandlingButton {
            let button = HandlingButton()
            button.titleLabel?.font = DimensionsManager.font(.small, fontType: .regular)
            button.setTitleColor(unselectedButtonColor, for: UIControlState())
            return button
        }
        
        let centerY: CGFloat = bounds.height / 2
        
        let centerXButton1 = availableWidthForCenterOffset
        
        let button1 = createButton()
        button1.setTitle(trans("quick_add_slider_tab_products"), for: UIControlState())
        button1.tapHandler = {[weak self] in
            self?.delegate?.onSlidingViewButtonTap(0, button: button1)
        }
        addSubview(button1)
        button1.sizeToFit()
        button1.center = CGPoint(x: centerXButton1, y: centerY)
        buttons.append(button1)
        
        let centerXButton2 = bounds.width - availableWidthForCenterOffset
        
        let button2 = createButton()
        button2.setTitle(trans("quick_add_slider_tab_recipes"), for: UIControlState())
        button2.tapHandler = {[weak self] in
            self?.delegate?.onSlidingViewButtonTap(1, button: button2)
        }
        addSubview(button2)
        button2.sizeToFit()
        button2.center = CGPoint(x: centerXButton2, y: centerY)
        buttons.append(button2)
    }
    
    func setSelected(_ buttonIndex: Int) {
        if let button = buttons[safe: buttonIndex] {
            for b in buttons {
                b.setTitleColor(unselectedButtonColor, for: UIControlState())
            }
            button.setTitleColor(selectedButtonColor, for: UIControlState())
        } else {
            QL3("Button not found: \(buttonIndex)")
        }
    }
}

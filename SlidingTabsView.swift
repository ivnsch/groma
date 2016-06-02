//
//  SlidingTabsView.swift
//  shoppin
//
//  Created by ischuetz on 26/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol SlidingTabsViewDelegate: class {
    func onSlidingViewButtonTap(index: Int, button: UIButton)
}

class SlidingTabsView: UIView {

    private let lineHeight: CGFloat = 2
    private let lineColor: UIColor = Theme.lightGrey2
    private let selectedButtonColor: UIColor = UIColor.darkTextColor()
    private let unselectedButtonColor: UIColor = UIColor.grayColor()
    private let lineBottomOffset: CGFloat = DimensionsManager.quickAddSlidingLineBottomOffset
    private let lineWidth: CGFloat = 70
    private let linePadding: CGFloat = DimensionsManager.quickAddSlidingLeftRightPadding
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    private var line: UIView?
    
    weak var delegate: SlidingTabsViewDelegate?
    
    var buttons: [UIButton] = []
    
    var onViewsReady: VoidFunction?
    
    private var addedViews: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    // the available space where the center of the line can be located such that the complete line is still in bounds (- lineWidth) and has given padding (-linePadding)
    private var availableWidthForCenter: CGFloat {
        return bounds.width - lineWidth - linePadding
    }

    // offset to edge such that available width is horizontally centered inside bounds
    private var availableWidthForCenterOffset: CGFloat {
        return (lineWidth / 2) + (linePadding / 2)
    }
    
    private func sharedInit() {
    }
    
    // percentage 0...1 of total width, to position the center of the line
    func moveLine(percentage: CGFloat) {
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
            
            let line = UIView(frame: CGRectMake(0, bounds.height - lineHeight - lineBottomOffset, lineWidth, lineHeight))
            line.backgroundColor = lineColor
            addSubview(line)
            self.line = line
            
            moveLine(0)
            
            onViewsReady?()
        }
    }
    
    // TODO generic!
    private func addButtons() {
        func createButton() -> HandlingButton {
            let button = HandlingButton()
            button.titleLabel?.font = DimensionsManager.font(.Small, fontType: .Regular)
            button.setTitleColor(unselectedButtonColor, forState: .Normal)
            return button
        }
        
        let centerY: CGFloat = bounds.height / 2
        
        let centerXButton1 = availableWidthForCenterOffset
        
        let button1 = createButton()
        button1.setTitle(trans("quick_add_slider_tab_products"), forState: .Normal)
        button1.tapHandler = {[weak self] in
            self?.delegate?.onSlidingViewButtonTap(0, button: button1)
        }
        addSubview(button1)
        button1.sizeToFit()
        button1.center = CGPointMake(centerXButton1, centerY)
        buttons.append(button1)
        
        let centerXButton2 = bounds.width - availableWidthForCenterOffset
        
        let button2 = createButton()
        button2.setTitle(trans("quick_add_slider_tab_groups"), forState: .Normal)
        button2.tapHandler = {[weak self] in
            self?.delegate?.onSlidingViewButtonTap(1, button: button2)
        }
        addSubview(button2)
        button2.sizeToFit()
        button2.center = CGPointMake(centerXButton2, centerY)
        buttons.append(button2)
    }
    
    func setSelected(buttonIndex: Int) {
        if let button = buttons[safe: buttonIndex] {
            for b in buttons {
                b.setTitleColor(unselectedButtonColor, forState: .Normal)
            }
            button.setTitleColor(selectedButtonColor, forState: .Normal)
        } else {
            QL3("Button not found: \(buttonIndex)")
        }
    }
}
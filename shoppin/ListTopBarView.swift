//
//  ListTopBarView.swift
//  shoppin
//
//  Created by ischuetz on 17/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol ListTopBarViewDelegate: class {
    func onTopBarButtonTap(buttonId: ListTopBarViewButtonId)
    func onTopBarTitleTap()
    func onTopBarBackButtonTap()
    
    // parameter: center => center, !center => left
    func onCenterTitleAnimComplete(center: Bool)
}

enum ListTopBarViewButtonId: Int {
    case Add = 0, Submit = 1, ToggleOpen = 2, Edit = 3
    
    var name: String {
        switch self {
        case .Add:
            return "add"
        case .Submit:
            return "submit"
        case .ToggleOpen:
            return "toggle"
        case .Edit:
            return "edit"
        }
    }
}

struct TopBarButtonModel {
    let buttonId: ListTopBarViewButtonId
    let initTransform: CGAffineTransform?
    let endTransform: CGAffineTransform?
    
    init(buttonId: ListTopBarViewButtonId, initTransform: CGAffineTransform? = nil, endTransform: CGAffineTransform? = nil) {
        self.buttonId = buttonId
        self.initTransform = initTransform
        self.endTransform = endTransform
    }
}

class ListTopBarView: UIView {

    // Min space to left and right of title view to edges of parent view. For now hardcoded, note also that this assumes only 1 button at the left and right
    private let titleMinLeftRightMargin: CGFloat = 60
    
    private var backButton: UIButton?
    var backButtonText: String?
    private var leftButtons: [UIButton] = []
    private var rightButtons: [UIButton] = []
    private var titleLabel: UILabel = UILabel()
    
    var titleLabelColor = UIColor.blackColor() {
        didSet {
            titleLabel.textColor = titleLabelColor
        }
    }
    
    weak var delegate: ListTopBarViewDelegate?
    
    var fgColor: UIColor = UIColor.blackColor() {
        didSet {
            backButton?.setTitleColor(fgColor, forState: .Normal)
            for button in leftButtons {
                button.imageView?.tintColor = fgColor
            }
            for button in rightButtons {
                button.imageView?.tintColor = fgColor
            }
            titleLabel.textColor = fgColor
        }
    }
    
    private var titleLabelLeftConstraint: NSLayoutConstraint?
    private var titleLabelWidthConstraint: NSLayoutConstraint?
    private var titleLabelCentered = false
    private let titleLabelLeftConstant: Float = Float(DimensionsManager.leftRightPaddingConstraint)
    
    private var titleLabelCenterYContraint: NSLayoutConstraint?
    
    private var bgColorLayer: CAShapeLayer?
    
    var dotColor: UIColor? {
        didSet {
            self.bgColorLayer?.fillColor = dotColor?.CGColor
        }
    }
    
    private var centerYInExpandedState: Float = 0
    private var centerYOffsetInExpandedState: Float = 0 // offset of center of available height to center of total height, derived from centerYInExpandedState
    
    private var titleLabelFont = Fonts.fontForSizeCategory(50)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false
        
        backgroundColor = Theme.navigationBarBackgroundColor
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let statusBarHeight: Float = 20
        let totalHeight: Float = 64
        let availableHeight: Float = totalHeight - statusBarHeight
        centerYInExpandedState = statusBarHeight + (availableHeight / 2)
        centerYOffsetInExpandedState = centerYInExpandedState - (totalHeight / 2)
        
        titleLabel.font = titleLabelFont
//        titleLabel.adjustsFontSizeToFitWidth = true
        addSubview(titleLabel)
        titleLabelLeftConstraint = titleLabel.alignLeft(self, constant: titleLabelLeftConstant)
        
        titleLabelCenterYContraint = titleLabel.centerYInParent()
        layoutIfNeeded()
        
        addTitleButton()
        
// to debug center y
//        let centerYLine = UIView()
//        centerYLine.translatesAutoresizingMaskIntoConstraints = false
//        centerYLine.backgroundColor = UIColor.redColor()
//        addSubview(centerYLine)
//        centerYLine.fillSuperviewWidth()
//        centerYLine.heightConstraint(1)
//        centerYLine.centerYInParent(centerYOffsetInExpandedState)
        
        
//        let hairline = UIImageView()
//        hairline.translatesAutoresizingMaskIntoConstraints = false
//        hairline.backgroundColor = UIColor.lightGrayColor()
//        addSubview(hairline)
//        hairline.fillSuperviewWidth()
//        hairline.heightConstraint(0.5)
//        hairline.alignBottom(self, constant: 0)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = self.bounds
        self.bgColorLayer = shapeLayer
        layer.insertSublayer(shapeLayer, atIndex: 0)
    }
    
    var title: String = "" {
        didSet {
            titleLabel.text = title
            titleLabel.sizeToFit()
        }
    }
    
    private func generateCirclePath() -> UIBezierPath? {
        
        guard let titleTextSize = titleLabel.text?.size(titleLabelFont) else {return nil}

        let circleDiam: CGFloat = 12
        let cornerRadius = circleDiam / 2
        let x = frame.width / 2 + (titleTextSize.width / 2) + 8
        let xMax = min(x, bounds.width - titleMinLeftRightMargin)
        let y = CGFloat(centerYInExpandedState) - (circleDiam / 2)
        
        let circlePath = UIBezierPath(roundedRect: CGRectMake(xMax, y, circleDiam, circleDiam), byRoundingCorners: UIRectCorner.AllCorners, cornerRadii: CGSizeMake(cornerRadius, cornerRadius))
        //        circlePath.closePath()
        return circlePath
    }
    
    func showDot() {
        guard let circlePath = generateCirclePath() else {QL3("No circle path"); return }
        bgColorLayer?.path = circlePath.CGPath
    }
    
    // parameter: toDot: true: rect -> dot, false: dot -> rect
    func animateRectDot(toDot: Bool, duration: CFTimeInterval) {
        
        guard let circlePath = generateCirclePath() else {QL3("No circle path"); return }

        let rectPath = UIBezierPath(roundedRect: CGRectInset(self.bounds, -10, -10), byRoundingCorners: UIRectCorner.AllCorners, cornerRadii: CGSizeMake(5, 5))
        
        if duration > 0 {
            let animationKey = "path"
            
            let pathAnimation = CABasicAnimation(keyPath: animationKey)
            pathAnimation.duration = duration
            pathAnimation.fromValue = toDot ? rectPath.CGPath : circlePath.CGPath
            
            // Disable implicit animation
            CATransaction.disableActions()
            
            pathAnimation.toValue = toDot ? circlePath.CGPath : rectPath.CGPath
            bgColorLayer?.addAnimation(pathAnimation, forKey: animationKey)
        }
        
        bgColorLayer?.path = toDot ? circlePath.CGPath : rectPath.CGPath
    }
    
    // parameter: center => center, !center => left
    // TODO rename maybe "setState(open)" or something, this is not only animating the label now but also the background and the height
    func positionTitleLabelLeft(center: Bool, animated: Bool, withDot: Bool, heightConstraint: NSLayoutConstraint? = nil) {
        
        if let heightConstraint = heightConstraint {
            // The cell and topbar have different heights so we hav to animate this too. Sometimes the topbar is used without animation (e.g. top bar from lists/inventories/groups controller - in this case heightConstraint is nil)
            heightConstraint.constant = center ? DimensionsManager.defaultCellHeight : 64
            layoutIfNeeded()
            heightConstraint.constant = center ? 64 : DimensionsManager.defaultCellHeight
        }
        
        titleLabelLeftConstraint?.constant = center ? self.center.x - titleLabel.frame.width / 2 : CGFloat(titleLabelLeftConstant)
        titleLabelCenterYContraint?.constant = center ? 10 : 0
        
        titleLabelWidthConstraint = titleLabel.widthLessThanConstraint(bounds.width - (titleMinLeftRightMargin * 2))
        
        if animated {
            UIView.animateWithDuration(0.3, animations: {[weak self] in
                self?.layoutIfNeeded()
                }) {[weak self] finished in
                    self?.delegate?.onCenterTitleAnimComplete(center)
            }
            
            if withDot {
                animateRectDot(center, duration: 0.3)
            }

        } else {
            
            if withDot && center { // we want to show the dot when the view is in expanded (label=center) state
                showDot()
            }
            layoutIfNeeded()
            delegate?.onCenterTitleAnimComplete(center)
        }
    }
    
    private func addTitleButton() {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        button.fillSuperviewHeight()
        button.fillSuperviewWidth(70, rightConstant: -70)
        button.addTarget(self, action: #selector(ListTopBarView.onTitleTap(_:)), forControlEvents: .TouchUpInside)
    }
    
    /**
    * NOTE call this before setButtonModels! setButtonModels needs that the (possible) back button is initialised to calculate the offset of the buttons on the left side
    */
    func setBackVisible(visible: Bool) {
        if visible {
            if backButton == nil { // don't add again if called multiple times with visible == true
                let button = UIButton()
                button.translatesAutoresizingMaskIntoConstraints = false
                button.imageView?.tintColor = fgColor
                button.setImage(UIImage(named: "tb_back"), forState: .Normal)
                backButton = button
                addSubview(button)
                
                let backLabel = UIButton()
                backLabel.translatesAutoresizingMaskIntoConstraints = false
                backLabel.setTitle(backButtonText ?? "", forState: .Normal)
                backLabel.titleLabel?.font = Fonts.fontForSizeCategory(50)
                backLabel.setTitleColor(fgColor, forState: .Normal)
                addSubview(backLabel)

                let viewDictionary = ["back": button, "backLabel": backLabel]
                
                let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-(6)-[back]-(4)-[backLabel]", options: [], metrics: nil, views: viewDictionary)
                
                button.centerYInParent(centerYOffsetInExpandedState)
                backLabel.centerYInParent(centerYOffsetInExpandedState)

                addConstraints(hConstraints)

                button.addTarget(self, action: #selector(ListTopBarView.onBackTap(_:)), forControlEvents: .TouchUpInside)
                backLabel.addTarget(self, action: #selector(ListTopBarView.onBackTap(_:)), forControlEvents: .TouchUpInside)
            }

        } else {
            backButton?.removeFromSuperview()
            backButton = nil
        }
        
        layoutIfNeeded()
    }
    
    func rightButton(identifier: ListTopBarViewButtonId) -> UIButton? {
        return rightButtons.findFirst({$0.tag == identifier.rawValue})
    }

    private func setButtonModels(models: [TopBarButtonModel], left: Bool) {

        if left {
            for button in leftButtons {
                button.removeFromSuperview()
            }
            leftButtons = []
            
        } else {
            for button in rightButtons {
                button.removeFromSuperview()
            }
            rightButtons = []
        }
        
        if !models.isEmpty {

            var modelsWithButtons: [(model: TopBarButtonModel, button: UIButton, inner: UIButton)] = []
            
            func createButton(model: TopBarButtonModel, imgName: String, tintColor: UIColor) -> UIButton {
                let button = UIButton()
                button.translatesAutoresizingMaskIntoConstraints = false
                button.imageView?.tintColor = tintColor
                
                button.setImage(UIImage(named: imgName), forState: .Normal)
                if left {
                    leftButtons.append(button)
                } else {
                    rightButtons.append(button)
                }
                
                button.tag = model.buttonId.rawValue
                
                button.userInteractionEnabled = false
                
                let tapView = UIButton()
                tapView.translatesAutoresizingMaskIntoConstraints = false
                tapView.tag = model.buttonId.rawValue
//                QL1("model.buttonId: \(model.buttonId), tag: \(tapView.tag)")
                tapView.addSubview(button)

                button.centerYInParent(centerYOffsetInExpandedState)
                button.centerXInParent()

                modelsWithButtons.append((model: model, button: tapView, inner: button))
                tapView.addTarget(self, action: "onActionButtonTap:", forControlEvents: .TouchUpInside)
                return button
            }
            
            
            for model in models {
                switch model.buttonId {
                case .Edit:
                    createButton(model, imgName: "tb_edit", tintColor: fgColor)
                case .Add:
                    createButton(model, imgName: "tb_add", tintColor: fgColor)
                case .Submit:
                    createButton(model, imgName: "tb_done", tintColor: fgColor)
                case .ToggleOpen:
                    createButton(model, imgName: "tb_add", tintColor: Theme.navBarAddColor)
                }
            }
            
            var viewsOrderedDictionary = OrderedDictionary<String, UIView>()
            
            // add subviews and apply possible transform - and fill view dictionary with constraints in same iteration
            for modelWithButton in modelsWithButtons {
                addSubview(modelWithButton.button)
                if let initTransform = modelWithButton.model.initTransform {
                    modelWithButton.inner.transform = initTransform
                }
                if let endTransform = modelWithButton.model.endTransform {
                    UIView.animateWithDuration(0.3) {
                        modelWithButton.inner.transform = endTransform
                    }
                }

                // TODO when button is at the same position as in a previous state it will re-grow which looks weird so we need a check if there's a button with same id at same index then don't do animation
//                // if there are no specific transforms, apply default (grow animation)
//                if modelWithButton.model.initTransform == nil && modelWithButton.model.endTransform == nil {
//                    modelWithButton.button.transform = CGAffineTransformMakeScale(0.001, 0.001) // 0.001 because 0 sometimes causes bugs with transform (iOS problem)
//                    UIView.animateWithDuration(0.3) {
//                        modelWithButton.button.transform = CGAffineTransformMakeScale(1, 1)
//                    }
//                }
                
                viewsOrderedDictionary[modelWithButton.model.buttonId.name] = modelWithButton.button
                
            }
            
            let viewsDictionary = viewsOrderedDictionary.toDictionary()
            
            let hSpace: CGFloat = 10
            let leadingHSpace = backButton == nil ? hSpace : hSpace + backButton!.frame.width + hSpace
            var hConstraintStr: String = left ? "H:|-(\(leadingHSpace))-" : "H:"
            for (index, entry) in viewsOrderedDictionary.enumerate() {
                var str = "\(hConstraintStr)[\(entry.0)]"
                if index < viewsOrderedDictionary.count - 1 {
                    str += "-\(hSpace)-"
                }
                hConstraintStr = str
            }
            hConstraintStr = left ? hConstraintStr : "\(hConstraintStr)-\(hSpace)-|"
            let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat(hConstraintStr, options: [], metrics: nil, views: viewsDictionary)
            addConstraints(hConstraints)
            
            for vConstraintStr in viewsOrderedDictionary.keys {
                let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[\(vConstraintStr)]|", options: [], metrics: nil, views: viewsDictionary)
                addConstraints(vConstraints)
            }
        }

        
        layoutIfNeeded()
    }
    
    // parameter left: true => left, false => right
    private func setButtonIds(buttonIds: [ListTopBarViewButtonId], left: Bool) {
        let models = buttonIds.map {TopBarButtonModel(buttonId: $0)}
        setButtonModels(models, left: left)
    }
    
    func setLeftButtonModels(models: [TopBarButtonModel]) {
        setButtonModels(models, left: true)
    }

    func setRightButtonModels(models: [TopBarButtonModel]) {
        setButtonModels(models, left: false)
    }
    
    func setLeftButtonIds(buttonIds: [ListTopBarViewButtonId]) {
        setButtonIds(buttonIds, left: true)
    }
    
    func setRightButtonIds(buttonIds: [ListTopBarViewButtonId]) {
        setButtonIds(buttonIds, left: false)
    }
    
    func onTitleTap(sender: UIButton) {
        delegate?.onTopBarTitleTap()
    }
    
    func onActionButtonTap(sender: UIButton) {
        if let buttonId = ListTopBarViewButtonId(rawValue: sender.tag) {
            delegate?.onTopBarButtonTap(buttonId)
        } else {
            print("Error: ListTopBarView.onActionButtonTap: no ListTopBarViewButtonId for tag: \(sender.tag)")
        }
    }
    
    func onBackTap(sender: UIButton) {
        delegate?.onTopBarBackButtonTap()
    }
}
//
//  ListTopBarView.swift
//  shoppin
//
//  Created by ischuetz on 17/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

protocol ListTopBarViewDelegate: class {
    func onTopBarButtonTap(_ buttonId: ListTopBarViewButtonId)
    func onTopBarTitleTap()
    func onTopBarBackButtonTap()
    
    // parameter: center => center, !center => left
    func onCenterTitleAnimComplete(_ center: Bool)
}

enum ListTopBarViewButtonId: Int {
    case add = 0, submit = 1, toggleOpen = 2, edit = 3, expandSections = 4
    
    var name: String {
        switch self {
        case .add:
            return "add"
        case .submit:
            return "submit"
        case .toggleOpen:
            return "toggle"
        case .edit:
            return "edit"
        case .expandSections:
            return "expandSections"
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
    fileprivate let titleMinLeftRightMargin: CGFloat = 60
    
    fileprivate var backButton: UIButton?
    var backButtonText: String?
    fileprivate var leftButtons: [UIButton] = []
    fileprivate var rightButtons: [UIButton] = []
    fileprivate var titleLabel: UILabel = UILabel()
    
    var titleLabelColor = UIColor.black {
        didSet {
            titleLabel.textColor = titleLabelColor
        }
    }
    
    weak var delegate: ListTopBarViewDelegate?
    
    var fgColor: UIColor = UIColor.black {
        didSet {
            backButton?.setTitleColor(fgColor, for: UIControlState())
            for button in leftButtons {
                button.imageView?.tintColor = fgColor
            }
            for button in rightButtons {
                button.imageView?.tintColor = fgColor
            }
            titleLabel.textColor = fgColor
        }
    }
    
    fileprivate var titleLabelLeftConstraint: NSLayoutConstraint?
    fileprivate var titleLabelWidthConstraint: NSLayoutConstraint?
    fileprivate var titleLabelCentered = false
    fileprivate let titleLabelLeftConstant: Float = Float(DimensionsManager.leftRightPaddingConstraint)
    
    fileprivate var titleLabelCenterYContraint: NSLayoutConstraint?
    fileprivate var titleLabelCenterYContraintOffset: CGFloat = 0

    fileprivate var bgColorLayer: CAShapeLayer?
    
    var dotColor: UIColor? {
        didSet {
            self.bgColorLayer?.fillColor = dotColor?.cgColor
        }
    }
    
    fileprivate var centerYInExpandedState: Float = 0
    fileprivate var centerYOffsetInExpandedState: Float = 0 // offset of center of available height to center of total height, derived from centerYInExpandedState
    
    fileprivate var titleLabelFont = Fonts.fontForSizeCategory(50)

    // hack - TODO remove this - generic way to update state of buttons
    var expandSectionButton: ExpandCollapseButton?

    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false
        
        backgroundColor = Theme.navigationBarBackgroundColor
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let hasNotch = Theme.navBarHeight == Theme.notchNavBarHeight
        let statusBarHeight: Float = hasNotch ? Float(Theme.notchHeight) : 20
        let totalHeight: Float = Float(Theme.navBarHeight)
        let availableHeight: Float = totalHeight - statusBarHeight
        centerYInExpandedState = statusBarHeight + (availableHeight / 2)

        titleLabelCenterYContraintOffset = hasNotch ? 21.5 : 10
        centerYOffsetInExpandedState = Float(titleLabelCenterYContraintOffset)
        titleLabel.font = titleLabelFont
//        titleLabel.adjustsFontSizeToFitWidth = true
        addSubview(titleLabel)
        titleLabelLeftConstraint = titleLabel.alignLeft(self, constant: titleLabelLeftConstant)

        titleLabelCenterYContraint = titleLabel.centerYInParent(Float(titleLabelCenterYContraintOffset))
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
        layer.insertSublayer(shapeLayer, at: 0)
    }
    
    var title: String = "" {
        didSet {
            titleLabel.text = title
            titleLabel.sizeToFit()
        }
    }
    
    fileprivate func generateCirclePath() -> UIBezierPath? {
        
        guard let titleTextSize = titleLabel.text?.size(titleLabelFont) else {return nil}

        let circleDiam: CGFloat = 12
        let cornerRadius = circleDiam / 2
        let x = frame.width / 2 + (titleTextSize.width / 2) + 8
        let xMax = min(x, bounds.width - titleMinLeftRightMargin)
        let y = CGFloat(centerYInExpandedState) - (circleDiam / 2)
        
        let circlePath = UIBezierPath(roundedRect: CGRect(x: xMax, y: y, width: circleDiam, height: circleDiam), byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        //        circlePath.closePath()
        return circlePath
    }
    
    func showDot() {
        guard let circlePath = generateCirclePath() else {logger.w("No circle path"); return }
        bgColorLayer?.path = circlePath.cgPath
    }
    
    // parameter: toDot: true: rect -> dot, false: dot -> rect
    func animateRectDot(_ toDot: Bool, duration: CFTimeInterval) {
        
        guard let circlePath = generateCirclePath() else {logger.w("No circle path"); return }

        let rectPath = UIBezierPath(roundedRect: self.bounds.insetBy(dx: -10, dy: -10), byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: 5, height: 5))
        
        if duration > 0 {
            let animationKey = "path"
            
            let pathAnimation = CABasicAnimation(keyPath: animationKey)
            pathAnimation.duration = duration
            pathAnimation.fromValue = toDot ? rectPath.cgPath : circlePath.cgPath
            
            // Disable implicit animation
            CATransaction.disableActions()
            
            pathAnimation.toValue = toDot ? circlePath.cgPath : rectPath.cgPath
            bgColorLayer?.add(pathAnimation, forKey: animationKey)
        }
        
        bgColorLayer?.path = toDot ? circlePath.cgPath : rectPath.cgPath
    }
    
    // parameter: center => center, !center => left
    // TODO rename maybe "setState(open)" or something, this is not only animating the label now but also the background and the height
    func positionTitleLabelLeft(_ center: Bool, animated: Bool, withDot: Bool, heightConstraint: NSLayoutConstraint? = nil) {
        
        if let heightConstraint = heightConstraint {
            // The cell and topbar have different heights so we hav to animate this too. Sometimes the topbar is used without animation (e.g. top bar from lists/inventories/groups controller - in this case heightConstraint is nil)
            heightConstraint.constant = center ? Theme.navBarHeight : DimensionsManager.defaultCellHeight
        }

        superview?.layoutIfNeeded()
        
        titleLabelLeftConstraint?.constant = center ? self.width / 2 - titleLabel.frame.width / 2 : CGFloat(titleLabelLeftConstant)
        titleLabelCenterYContraint?.constant = center ? titleLabelCenterYContraintOffset : 0

        titleLabelWidthConstraint = titleLabel.widthLessThanConstraint(bounds.width - (titleMinLeftRightMargin * 2))
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: {[weak self] in
                self?.layoutIfNeeded()
                }, completion: {[weak self] finished in
                    self?.delegate?.onCenterTitleAnimComplete(center)
            }) 
            
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
    
    fileprivate func addTitleButton() {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        button.fillSuperviewHeight()
        button.fillSuperviewWidth(70, rightConstant: -70)
        button.addTarget(self, action: #selector(ListTopBarView.onTitleTap(_:)), for: .touchUpInside)
    }
    
    /**
    * NOTE call this before setButtonModels! setButtonModels needs that the (possible) back button is initialised to calculate the offset of the buttons on the left side
    */
    func setBackVisible(_ visible: Bool) {
        if visible {
            if backButton == nil { // don't add again if called multiple times with visible == true
                let button = UIButton()
                button.translatesAutoresizingMaskIntoConstraints = false
                button.imageView?.tintColor = fgColor
                button.setImage(UIImage(named: "tb_back"), for: UIControlState())
                backButton = button
                addSubview(button)
                
                let backLabel = UIButton()
                backLabel.translatesAutoresizingMaskIntoConstraints = false
                backLabel.setTitle(backButtonText ?? "", for: UIControlState())
                backLabel.titleLabel?.font = Fonts.fontForSizeCategory(50)
                backLabel.setTitleColor(fgColor, for: UIControlState())
                addSubview(backLabel)

                let viewDictionary = ["back": button, "backLabel": backLabel]
                
                let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(6)-[back]-(4)-[backLabel]", options: [], metrics: nil, views: viewDictionary)
                
                _ = button.centerYInParent(centerYOffsetInExpandedState)
                _ = backLabel.centerYInParent(centerYOffsetInExpandedState)

                addConstraints(hConstraints)

                button.addTarget(self, action: #selector(ListTopBarView.onBackTap(_:)), for: .touchUpInside)
                backLabel.addTarget(self, action: #selector(ListTopBarView.onBackTap(_:)), for: .touchUpInside)
            }

        } else {
            backButton?.removeFromSuperview()
            backButton = nil
        }
        
        layoutIfNeeded()
    }
    
    func rightButton(_ identifier: ListTopBarViewButtonId) -> UIButton? {
        return rightButtons.findFirst({$0.tag == identifier.rawValue})
    }

    fileprivate func setButtonModels(_ models: [TopBarButtonModel], left: Bool) {

        if left {
            for button in leftButtons {
                button.removeFromSuperview()
                expandSectionButton = nil
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
            
            func createButton(_ model: TopBarButtonModel, imgName: String, tintColor: UIColor) -> UIButton {

                var button: UIButton
                if model.buttonId == .expandSections {
                    let expandCollapseButton = ExpandCollapseButton()
                    button = expandCollapseButton
                    expandSectionButton = expandCollapseButton // note: hack - see comment on variable

                } else {
                    button = UIButton()
                    button.imageView?.tintColor = tintColor
                    button.setImage(UIImage(named: imgName), for: UIControlState())
                }

                button.translatesAutoresizingMaskIntoConstraints = false
                button.tag = model.buttonId.rawValue
                button.isUserInteractionEnabled = false
                
                let tapView = UIButton()
                tapView.translatesAutoresizingMaskIntoConstraints = false
                tapView.tag = model.buttonId.rawValue
//                logger.v("model.buttonId: \(model.buttonId), tag: \(tapView.tag)")
                tapView.addSubview(button)
                tapView.accessibilityIdentifier = model.buttonId.name
                if left {
                    leftButtons.append(tapView)
                } else {
                    rightButtons.append(tapView)
                }

                _ = button.centerYInParent(centerYOffsetInExpandedState)
                _ = button.centerXInParent()

                modelsWithButtons.append((model: model, button: tapView, inner: button))
                tapView.addTarget(self, action: #selector(ListTopBarView.onActionButtonTap(_:)), for: .touchUpInside)
                return button
            }
            
            
            for model in models {
                switch model.buttonId {
                case .edit:
                    _ = createButton(model, imgName: "tb_edit", tintColor: fgColor)
                case .add:
                    _ = createButton(model, imgName: "tb_add", tintColor: fgColor)
                case .submit:
                    _ = createButton(model, imgName: "tb_done", tintColor: fgColor)
                case .toggleOpen:
                    _ = createButton(model, imgName: "tb_add", tintColor: Theme.navBarAddColor)
                case .expandSections:
                    // TODO don't pass imgName and tintColor here
                    _ = createButton(model, imgName: "", tintColor: Theme.navBarAddColor)
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
                    UIView.animate(withDuration: 0.3, animations: {
                        modelWithButton.inner.transform = endTransform
                    }) 
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
            for (index, entry) in viewsOrderedDictionary.enumerated() {
                var str = "\(hConstraintStr)[\(entry.0)]"
                if index < viewsOrderedDictionary.count - 1 {
                    str += "-\(hSpace)-"
                }
                hConstraintStr = str
            }
            hConstraintStr = left ? hConstraintStr : "\(hConstraintStr)-\(hSpace)-|"
            let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: hConstraintStr, options: [], metrics: nil, views: viewsDictionary)
            addConstraints(hConstraints)
            
            for vConstraintStr in viewsOrderedDictionary.keys {
                let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[\(vConstraintStr)]|", options: [], metrics: nil, views: viewsDictionary)
                addConstraints(vConstraints)
            }
        }

        
        layoutIfNeeded()
    }
    
    // parameter left: true => left, false => right
    fileprivate func setButtonIds(_ buttonIds: [ListTopBarViewButtonId], left: Bool) {
        let models = buttonIds.map {TopBarButtonModel(buttonId: $0)}
        setButtonModels(models, left: left)
    }
    
    func setLeftButtonModels(_ models: [TopBarButtonModel]) {
        setButtonModels(models, left: true)
    }

    func setRightButtonModels(_ models: [TopBarButtonModel]) {
        setButtonModels(models, left: false)
    }
    
    func setLeftButtonIds(_ buttonIds: [ListTopBarViewButtonId]) {
        setButtonIds(buttonIds, left: true)
    }
    
    func setRightButtonIds(_ buttonIds: [ListTopBarViewButtonId]) {
        setButtonIds(buttonIds, left: false)
    }
    
    @objc func onTitleTap(_ sender: UIButton) {
        delegate?.onTopBarTitleTap()
    }
    
    @objc func onActionButtonTap(_ sender: UIButton) {
        if let buttonId = ListTopBarViewButtonId(rawValue: sender.tag) {
            delegate?.onTopBarButtonTap(buttonId)
        } else {
            print("Error: ListTopBarView.onActionButtonTap: no ListTopBarViewButtonId for tag: \(sender.tag)")
        }
    }
    
    @objc func onBackTap(_ sender: UIButton) {
        delegate?.onTopBarBackButtonTap()
    }
}

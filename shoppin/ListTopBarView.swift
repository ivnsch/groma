//
//  ListTopBarView.swift
//  shoppin
//
//  Created by ischuetz on 17/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol ListTopBarViewDelegate {
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
    
    var delegate: ListTopBarViewDelegate?
    
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
    private var titleLabelCentered = false
    private let titleLabelLeftConstant: Float = 14
    
    private let startTopConstant: Float = 27
    private let topConstant: Float = 32
    
    private var titleLabelTopConstraint: NSLayoutConstraint?
    
    
    private var bgColorLayer: CAShapeLayer?
    
    var dotColor: UIColor? {
        didSet {
            self.bgColorLayer?.fillColor = dotColor?.CGColor
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false
        
        backgroundColor = Theme.navigationBarBackgroundColor
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = Fonts.regular
        addSubview(titleLabel)
        titleLabelLeftConstraint = titleLabel.alignLeft(self, constant: titleLabelLeftConstant)

        // FIXME for some reason this makes the label move the y center during the animation - it should stay constant. alignTop (quickfix) stays constant
//        titleLabel.centerYInParent()
        titleLabelTopConstraint = titleLabel.alignTop(self, constant: startTopConstant)
        
        layoutIfNeeded()
        
        addTitleButton()
        
        let hairline = UIImageView()
        hairline.translatesAutoresizingMaskIntoConstraints = false
        hairline.backgroundColor = UIColor.lightGrayColor()
        addSubview(hairline)
        hairline.fillSuperviewWidth()
        hairline.heightConstraint(0.5)
        hairline.alignBottom(self, constant: 0)
        
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
    
    func animateDot(expanding: Bool, duration: CFTimeInterval = 0.3) {
        
        guard let titleTextSize = titleLabel.text?.size(Fonts.regular) else {return}
        
        let rectPath = UIBezierPath(roundedRect: CGRectInset(self.bounds, -10, -10), byRoundingCorners: UIRectCorner.AllCorners, cornerRadii: CGSizeMake(5, 5))
        
        let circleDiam: CGFloat = 12
        let cornerRadius = circleDiam / 2
        let x = frame.width / 2 + (titleTextSize.width / 2) + 8
        let y = titleTopConstant(expanding) + (titleTextSize.height / 2) - (circleDiam / 2)
        
        let circlePath = UIBezierPath(roundedRect: CGRectMake(x, y, circleDiam, circleDiam), byRoundingCorners: UIRectCorner.AllCorners, cornerRadii: CGSizeMake(cornerRadius, cornerRadius))
        circlePath.closePath()
        
        let animationKey = "path"
        
        CATransaction.begin()
        let pathAnimation = CABasicAnimation(keyPath: animationKey)
        pathAnimation.duration = duration
        pathAnimation.fillMode = kCAFillModeForwards
        pathAnimation.removedOnCompletion = false
        pathAnimation.fromValue = expanding ? rectPath.CGPath : circlePath.CGPath
        pathAnimation.toValue = expanding ? circlePath.CGPath : rectPath.CGPath
        
        CATransaction.setCompletionBlock {[weak self] in
            self?.bgColorLayer?.path = expanding ? circlePath.CGPath : rectPath.CGPath
            self?.setNeedsDisplay()
            // remove the animation manually, after it's completed, otherwise there's flickering (on expanding = false)
            // removing the animation is important, otherwise we get sometimes random artifacts later which freeze the app.
            self?.bgColorLayer?.removeAnimationForKey(animationKey)
        }
        bgColorLayer?.addAnimation(pathAnimation, forKey: animationKey)
        
        CATransaction.commit()
    }
    
    private func titleTopConstant(expanded: Bool) -> CGFloat {
        return expanded ? CGFloat(topConstant) : CGFloat(startTopConstant)
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
        titleLabelTopConstraint?.constant = center ? CGFloat(topConstant) : CGFloat(startTopConstant)
        if animated {
            UIView.animateWithDuration(0.3, animations: {[weak self] in
                self?.layoutIfNeeded()
                }) {[weak self] finished in
                    self?.delegate?.onCenterTitleAnimComplete(center)
            }
            
            if withDot {
                animateDot(center)
            }

        } else {
            
            if withDot && center { // we want to show the dot when the view is in expanded (label=center) state
                animateDot(true, duration: 0.1) // since the dot is not added as a view but simply animation with fill after, to show dot without animation we run the animation with duration 0
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
        button.addTarget(self, action: "onTitleTap:", forControlEvents: .TouchUpInside)
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
                backLabel.titleLabel?.font = Fonts.regularLight
                backLabel.setTitleColor(fgColor, forState: .Normal)
                addSubview(backLabel)
                
                let viewDictionary = ["back": button, "backLabel": backLabel]
                
                let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-(6)-[back]-(4)-[backLabel]", options: [], metrics: nil, views: viewDictionary)
                let vImgConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(\(topConstant))-[back]", options: [], metrics: nil, views: viewDictionary)
                let vLabelConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(\(topConstant))-[backLabel]", options: [], metrics: nil, views: viewDictionary)
                
                addConstraints(hConstraints)
                addConstraints(vImgConstraints)
                addConstraints(vLabelConstraints)

                button.addTarget(self, action: "onBackTap:", forControlEvents: .TouchUpInside)
                backLabel.addTarget(self, action: "onBackTap:", forControlEvents: .TouchUpInside)
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

                button.alignTop(tapView, constant: topConstant)
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
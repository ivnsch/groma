//
//  FloatingViews.swift
//  shoppin
//
//  Created by ischuetz on 24/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

enum FLoatingButtonAction {
    case add, toggle, back, submit, expand
}

struct FLoatingButtonAttributedAction {
    let action: FLoatingButtonAction
    let alpha: CGFloat
    let rotation: CGFloat
    let xRight: CGFloat?
    let enabled: Bool
    let paths: [CGPath]?
    let backgroundColor: UIColor?
    let pathColor: UIColor?
    
    init(action: FLoatingButtonAction, alpha: CGFloat = 1, rotation: CGFloat = 0, xRight: CGFloat? = nil, enabled: Bool = true, paths: [CGPath]? = nil, backgroundColor: UIColor? = nil, pathColor: UIColor? = nil) {
        self.action = action
        self.alpha = alpha
        self.rotation = rotation
        self.xRight = xRight
        self.enabled = enabled
        self.paths = paths
        self.backgroundColor = backgroundColor
        self.pathColor = pathColor
    }
    
    // NOTE: xRight must be passed because field is an optional, if we make passing optional and want to set it to nil it's not possible
    func copy(_ action: FLoatingButtonAction? = nil, alpha: CGFloat? = nil, rotation: CGFloat? = nil, xRight: CGFloat?) -> FLoatingButtonAttributedAction {
        return FLoatingButtonAttributedAction(
            action: action ?? self.action,
            alpha: alpha ?? self.alpha,
            rotation: rotation ?? self.rotation,
            xRight: xRight
        )
    }
}


class FloatingViewModel {
    let action: FLoatingButtonAction
    let imgName: String?
    let alpha: CGFloat
    let rotation: CGFloat
    let xRight: CGFloat?
    let enabled: Bool
    let onTap: VoidFunction
    let paths: [CGPath]?
    let backgroundColor: UIColor?
    let pathColor: UIColor?

    init(action: FLoatingButtonAction, imgName: String?, alpha: CGFloat, rotation: CGFloat, xRight: CGFloat? = nil, enabled: Bool, paths: [CGPath]? = nil, backgroundColor: UIColor? = nil, pathColor: UIColor? = nil, onTap: @escaping VoidFunction) {
        self.action = action
        self.imgName = imgName
        self.alpha = alpha
        self.rotation = rotation
        self.xRight = xRight
        self.enabled = enabled
        self.paths = paths
        self.onTap = onTap
        self.backgroundColor = backgroundColor
        self.pathColor = pathColor
    }
}


protocol BottonPanelViewDelegate: class {
    func onSubmitAction(_ action: FLoatingButtonAction)
}

class ButtonWithConstraints: UIButton {
    
    var right: NSLayoutConstraint? = nil

    var paths: [CGPath] = []
    
    init() {
        super.init(frame: CGRect.null)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class FloatingViews: UIView {
    
    fileprivate let extendABitWhen3Buttons = true
    
    let buttonWidth: CGFloat = 40
    
    var models: [FloatingViewModel] = [] {
        didSet {
//            initButtons()
            transition(oldValue, newModels: models)
        }
    }
    
    fileprivate var buttons: [ButtonWithConstraints] = [] // Note: order is not important here
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        xibSetup()
        
        autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        xibSetup()
        
        autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
    }
    
//    // TODO find a way to not have extra view here (add subview) since this is used in tableview cells.
//    private func xibSetup() {
//        let view = NSBundle.loadView("FloatingViews", owner: self)!
//        view.frame = bounds
//        // Make the view stretch with containing view
//        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
//        self.addSubview(view)
//    }
    
    
    weak var delegate: BottonPanelViewDelegate?
    
    func setActions(_ actions: [FLoatingButtonAction]) {
        let attributedActions = actions.map{FLoatingButtonAttributedAction(action: $0)}
        setActions(attributedActions)
    }

    func setActions(_ actions: [FLoatingButtonAttributedAction]) {
        
        func toModel(_ attributedAction: FLoatingButtonAttributedAction) -> FloatingViewModel {
            let imgName: String? = {
                switch attributedAction.action {
                case .add: return "flt_plus"
                case .toggle: return "flt_plus"
                case .back: return "flt_back"
                case .submit: return "flt_done"
                case .expand: return nil
                }
            }()
            return FloatingViewModel(action: attributedAction.action, imgName: imgName, alpha: attributedAction.alpha, rotation: attributedAction.rotation, xRight: attributedAction.xRight, enabled: attributedAction.enabled, paths: attributedAction.paths, backgroundColor: attributedAction.backgroundColor, pathColor: attributedAction.pathColor, onTap: {[weak self] in
                self?.submitAction(attributedAction.action)
            })
        }
        
        let models = actions.map{toModel($0)}
        self.models = models
    }
    
    fileprivate func submitAction(_ action: FLoatingButtonAction) {
        delegate?.onSubmitAction(action)
    }
    
    
    fileprivate func initButtons() {
        clearButtons()
        loadButtons()
    }
    
    fileprivate func clearButtons() {
        removeSubviews()
    }
    
    fileprivate func loadButtons() {
        for i in 0..<models.count {
            let model = models[i]
            
            let button = createButton(model)
            
            button.tag = i
            
            addSubview(button)
            buttons.append(button)
        }
    }
    
    fileprivate func createButton(_ model: FloatingViewModel) -> ButtonWithConstraints {
        let button = ButtonWithConstraints()
        button.backgroundColor = model.backgroundColor ?? UIColor.white // note that bgColor is set again in animation, to be able to animate color changes
        button.layer.cornerRadius = buttonWidth / CGFloat(2)
        button.clipsToBounds = true
        
        if let imgName = model.imgName {
            button.setImage(UIImage(named: imgName), for: UIControl.State())
        }
        
        // Add the sublayers (empty). The paths are added during animation.
        if let paths = model.paths {
            for path in paths {
                let sublayer = CAShapeLayer()
                sublayer.fillColor     = UIColor.clear.cgColor
                sublayer.anchorPoint   = CGPoint(x: 0, y: 0)
                sublayer.lineJoin      = CAShapeLayerLineJoin.round
                sublayer.lineCap       = CAShapeLayerLineCap.round
                sublayer.contentsScale = layer.contentsScale
                sublayer.lineWidth     = 1
                sublayer.strokeColor   = model.pathColor?.cgColor ?? UIColor.black.cgColor
                button.layer.addSublayer(sublayer)
                button.paths.append(path)
            }
        }

        button.addTarget(self, action: #selector(FloatingViews.onButtonTap(_:)), for: .touchUpInside)
        button.alpha = model.alpha
        button.transform = CGAffineTransform(rotationAngle: model.rotation)
        button.isEnabled = model.enabled
        return button
    }
    
    fileprivate func calculateModelPosition(_ index: Int, modelsCount: Int) -> CGPoint {
        let halfButtonWidth = buttonWidth / 2
        let distanceX = frame.width / CGFloat(modelsCount + 1)
        let top: CGFloat = (frame.height - buttonWidth) / 2.0
        
        var centerXFromRight = ((CGFloat(index + 1) * distanceX) - halfButtonWidth)
        
        if extendABitWhen3Buttons {
            if modelsCount == 3 {
                if index == 0 {
                    centerXFromRight -= 15
                } else if index == 2 {
                    centerXFromRight += 15
                }
            }
        }
        
        return CGPoint(x: centerXFromRight, y: top)
    }
    
    fileprivate func positionView(_ view: ButtonWithConstraints, xFromRight: CGFloat, top: CGFloat) {
        
        let views = [view]
        for v in views {
            v.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let namedViews = views.enumerated().map{index, view in
            ("v\(index)", view)
        }
        
        var viewsDict: [String: UIView] = [:]
        for tuple in namedViews {
            viewsDict[tuple.0] = tuple.1
        }
        
        let hConstraintStr = "H:[v0]-(\(xFromRight))-|"
        
        let vConstraits = namedViews.flatMap {NSLayoutConstraint.constraints(withVisualFormat: "V:|-(\(top))-[\($0.0)]", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDict)}
        
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: hConstraintStr, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDict)
        
        view.right = hConstraints.first!

        addConstraints(hConstraints + vConstraits)
    }
    
    fileprivate func buttonForAction(models: [FloatingViewModel], action: FLoatingButtonAction) -> ButtonWithConstraints? {
        for button in buttons {
            if models[button.tag].action == action { // TODO!!! index out of range here when tap many times fast on edit in list items. Models is empty and tag is 0
                return button
            }
        }
        return nil
    }
    
    // src: https://github.com/yannickl/DynamicButton/blob/master/DynamicButton/DynamicButton.swift
    fileprivate func animationWithKeyPath(_ keyPath: String, damping: CGFloat = 10, initialVelocity: CGFloat = 0, stiffness: CGFloat = 100) -> CABasicAnimation {
        guard #available(iOS 9, *) else {
            let basic = CABasicAnimation(keyPath: keyPath)
            basic.duration = 0.3
            basic.fillMode = CAMediaTimingFillMode.forwards
            basic.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
            return basic
        }
        
        let spring = CASpringAnimation(keyPath: keyPath)
        spring.duration = spring.settlingDuration
        spring.damping = damping
        spring.initialVelocity = initialVelocity
        spring.stiffness = stiffness
        spring.fillMode = CAMediaTimingFillMode.forwards
        spring.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
        
        return spring
    }
    
    fileprivate func animate(_ button: ButtonWithConstraints, target: PositionedModel, onComplete: VoidFunction? = nil) {
        
        button.right?.constant = target.position.x

        // animate possible path(s)
        if let paths = target.paths {
            for (index, path) in paths.enumerated() {
                let anim = animationWithKeyPath("path", damping: 10)
                anim.fromValue = button.paths[index]
                anim.toValue = path
                // TODO cleaner implementation, this index based access and casting is super unsafe
                (button.layer.sublayers![index] as! CAShapeLayer).add(anim, forKey: "path")
                (button.layer.sublayers![index] as! CAShapeLayer).path = path
            }
            button.paths = paths
        }

        // animate possible alpha and rotation change
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
            self?.layoutIfNeeded()
            button.alpha = target.alpha
            button.transform = CGAffineTransform(rotationAngle: target.rotation)
            if let backgroundColor = target.backgroundColor {
                button.backgroundColor = backgroundColor
            }
        }, completion: {finished in
            onComplete?()
        })
    }
    
    fileprivate typealias PositionedModel = (action: FLoatingButtonAction, position: CGPoint, alpha: CGFloat, rotation: CGFloat, paths: [CGPath]?, backgroundColor: UIColor?, pathColor: UIColor?)
    
    // TODO ensure while add/remove buttons (index change) no access to buttons or models based on index / tag
    
    fileprivate func transition(_ oldModels: [FloatingViewModel], newModels: [FloatingViewModel]) {
        // for now:
        // contract: make all views "on the left" move to center of view on the most right and fade out
        // expand: make all views "on the left" start from center most right to their respective positions
        
        var toAdd: [ButtonWithConstraints] = []
        var toUpdate: [(button: ButtonWithConstraints, targetModel: PositionedModel)] = []
        for (i, newModel) in newModels.enumerated() {
            let buttonForNewModelMaybe = buttonForAction(models: oldModels, action: newModel.action)
            
            if let existingButton = buttonForNewModelMaybe {
                
                var position = calculateModelPosition(i, modelsCount: newModels.count)
                position.x = newModel.xRight ?? position.x
                
                let positionedModel = PositionedModel(newModel.action, position, newModel.alpha, newModel.rotation, newModel.paths, newModel.backgroundColor, newModel.pathColor)
                toUpdate.append((existingButton, positionedModel))
                existingButton.tag = i
                
            } else {
                let button = createButton(newModel)
                toAdd.append(button)
                
                button.alpha = 0
                
                var position = calculateModelPosition(i, modelsCount: newModels.count)
                position.x = newModel.xRight ?? position.x

                let positionedModel = PositionedModel(newModel.action, position, newModel.alpha, newModel.rotation, newModel.paths, newModel.backgroundColor, newModel.pathColor)
                toUpdate.append((button, positionedModel))
                button.tag = i
            }
        }
        
        var toRemove: [(button: ButtonWithConstraints, targetModel: PositionedModel)] = []
        for button in buttons {
            let oldModel = oldModels[button.tag]
            if !newModels.contains(where: {$0.action == oldModel.action}) {
                
                // animation target for removed elements: position on the right corner
                let position = calculateModelPosition(0, modelsCount: newModels.count)
                let positionedModel = PositionedModel(oldModel.action, position, 0, oldModel.rotation, oldModel.paths, oldModel.backgroundColor, oldModel.pathColor)
                
                toRemove.append((button: button, targetModel: positionedModel))
            }
        }

        // now that all updates are prepared, execute them
        
        // add buttons for the new items (at right bottom corner, behind)
        for button in toAdd {
            let position = calculateModelPosition(0, modelsCount: newModels.count)
            addSubview(button)
            sendSubviewToBack(button)
            buttons.append(button)
            positionView(button, xFromRight: position.x, top: position.y) // TODO behind existing buttons
            // set size
            _ = button.widthConstraint(buttonWidth)
            _ = button.heightConstraint(buttonWidth)
        }
        
        // TODO is this necessary?
        setNeedsLayout()
        layoutIfNeeded()
        
        // animate updated (new or old which are also in new) buttons to their target positions
        for t in toUpdate {
            animate(t.button, target: t.targetModel)
        }
        
        // animate the removed buttons to the bottom right
        for t in toRemove {
            animate(t.button, target: t.targetModel) {[weak self] in
                // FIXME! models are updated immediately, but this - the update of corresponding buttons, after animation complete, so in the meantime (currently 0.3 seconds), inconsistent state which can lead to out of bounds when trying to access models using button index or viceversa.
                // model & corresponding buttons should be updated exactly at the same time as this represents same state. (Would is maybe make sense to have only 1 class, e.g. put all the state in the buttons or something?)
                t.button.removeFromSuperview()
                _ = self?.buttons.remove(t.button)
            }
        }
    }
    
    @objc func onButtonTap(_ button: UIButton) {
        models[button.tag].onTap()
    }
}

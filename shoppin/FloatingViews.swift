//
//  FloatingViews.swift
//  shoppin
//
//  Created by ischuetz on 24/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

enum FLoatingButtonAction {
    case Add, Toggle, Back, Submit
}

struct FLoatingButtonAttributedAction {
    let action: FLoatingButtonAction
    let alpha: CGFloat
    let rotation: CGFloat
    let xRight: CGFloat?
    let enabled: Bool
    
    init(action: FLoatingButtonAction, alpha: CGFloat = 1, rotation: CGFloat = 0, xRight: CGFloat? = nil, enabled: Bool = true) {
        self.action = action
        self.alpha = alpha
        self.rotation = rotation
        self.xRight = xRight
        self.enabled = enabled
    }
    
    // NOTE: xRight must be passed because field is an optional, if we make passing optional and want to set it to nil it's not possible
    func copy(action: FLoatingButtonAction? = nil, alpha: CGFloat? = nil, rotation: CGFloat? = nil, xRight: CGFloat?) -> FLoatingButtonAttributedAction {
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
    let imgName: String
    let alpha: CGFloat
    let rotation: CGFloat
    let xRight: CGFloat?
    let enabled: Bool
    let onTap: VoidFunction
    
    init(action: FLoatingButtonAction, imgName: String, alpha: CGFloat, rotation: CGFloat, xRight: CGFloat? = nil, enabled: Bool, onTap: VoidFunction) {
        self.action = action
        self.imgName = imgName
        self.alpha = alpha
        self.rotation = rotation
        self.xRight = xRight
        self.enabled = enabled
        self.onTap = onTap
    }
}


protocol BottonPanelViewDelegate {
    func onSubmitAction(action: FLoatingButtonAction)
}

class ButtonWithConstraints: UIButton {
    
    var right: NSLayoutConstraint? = nil

    init() {
        super.init(frame: CGRectNull)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class FloatingViews: UIView {
    
    private let extendABitWhen3Buttons = true
    
    let buttonWidth: CGFloat = 40
    
    var models: [FloatingViewModel] = [] {
        didSet {
//            initButtons()
            transition(oldValue, newModels: models)
        }
    }
    
    private var buttons: [ButtonWithConstraints] = [] // Note: order is not important here
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        xibSetup()
        
        autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        xibSetup()
        
        autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
    }
    
//    // TODO find a way to not have extra view here (add subview) since this is used in tableview cells.
//    private func xibSetup() {
//        let view = NSBundle.loadView("FloatingViews", owner: self)!
//        view.frame = bounds
//        // Make the view stretch with containing view
//        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
//        self.addSubview(view)
//    }
    
    
    var delegate: BottonPanelViewDelegate?
    
    func setActions(actions: [FLoatingButtonAction]) {
        let attributedActions = actions.map{FLoatingButtonAttributedAction(action: $0)}
        setActions(attributedActions)
    }

    func setActions(actions: [FLoatingButtonAttributedAction]) {
        
        func toModel(attributedAction: FLoatingButtonAttributedAction) -> FloatingViewModel {
            let imgName: String = {
                switch attributedAction.action {
                case .Add: return "flt_plus"
                case .Toggle: return "flt_plus"
                case .Back: return "flt_back"
                case .Submit: return "flt_done"
                }
            }()
            return FloatingViewModel(action: attributedAction.action, imgName: imgName, alpha: attributedAction.alpha, rotation: attributedAction.rotation, xRight: attributedAction.xRight, enabled: attributedAction.enabled, onTap: {[weak self] in
                self?.submitAction(attributedAction.action)
            })
        }
        
        let models = actions.map{toModel($0)}
        self.models = models
    }
    
    private func submitAction(action: FLoatingButtonAction) {
        delegate?.onSubmitAction(action)
    }
    
    
    private func initButtons() {
        clearButtons()
        loadButtons()
    }
    
    private func clearButtons() {
        removeSubviews()
    }
    
    private func loadButtons() {
        for i in 0..<models.count {
            let model = models[i]
            
            let button = createButton(model)
            
            button.tag = i
            
            addSubview(button)
            buttons.append(button)
        }
    }
    
    private func createButton(model: FloatingViewModel) -> ButtonWithConstraints {
        let button = ButtonWithConstraints()
        button.backgroundColor = UIColor.whiteColor()
        button.layer.cornerRadius = buttonWidth / CGFloat(2)
        button.setImage(UIImage(named: model.imgName), forState: .Normal)
        button.addTarget(self, action: "onButtonTap:", forControlEvents: .TouchUpInside)
        button.alpha = model.alpha
        button.transform = CGAffineTransformMakeRotation(model.rotation)
        button.enabled = model.enabled
        return button
    }
    
    private func calculateModelPosition(index: Int, modelsCount: Int) -> CGPoint {
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
        
        return CGPointMake(centerXFromRight, top)
    }
    
    private func positionView(view: ButtonWithConstraints, xFromRight: CGFloat, top: CGFloat) {
        
        let views = [view]
        for v in views {
            v.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let namedViews = views.enumerate().map{index, view in
            ("v\(index)", view)
        }
        
        let viewsDict = namedViews.reduce(Dictionary<String, UIView>()) {(var u, tuple) in
            u[tuple.0] = tuple.1
            return u
        }
        
        let hConstraintStr = "H:[v0]-\(xFromRight)-|"
        
        let vConstraits = namedViews.flatMap {NSLayoutConstraint.constraintsWithVisualFormat("V:|-(\(top))-[\($0.0)]", options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict)}
        
        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat(hConstraintStr, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict)
        
        view.right = hConstraints.first!
        
        addConstraints(hConstraints + vConstraits)
    }
    
    private func buttonForAction(models models: [FloatingViewModel], action: FLoatingButtonAction) -> ButtonWithConstraints? {
        for button in buttons {
            if models[button.tag].action == action {
                return button
            }
        }
        return nil
    }
    
    
    private func animate(button: ButtonWithConstraints, target: PositionedModel, onComplete: VoidFunction? = nil) {
        
        button.right?.constant = target.position.x
        
        UIView.animateWithDuration(0.3, animations: {[weak self] in
            self?.layoutIfNeeded()
            button.alpha = target.alpha
            button.transform = CGAffineTransformMakeRotation(target.rotation)
  
        }, completion: {finished in
            onComplete?()
        })
    }
    
    private typealias PositionedModel = (action: FLoatingButtonAction, position: CGPoint, alpha: CGFloat, rotation: CGFloat)
    
    // TODO ensure while add/remove buttons (index change) no access to buttons or models based on index / tag
    
    private func transition(oldModels: [FloatingViewModel], newModels: [FloatingViewModel]) {
        // for now:
        // contract: make all views "on the left" move to center of view on the most right and fade out
        // expand: make all views "on the left" start from center most right to their respective positions
        
        var toAdd: [ButtonWithConstraints] = []
        var toUpdate: [(button: ButtonWithConstraints, targetModel: PositionedModel)] = []
        for (i, newModel) in newModels.enumerate() {
            let buttonForNewModelMaybe = buttonForAction(models: oldModels, action: newModel.action)
            
            if let existingButton = buttonForNewModelMaybe {
                
                var position = calculateModelPosition(i, modelsCount: newModels.count)
                position.x = newModel.xRight ?? position.x
                
                let positionedModel = PositionedModel(newModel.action, position, newModel.alpha, newModel.rotation)
                toUpdate.append((existingButton, positionedModel))
                existingButton.tag = i
                
            } else {
                let button = createButton(newModel)
                toAdd.append(button)
                
                button.alpha = 0
                
                var position = calculateModelPosition(i, modelsCount: newModels.count)
                position.x = newModel.xRight ?? position.x

                let positionedModel = PositionedModel(newModel.action, position, newModel.alpha, newModel.rotation)
                toUpdate.append((button, positionedModel))
                button.tag = i
            }
        }
        
        var toRemove: [(button: ButtonWithConstraints, targetModel: PositionedModel)] = []
        for button in buttons {
            let oldModel = oldModels[button.tag]
            if !newModels.contains({$0.action == oldModel.action}) {
                
                // animation target for removed elements: position on the right corner
                let position = calculateModelPosition(0, modelsCount: newModels.count)
                let positionedModel = PositionedModel(oldModel.action, position, 0, oldModel.rotation)
                
                toRemove.append(button: button, targetModel: positionedModel)
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
        }
        setNeedsLayout()
        layoutIfNeeded()
        
        // animate updated (new or old which are also in new) buttons to their target positions
        for t in toUpdate {
            animate(t.button, target: t.targetModel)
        }
        
        // animate the removed buttons to the bottom right
        for t in toRemove {
            animate(t.button, target: t.targetModel) {[weak self] in
                t.button.removeFromSuperview()
                self?.buttons.remove(t.button)
            }
        }
    }
    
    func onButtonTap(button: UIButton) {
        models[button.tag].onTap()
    }
}
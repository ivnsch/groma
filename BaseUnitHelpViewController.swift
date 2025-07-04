//
//  BaseUnitHelpViewController.swift
//  groma
//
//  Created by Ivan Schuetz on 22.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import ChartLegends
import Providers

enum BaseUnitHelpItemType {
    case base, secondBase, unit, refQuantity, price
}

class BaseUnitHelpViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var legendsView: ChartLegendsView!
    @IBOutlet weak var tableView: UITableView!

    fileprivate var animateCirclesInCell = true
    var closeTapHandler: (() -> Void)?

    fileprivate let noteCellIndex = 1

    fileprivate let cellModels: [UnitBaseHelpCell.CellModel] = [
        UnitBaseHelpCell.CellModel(itemName: trans("pr_eggs"), quantity: 1, baseQuantity: 6, secondBaseQuantity: nil, unit: trans("unit_unit_pl"), referenceQuantity: 6, price: 1.99, image: #imageLiteral(resourceName: "eggs6x")),
        UnitBaseHelpCell.CellModel(itemName: trans("pr_grapes"), quantity: 1, baseQuantity: 500, secondBaseQuantity: nil, unit: trans("unit_g"), referenceQuantity: 1000, price: 1.99, image: #imageLiteral(resourceName: "grapes")),
        UnitBaseHelpCell.CellModel(itemName: trans("pr_cola"), quantity: 1, baseQuantity: 2, secondBaseQuantity: nil, unit: trans("unit_liter"), referenceQuantity: 1, price: 1.99, image: #imageLiteral(resourceName: "coke")),
        UnitBaseHelpCell.CellModel(itemName: trans("pr_cola"), quantity: 1, baseQuantity: 6, secondBaseQuantity: 1, unit: trans("unit_liter"), referenceQuantity: 1, price: 0.98, image: #imageLiteral(resourceName: "coke6x"))
    ]

    fileprivate var itemTypeColors: [BaseUnitHelpItemType: UIColor] = [
        .base : UIColor.flatLime,
        .secondBase : UIColor.flatBlue,
        .unit : UIColor.flatOrange,
        .refQuantity : UIColor.flatRed,
        .price : UIColor.flatMint
    ]

    fileprivate func color(_ itemType: BaseUnitHelpItemType) -> UIColor {
        return itemTypeColors[itemType] ?? UIColor.black
    }

    static func show(parent: UIViewController, from: UIView? = nil) {
        let helpController = BaseUnitHelpViewController()
        let preferredFrame = CGRect(x: 100, y: 10, width: 340, height: 520)

        helpController.view.frame = {
            let width = min(preferredFrame.width, UIScreen.main.bounds.width - DimensionsManager.minPopupHMargin * 2)
            return preferredFrame.copy(width: width)
        } ()

        helpController.view.layer.cornerRadius = Theme.popupCornerRadius
        helpController.view.clipsToBounds = true

        let popup = MyPopupHelper.showCustomPopupFrom(parent: parent, centerYOffset: 0, contentController: helpController, swipeEnabled: false, useDefaultFrame: false, from: from)

        helpController.closeTapHandler = {
            helpController.removeFromParent()
            if from == nil {
                popup.hideFall()
            } else {
                popup.hide()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = trans("base_unit_help_title")

        setupLegends()
        setupTableView()
    }

    fileprivate func setupLegends() {
        var legendConstraints = DefaultChartLegendConstraintConstants()
        legendConstraints.shapeWidth = 8
        legendConstraints.shapeToLabel = 10
        DefaultChartLegendCell.defaultConstraintConstants = legendConstraints

        // Set also text color (default legend cells set only color of shape)
        legendsView.configure(cellType: DefaultChartLegendCell.self) { cell, legend, indexPath in
            cell.legend = legend as? ShapeChartLegend
            cell.label.textColor = legend.color
        }

        legendsView.setLegends(.circle(radius: 4), [
            (text: "Base quantity", color: color(.base)),
            (text: "2nd base quantity", color: color(.secondBase)),
            (text: "Unit", color: color(.unit)),
            (text: "Reference quantity", color: color(.refQuantity)),
            (text: "Price", color: color(.price))
            ])
    }

    fileprivate func setupTableView() {
        tableView.register(UINib(nibName: "UnitBaseHelpCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.register(UINib(nibName: "BaseUnitHelpExplanationCell", bundle: nil), forCellReuseIdentifier: "noteCell")
        tableView.register(UINib(nibName: "UnitBaseHelpBasesExplanationCell", bundle: nil), forCellReuseIdentifier: "unitBaseExplanation")
        tableView.register(UINib(nibName: "ReferenceQuantityPriceHelpCell", bundle: nil), forCellReuseIdentifier: "referencePriceCell")

        tableView.dataSource = self
        tableView.delegate = self

        let submitView = SubmitView()
        submitView.setButtonTitle(title: trans("button_close_help"))
        submitView.delegate = self
        submitView.size = CGSize(width: view.width, height: Theme.submitViewHeight)

        tableView.tableFooterView = submitView
    }

    @IBAction func onCloseTap(_ sender: UIButton) {
        closeTapHandler?()
    }
}

extension BaseUnitHelpViewController: SubmitViewDelegate {

    func onSubmitButton() {
        closeTapHandler?()
    }
}

extension BaseUnitHelpViewController: UITableViewDataSource {

    var cellCount: Int {
        return cellModels.count + 1 + 1 + 1 // + 1 note cell + 1 base unit explanation + 1 reference quantity / price explanation
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: UITableViewCell = {
            switch indexPath.row {
            case noteCellIndex:
                let cell = tableView.dequeueReusableCell(withIdentifier: "noteCell", for: indexPath) as! BaseUnitHelpExplanationCell
                return cell
            case cellModels.count + 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "unitBaseExplanation", for: indexPath) as! UnitBaseHelpBasesExplanationCell
                cell.config(colorDict: itemTypeColors)
                return cell
            case cellModels.count + 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "referencePriceCell", for: indexPath) as! ReferenceQuantityPriceHelpCell
                cell.config(colorDict: itemTypeColors)
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UnitBaseHelpCell
                let index = indexPath.row < noteCellIndex ? indexPath.row : indexPath.row - 1
                cell.config(model: cellModels[index], circleColorsDictionary: itemTypeColors, animateCircles: animateCirclesInCell)
                animateCirclesInCell = false
                return cell
            }
        }()

        if indexPath.row < cellCount - 1 {
            cell.contentView.addBottomBorderWithColor(Theme.cellBottomBorderColor, width: 1)
        }
        return cell
    }
}

extension BaseUnitHelpViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        switch indexPath.row {
        case noteCellIndex:
            return 100
        case cellModels.count + 1:
            return 90
        case cellModels.count + 2:
            return 270
        default:
            return 350
        }
    }
}

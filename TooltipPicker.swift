//
//  TooltipPicker.swift
//  groma
//
//  Created by Ivan Schuetz on 24.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class TooltipPicker: UITableViewController {

    fileprivate var options: [String] = []
    fileprivate var selectedOption: String?
    fileprivate var onSelectOption: ((String) -> Void)?

    func config(options: [String], selectedOption: String?, onSelectOption: @escaping (String) -> Void) {
        self.options = options
        self.selectedOption = selectedOption
        self.onSelectOption = onSelectOption
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "TooltipPickerCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = Theme.blue
        tableView.indicatorStyle = .white
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> TooltipPickerCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TooltipPickerCell

        let option = options[indexPath.row]
        cell.label.text = option
        cell.selectionStyle = .none

        cell.selectedBackground.isHidden = option != selectedOption
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedOption = options[indexPath.row]
        self.selectedOption = selectedOption
        tableView.reloadData()
        onSelectOption?(selectedOption)
    }
}

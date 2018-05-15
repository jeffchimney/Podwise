//
//  SettingsTableViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2018-05-15.
//  Copyright © 2018 Jeff Chimney. All rights reserved.
//

import Foundation

class SettingsTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "labelSwitchCell", for: indexPath as IndexPath) as! LabelAndSwitchTableViewCell
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                cell.setCellType(to: .delete)
            case 1:
                cell.setCellType(to: .autoPlay)
            default:
                cell.setCellType(to: .notSet)
            }
        }
        return cell
    }
}

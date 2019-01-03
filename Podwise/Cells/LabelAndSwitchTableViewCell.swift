//
//  LabelAndSwitchTableViewCell.swift
//  Podwise
//
//  Created by Jeff Chimney on 2018-05-15.
//  Copyright © 2018 Jeff Chimney. All rights reserved.
//

import Foundation

enum CellType {
    case delete
    case autoPlay
    case notSet
}

class LabelAndSwitchTableViewCell: UITableViewCell {
    
    let switchView = UISwitch(frame: .zero)
    var cellType: CellType = .notSet
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    func commonInit() {
        switchView.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        self.accessoryView = switchView
    }
    
    func setCellType(to: CellType) {
        self.cellType = to
        
        switch cellType {
        case .delete:
            titleLabel.text = "Housekeeping!"
            subTitleLabel.text = "Auto delete episodes upon completion."
            switchView.setOn(UserDefaultsHelper.getDeleteAfterEpisodeFinishes(), animated: true)
        case .autoPlay:
            titleLabel.text = "Queue me up, Scotty"
            subTitleLabel.text = "Auto play the next episode in a playlist when the current episode ends."
            switchView.setOn(UserDefaultsHelper.getAutoPlayNextEpisode(), animated: true)
        case .notSet:
            print("Not Set")
        }
    }
    
    @objc func switchChanged() {
        switch cellType {
        case .delete:
            UserDefaultsHelper.setDeleteAfterEpisodeFinishes(to: switchView.isOn)
        case .autoPlay:
            UserDefaultsHelper.setAutoPlayNextEpisode(to: switchView.isOn)
        case .notSet:
            print("Not Set")
        }
    }
}

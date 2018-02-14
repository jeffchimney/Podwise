//
//  PlaylistCell.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-22.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class PlaylistCell: UITableViewCell {
    
    @IBOutlet weak var artImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var episodeCounterLabel: UILabel!
    
    override func layoutSubviews() {
        self.bounds = CGRect(x: self.bounds.origin.x,
                             y: self.bounds.origin.y,
                             width: self.bounds.size.width - 16,
                             height: self.bounds.size.height)
        super.layoutSubviews()
    }
}


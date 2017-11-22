//
//  EpisodeCell.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-21.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class EpisodeCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    var feedID: String!
    
}

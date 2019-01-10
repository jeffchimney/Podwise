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
    @IBOutlet weak var percentDowloadedLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var nowPlayingView: NowPlayingView!
    @IBOutlet weak var centerEQHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var centerEQView: UIView!
    @IBOutlet weak var leftEQHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftEQView: UIView!
    @IBOutlet weak var rightEQHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightEQView: UIView!
    
}


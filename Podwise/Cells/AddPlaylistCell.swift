//
//  AddPlaylistCell.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-29.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class AddPlaylistCell: UICollectionViewCell {
    
    @IBOutlet weak var playlistButton: UIButton!
    weak var editDelegate: editPlaylistParentDelegate!
    
    @IBAction func addPlaylistPressed(_ sender: Any) {
        editDelegate.edit()
    }
}

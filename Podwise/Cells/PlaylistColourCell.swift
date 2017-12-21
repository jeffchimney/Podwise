//
//  PlaylistColourCell.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-12-20.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class PlaylistColourCell: UICollectionViewCell {
    
    @IBOutlet weak var purpleButton: UIButton!
    @IBOutlet weak var blueButton: UIButton!
    @IBOutlet weak var greenButton: UIButton!
    @IBOutlet weak var yellowButton: UIButton!
    @IBOutlet weak var orangeButton: UIButton!
    @IBOutlet weak var redButton: UIButton!
    @IBOutlet weak var greyButton: UIButton!
    
    @IBAction func colourPreferenceChanged(_ sender: Any) {
        let buttonPressed = sender as! UIButton
        switch buttonPressed {
        case purpleButton:
            print("purple")
        case blueButton:
            print("blue")
        case greenButton:
            print("green")
        case yellowButton:
            print("yellow")
        case orangeButton:
            print("orange")
        case redButton:
            print("red")
        case greyButton:
            print("red")
        default:
            print("default")
        }
    }
}

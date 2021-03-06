//
//  NewPlaylistHeaderView.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-12-19.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class NewPlaylistHeaderView: UITableViewHeaderFooterView, UITextFieldDelegate {
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    weak var savePlaylistDelegate: savePlaylistDelegate!
    //var playlist: CDPlaylist!
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        if textField.text == "" {
            textField.text = "New Playlist"
        }
        savePlaylistDelegate.saveButtonPressed(playlistName: textField.text!)
    }
    @IBAction func dismissButtonPressed(_ sender: Any) {
        savePlaylistDelegate.dismissPlaylist()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


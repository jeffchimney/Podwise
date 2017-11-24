//
//  BaseViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-23.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

var audioPlayer:AVAudioPlayer!
var downloads: [CDEpisode]!
var nowPlayingArt: UIImage!
var baseViewController: BaseViewController!

class BaseViewController: UIViewController {
    
    @IBOutlet weak var miniPlayerView: MiniPlayerView!
    @IBOutlet weak var miniPlayerHeightConstraint: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        baseViewController = self
        
        miniPlayerView.artImageView.layer.cornerRadius = 10
        miniPlayerView.artImageView.layer.masksToBounds = true
        
        if audioPlayer != nil {
            showMiniPlayer(animated: false)
        } else {
            hideMiniPlayer(animated: false)
        }
    }
    
    public func hideMiniPlayer(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 1, animations: {
                self.miniPlayerHeightConstraint.constant = 0
                self.miniPlayerView.alpha = 0
            })
        } else {
            self.miniPlayerHeightConstraint.constant = 0
            self.miniPlayerView.alpha = 0
        }
    }
    
    public func showMiniPlayer(animated: Bool) {
        if audioPlayer != nil {
            miniPlayerView.artImageView.image = nowPlayingArt
            if audioPlayer.isPlaying {
                miniPlayerView.playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
            } else {
                miniPlayerView.playPauseButton.setImage(UIImage(named: "play-50"), for: .normal)
            }
        }
        if animated {
            UIView.animate(withDuration: 1, animations: {
                self.miniPlayerHeightConstraint.constant = 70
                self.miniPlayerView.alpha = 1
            })
        } else {
            self.miniPlayerHeightConstraint.constant = 70
            self.miniPlayerView.alpha = 1
        }
    }
}

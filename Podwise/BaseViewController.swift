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
    
    @IBOutlet weak var baseView: UIView!
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
    
    override func viewDidLayoutSubviews() {
        let rectShape = CAShapeLayer()
        rectShape.bounds = self.baseView.frame
        rectShape.position = self.baseView.center
        rectShape.path = UIBezierPath(roundedRect: self.baseView.bounds, byRoundingCorners: [.bottomLeft , .bottomRight], cornerRadii: CGSize(width: 25, height: 25)).cgPath
        
        self.baseView.layer.backgroundColor = UIColor.green.cgColor
        //Here I'm masking the textView's layer with rectShape layer
        self.baseView.layer.masksToBounds = true
        self.baseView.layer.mask = rectShape
    }
    
    public func hideMiniPlayer(animated: Bool) {
        if animated {
            self.miniPlayerHeightConstraint.constant = 0
            UIView.animate(withDuration: 1, animations: {
                self.miniPlayerView.alpha = 0
                self.view.layoutIfNeeded()
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
            self.miniPlayerHeightConstraint.constant = 70
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
            }, completion: { completed in
                UIView.animate(withDuration: 1, animations: {
                    self.miniPlayerView.alpha = 1
                })
            })
        } else {
            self.miniPlayerHeightConstraint.constant = 70
            self.miniPlayerView.alpha = 1
        }
    }
}

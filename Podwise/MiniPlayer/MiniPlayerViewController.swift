//
//  MiniPlayerViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-23.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit

class MiniPlayerView: UIView {
    
    @IBOutlet var miniPlayerView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var artImageView: UIImageView!
    @IBOutlet var artImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var artImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var artImageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var artImageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var artImageViewCenterYConstraint: NSLayoutConstraint!
    @IBOutlet var artImageViewCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var podcastTitle: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var chevronImage: UIImageView!
    @IBOutlet weak var playPauseDistanceFromBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var backTenDistanceFromPlayConstraint: NSLayoutConstraint!
    @IBOutlet weak var forward30DistanceFromPlayConstraint: NSLayoutConstraint!
    @IBOutlet weak var playPauseHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var playPauseWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressSlider: UISlider!
    var managedContext: NSManagedObjectContext?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("MiniPlayer", owner: self, options: nil)
        addSubview(miniPlayerView)
        miniPlayerView.frame = self.bounds
        miniPlayerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        if let player = audioPlayer {
            if player.isPlaying {
                playPauseButton.setImage(UIImage(named: "play-50"), for: .normal)
            } else {
                playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
            }
        }
        
        var thumbImage = UIImage(named: "first")
        
        let horizontalRatio: CGFloat = 0.5
        let verticalRatio: CGFloat = 0.5
        
        let ratio = max(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: (thumbImage?.size.width)! * ratio, height: (thumbImage?.size.height)! * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        draw(CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        thumbImage = newImage!
        
        progressSlider.setThumbImage(thumbImage, for: .normal)
        
        artImageViewCenterXConstraint.isActive = false
        artImageViewCenterYConstraint.isActive = false
    }
    
    @IBAction func playPauseButtonPressed(_ sender: Any) {
        if let player = audioPlayer {
            if player.isPlaying {
                playPauseButton.setImage(UIImage(named: "play-50"), for: .normal)
                
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                    return
                }
                managedContext = appDelegate.persistentContainer.viewContext
                
                nowPlayingEpisode.progress = Int64(audioPlayer.currentTime)
                CoreDataHelper.save(context: managedContext!)
                player.pause()
            } else {
                playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
                player.play()
            }
        }
    }
    
    @IBAction func skipBack(_ sender: Any) {
        if let player = audioPlayer {
            // Update progress
            player.currentTime = player.currentTime.advanced(by: -10)
            baseViewController.sliderView.setValue(Float(player.currentTime/player.duration), animated: true)
        }
    }
    
    @IBAction func skipForward(_ sender: Any) {
        if let player = audioPlayer {
            // Update progress
            player.currentTime = player.currentTime.advanced(by: 30)
            baseViewController.sliderView.setValue(Float(player.currentTime/player.duration), animated: true)
        }
    }
    
    @IBAction func playheadChanged(_ sender: Any) {
        if let player = audioPlayer {
            // Update progress
            let percentComplete = progressSlider.value
            player.currentTime = player.duration * Double(percentComplete)
        }
    }
}


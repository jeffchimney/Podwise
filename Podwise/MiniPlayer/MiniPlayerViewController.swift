//
//  MiniPlayerViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-23.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit
import MediaPlayer

class MiniPlayerView: UIView {
    
    @IBOutlet var miniPlayerView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var artImageView: UIImageView!
    @IBOutlet var artImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var artImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var artImageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var artImageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var playPauseDistanceFromBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var backTenDistanceFromPlayConstraint: NSLayoutConstraint!
    @IBOutlet weak var forward30DistanceFromPlayConstraint: NSLayoutConstraint!
    @IBOutlet weak var playPauseHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var playPauseWidthConstraint: NSLayoutConstraint!
    var managedContext: NSManagedObjectContext?
    var interactor:Interactor? = nil
    
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
                updateMediaPlayer(player: player)
                
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
            updateMediaPlayer(player: player)
            baseViewController.sliderView.setValue(Float(player.currentTime/player.duration), animated: true)
        }
    }
    
    @IBAction func skipForward(_ sender: Any) {
        if let player = audioPlayer {
            // Update progress
            player.currentTime = player.currentTime.advanced(by: 30)
            updateMediaPlayer(player: player)
            baseViewController.sliderView.setValue(Float(player.currentTime/player.duration), animated: true)
        }
    }
    
    func updateMediaPlayer(player: AVAudioPlayer) {
        let artworkImage = UIImage(data: nowPlayingEpisode.podcast!.image!)
        let artwork = MPMediaItemArtwork.init(boundsSize: artworkImage!.size, requestHandler: { (size) -> UIImage in
            return artworkImage!
        })
        
        let mpic = MPNowPlayingInfoCenter.default()
        mpic.nowPlayingInfo = [MPMediaItemPropertyTitle:nowPlayingEpisode.title!,
                               MPMediaItemPropertyArtist:nowPlayingEpisode.podcast!.title!,
                               MPMediaItemPropertyArtwork: artwork,
                               MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
                               MPMediaItemPropertyPlaybackDuration: player.duration,
        ]
    }
}


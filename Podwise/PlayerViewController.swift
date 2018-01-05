//
//  PlayerViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2018-01-05.
//  Copyright © 2018 Jeff Chimney. All rights reserved.
//

import UIKit
import MediaPlayer

class PlayerViewController: UIViewController {
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var artImageView: UIImageView!
    @IBOutlet weak var podcastTitle: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var chevronImage: UIImageView!
    @IBOutlet weak var progressSlider: UISlider!
    var managedContext: NSManagedObjectContext?
    var interactor:Interactor? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        view.draw(CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        thumbImage = newImage!
        
        progressSlider.setThumbImage(thumbImage, for: .normal)
    }
    
    @IBAction func handleGesture(sender: UIPanGestureRecognizer) {
        // 3
        let translation = sender.translation(in: view)
        // 4
        let progress = MiniPlayerTransitionHelper.calculateProgress(
            translationInView: translation,
            viewBounds: view.bounds,
            direction: .Down
        )
        // 5
        MiniPlayerTransitionHelper.mapGestureStateToInteractor(
            gestureState: sender.state,
            progress: progress,
            interactor: interactor){
                // 6
                self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func closeMenu(sender: AnyObject) {
        dismiss(animated: true, completion: nil)
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
    
    @IBAction func playheadChanged(_ sender: Any) {
        if let player = audioPlayer {
            // Update progress
            let percentComplete = progressSlider.value
            player.currentTime = player.duration * Double(percentComplete)
            updateMediaPlayer(player: player)
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



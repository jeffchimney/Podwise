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
import MediaPlayer

var audioPlayer:AVAudioPlayer!
var downloads: [CDEpisode]!
var nowPlayingEpisode: CDEpisode!
var baseViewController: BaseViewController!

class BaseViewController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var miniPlayerView: MiniPlayerView!
    @IBOutlet weak var miniPlayerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sliderHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sliderView: UISlider!
    let originalMiniPlayerHeightConstant: CGFloat = 70
    
    override func viewDidLoad() {
        super.viewDidLoad()
        baseViewController = self
        
        miniPlayerView.artImageView.layer.cornerRadius = 10
        miniPlayerView.artImageView.layer.masksToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
        swipeUp.direction = .up
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
        swipeDown.direction = .down
        miniPlayerView.addGestureRecognizer(tap)
        miniPlayerView.addGestureRecognizer(swipeUp)
        miniPlayerView.addGestureRecognizer(swipeDown)
//        miniPlayerView.layer.cornerRadius = 15
//        miniPlayerView.layer.masksToBounds = true
        
        sliderView.setValue(0, animated: false)
        sliderView.maximumTrackTintColor = .clear
        
        if audioPlayer != nil {
            showMiniPlayer(animated: false)
        } else {
            hideMiniPlayer(animated: false)
        }
        
        self.view.backgroundColor = .white
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            //Update your button here for the pause command
            self.miniPlayerView.playPauseButtonPressed(self)
            return .success
        }
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            //Update your button here for the pause command
            self.miniPlayerView.playPauseButtonPressed(self)
            return .success
        }
        commandCenter.skipForwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            //Update your button here for the pause command
            self.miniPlayerView.skipForward(self)
            return .success
        }
        commandCenter.skipBackwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            //Update your button here for the pause command
            self.miniPlayerView.skipBack(self)
            return .success
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(startUpdatingSlider), userInfo: nil, repeats: true)
    }
    
    public func hideMiniPlayer(animated: Bool) {
        
        baseView.layer.shadowOpacity = 0.0
        
        if animated {
            self.miniPlayerHeightConstraint.constant = 0
            self.sliderHeightConstraint.constant = 0
            sliderView.isHidden = true
            UIView.animate(withDuration: 1, animations: {
                self.view.layoutIfNeeded()
            })
        } else {
            sliderView.isHidden = true
            self.sliderHeightConstraint.constant = 0
            self.miniPlayerHeightConstraint.constant = 0
        }
    }
    
    public func showMiniPlayer(animated: Bool) {
        baseView.layer.shadowColor = UIColor.black.cgColor
        baseView.layer.shadowOpacity = 0.75
        baseView.layer.shadowOffset = CGSize.zero
        baseView.layer.shadowRadius = 5
        
        if audioPlayer != nil {
            let imageArt = UIImage(data: nowPlayingEpisode.podcast!.image!)
            miniPlayerView.artImageView.image = imageArt
            miniPlayerView.podcastTitle.text = nowPlayingEpisode.podcast?.title
            miniPlayerView.episodeTitle.text = nowPlayingEpisode.title
            if audioPlayer.isPlaying {
                miniPlayerView.playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
            } else {
                miniPlayerView.playPauseButton.setImage(UIImage(named: "play-50"), for: .normal)
            }
        }
        if animated {
            sliderView.isHidden = false
            self.sliderHeightConstraint.constant = 0
            self.miniPlayerHeightConstraint.constant = originalMiniPlayerHeightConstant
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
            })
        } else {
            sliderView.isHidden = false
            self.sliderHeightConstraint.constant = 0
            self.miniPlayerHeightConstraint.constant = originalMiniPlayerHeightConstant
        }
    }
    
    func setupNowPlaying(episode: CDEpisode) {
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "My Movie"
        if let image = UIImage(named: "lockscreen") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
            }
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer.currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = audioPlayer.duration
        //nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    @objc public func startUpdatingSlider() {
        if !miniPlayerView.progressSlider.isTracking {
            if let player = audioPlayer {
                if player.isPlaying
                {
                    // Update progress
                    sliderView.setValue(Float(player.currentTime/player.duration), animated: true)
                    miniPlayerView.progressSlider.setValue(Float(player.currentTime/player.duration), animated: true)
                }
            }
        }
    }
    
    public func setProgressBarColor(red: CGFloat, green: CGFloat, blue: CGFloat) {
        sliderView.minimumTrackTintColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        miniPlayerView.progressSlider.minimumTrackTintColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    public func getAverageColorOf(image: CGImage) -> UIColor {
        var bitmap = [UInt8](repeating: 0, count: 4)
        
        let context = CIContext(options: nil)
        let cgImg = context.createCGImage(CoreImage.CIImage(cgImage: image), from: CoreImage.CIImage(cgImage: image).extent)
        
        let inputImage = CIImage(cgImage: cgImg!)
        let extent = inputImage.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        let filter = CIFilter(name: "CIAreaAverage", withInputParameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent])!
        let outputImage = filter.outputImage!
        let outputExtent = outputImage.extent
        assert(outputExtent.size.width == 1 && outputExtent.size.height == 1)
        
        // Render to bitmap.
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: kCIFormatRGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        // Compute result.
        let result = UIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: 1.0)
        return result
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        if miniPlayerHeightConstraint.constant <= originalMiniPlayerHeightConstant { // make mini player full page
            // disable old leading and bottom constraints
            miniPlayerView.artImageViewLeadingConstraint.isActive = false
            miniPlayerView.artImageViewBottomConstraint.isActive = false
            
            // enable new constraints
            miniPlayerHeightConstraint.constant += baseView.bounds.height
            miniPlayerView.artImageViewCenterXConstraint.isActive = true
            miniPlayerView.artImageViewCenterYConstraint.isActive = true
            miniPlayerView.artImageViewHeightConstraint.constant = 300
            miniPlayerView.artImageViewWidthConstraint.constant = 300
            miniPlayerView.playPauseDistanceFromBottomConstraint.constant += 50
            miniPlayerView.backTenDistanceFromPlayConstraint.constant += 15
            miniPlayerView.forward30DistanceFromPlayConstraint.constant += 15
            miniPlayerView.playPauseHeightConstraint.constant += 40
            miniPlayerView.playPauseWidthConstraint.constant += 40
            miniPlayerView.chevronImage.isHidden = false
            miniPlayerView.podcastTitle.isHidden = false
            miniPlayerView.episodeTitle.isHidden = false
            
            miniPlayerView.progressSlider.isHidden = false
            
            UIView.animate(withDuration: 0.75, animations: {
                self.miniPlayerView.layoutSubviews()
                self.view.layoutSubviews()
            })
        }
    }
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        
//        if sender.state == .began || sender.state == .changed {
//            let translation = sender.translation(in: self.view)
//            // note: 'view' is optional and need to be unwrapped
//            miniPlayerHeightConstraint.constant = originalMiniPlayerHeightConstant-(translation.y)
//            self.view.layoutSubviews()
//        }
//        if sender.state == .ended {
//            let translation = sender.translation(in: self.view)
//
//            if miniPlayerHeightConstraint.constant == originalMiniPlayerHeightConstant { // show expanded mini player if threshold broken
//                if -translation.y < self.view.frame.maxY/8 { // if threshold is not broken
//                    miniPlayerHeightConstraint.constant = originalMiniPlayerHeightConstant
//                    UIView.animate(withDuration: 0.25, animations: {
//                        self.miniPlayerView.layoutSubviews()
//                        self.view.layoutSubviews()
//                    })
//                } else { // threshold is broken, enlarge mini player
//                 //disable old leading and bottom constraints
//                    miniPlayerView.artImageViewLeadingConstraint.isActive = false
//                    miniPlayerView.artImageViewBottomConstraint.isActive = false
//
//                    // enable new constraints
//                    miniPlayerHeightConstraint.constant += baseView.bounds.height
//                    miniPlayerView.artImageViewCenterXConstraint.isActive = true
//                    miniPlayerView.artImageViewCenterYConstraint.isActive = true
//                    miniPlayerView.artImageViewHeightConstraint.constant = 300
//                    miniPlayerView.artImageViewWidthConstraint.constant = 300
//                    miniPlayerView.playPauseDistanceFromBottomConstraint.constant += 50
//                    miniPlayerView.backTenDistanceFromPlayConstraint.constant += 15
//                    miniPlayerView.forward30DistanceFromPlayConstraint.constant += 15
//                    miniPlayerView.playPauseHeightConstraint.constant += 40
//                    miniPlayerView.playPauseWidthConstraint.constant += 40
//                    miniPlayerView.chevronImage.isHidden = false
//                    miniPlayerView.podcastTitle.isHidden = false
//                    miniPlayerView.episodeTitle.isHidden = false
//
//                    miniPlayerView.progressSlider.isHidden = false
//
//                    UIView.animate(withDuration: 0.25, animations: {
//                        self.miniPlayerView.layoutSubviews()
//                        self.view.layoutSubviews()
//                    })
//                }
//            } else {
//                if translation.y < -self.view.frame.maxY/8 { // if threshold is not broken
//                    // enable new constraints
//                    miniPlayerHeightConstraint.constant = baseView.bounds.height + translation.y
//
//
//                    UIView.animate(withDuration: 0.25, animations: {
//                        self.miniPlayerView.layoutSubviews()
//                        self.view.layoutSubviews()
//                    })
//                } else { // threshold is broken, shrink mini player
//                    //disable old leading and bottom constraints
//                    miniPlayerView.artImageViewCenterXConstraint.isActive = false
//                    miniPlayerView.artImageViewCenterYConstraint.isActive = false
//
//                    // enable new constraints
//                    miniPlayerHeightConstraint.constant = originalMiniPlayerHeightConstant
//                    miniPlayerView.artImageViewLeadingConstraint.isActive = true
//                    miniPlayerView.artImageViewBottomConstraint.isActive = true
//                    miniPlayerView.artImageViewHeightConstraint.constant = 60
//                    miniPlayerView.artImageViewWidthConstraint.constant = 60
//                    miniPlayerView.playPauseDistanceFromBottomConstraint.constant -= 50
//                    miniPlayerView.backTenDistanceFromPlayConstraint.constant -= 15
//                    miniPlayerView.forward30DistanceFromPlayConstraint.constant -= 15
//                    miniPlayerView.playPauseHeightConstraint.constant -= 40
//                    miniPlayerView.playPauseWidthConstraint.constant -= 40
//                    miniPlayerView.chevronImage.isHidden = true
//                    miniPlayerView.podcastTitle.isHidden = true
//                    miniPlayerView.episodeTitle.isHidden = true
//
//                    miniPlayerView.progressSlider.isHidden = true
//
//                    UIView.animate(withDuration: 0.75, animations: {
//                        self.miniPlayerView.layoutSubviews()
//                        self.view.layoutSubviews()
//                    })
//                }
//            }
//        }
        print(sender.direction)
        if miniPlayerHeightConstraint.constant > originalMiniPlayerHeightConstant { // make mini player small
            if sender.direction == .down {
                // disable old leading and bottom constraints
                miniPlayerView.artImageViewCenterXConstraint.isActive = false
                miniPlayerView.artImageViewCenterYConstraint.isActive = false

                // enable new constraints
                miniPlayerHeightConstraint.constant = originalMiniPlayerHeightConstant
                miniPlayerView.artImageViewLeadingConstraint.isActive = true
                miniPlayerView.artImageViewBottomConstraint.isActive = true
                miniPlayerView.artImageViewHeightConstraint.constant = 60
                miniPlayerView.artImageViewWidthConstraint.constant = 60
                miniPlayerView.playPauseDistanceFromBottomConstraint.constant -= 50
                miniPlayerView.backTenDistanceFromPlayConstraint.constant -= 15
                miniPlayerView.forward30DistanceFromPlayConstraint.constant -= 15
                miniPlayerView.playPauseHeightConstraint.constant -= 40
                miniPlayerView.playPauseWidthConstraint.constant -= 40
                miniPlayerView.chevronImage.isHidden = true
                miniPlayerView.podcastTitle.isHidden = true
                miniPlayerView.episodeTitle.isHidden = true

                miniPlayerView.progressSlider.isHidden = true

                UIView.animate(withDuration: 0.75, animations: {
                    self.miniPlayerView.layoutSubviews()
                    self.view.layoutSubviews()
                })
            }
        } else { // make mini player full screen
            if sender.direction == .up {
                // disable old leading and bottom constraints
                miniPlayerView.artImageViewLeadingConstraint.isActive = false
                miniPlayerView.artImageViewBottomConstraint.isActive = false

                // enable new constraints
                miniPlayerHeightConstraint.constant += baseView.bounds.height
                miniPlayerView.artImageViewCenterXConstraint.isActive = true
                miniPlayerView.artImageViewCenterYConstraint.isActive = true
                miniPlayerView.artImageViewHeightConstraint.constant = 300
                miniPlayerView.artImageViewWidthConstraint.constant = 300
                miniPlayerView.playPauseDistanceFromBottomConstraint.constant += 50
                miniPlayerView.backTenDistanceFromPlayConstraint.constant += 15
                miniPlayerView.forward30DistanceFromPlayConstraint.constant += 15
                miniPlayerView.playPauseHeightConstraint.constant += 40
                miniPlayerView.playPauseWidthConstraint.constant += 40
                miniPlayerView.chevronImage.isHidden = false
                miniPlayerView.podcastTitle.isHidden = false
                miniPlayerView.episodeTitle.isHidden = false

                miniPlayerView.progressSlider.isHidden = false

                UIView.animate(withDuration: 0.75, animations: {
                    self.miniPlayerView.layoutSubviews()
                    self.view.layoutSubviews()
                })
            }
        }
    }
}

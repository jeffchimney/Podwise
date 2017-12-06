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
        
        baseView.layer.shadowColor = UIColor.black.cgColor
        baseView.layer.shadowOpacity = 0.75
        baseView.layer.shadowOffset = CGSize.zero
        baseView.layer.shadowRadius = 5
        
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
        
        self.view.backgroundColor = .black
        
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(startUpdatingSlider), userInfo: nil, repeats: true)
    }
    
//    override func viewDidLayoutSubviews() {
//        let rectShape = CAShapeLayer()
//        rectShape.bounds = self.baseView.frame
//        rectShape.position = self.baseView.center
//        rectShape.path = UIBezierPath(roundedRect: self.baseView.bounds, byRoundingCorners: [.bottomLeft , .bottomRight], cornerRadii: CGSize(width: 25, height: 25)).cgPath
//
//        self.baseView.layer.backgroundColor = UIColor.green.cgColor
//        //Here I'm masking the textView's layer with rectShape layer
//        self.baseView.layer.masksToBounds = true
//        self.baseView.layer.mask = rectShape
//    }
    
    public func hideMiniPlayer(animated: Bool) {
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

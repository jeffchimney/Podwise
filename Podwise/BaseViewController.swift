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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var miniPlayerView: MiniPlayerView!
    @IBOutlet weak var miniPlayerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sliderHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sliderView: UISlider!
    override func viewDidLoad() {
        super.viewDidLoad()
        baseViewController = self
        
        miniPlayerView.artImageView.layer.cornerRadius = 10
        miniPlayerView.artImageView.layer.masksToBounds = true
        miniPlayerView.layer.cornerRadius = 15
        miniPlayerView.layer.masksToBounds = true
        
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
            self.sliderHeightConstraint.constant = 0
            sliderView.isHidden = true
            UIView.animate(withDuration: 1, animations: {
                self.miniPlayerView.alpha = 0
                self.view.layoutIfNeeded()
            })
        } else {
            sliderView.isHidden = true
            self.sliderHeightConstraint.constant = 0
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
            sliderView.isHidden = false
            self.sliderHeightConstraint.constant = 0
            self.miniPlayerHeightConstraint.constant = 70
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
            }, completion: { completed in
                UIView.animate(withDuration: 1, animations: {
                    self.miniPlayerView.alpha = 1
                })
            })
        } else {
            sliderView.isHidden = false
            self.sliderHeightConstraint.constant = 0
            self.miniPlayerHeightConstraint.constant = 70
            self.miniPlayerView.alpha = 1
        }
    }
    
    @objc public func startUpdatingSlider() {
        if !sliderView.isTracking {
            if let player = audioPlayer {
                if player.isPlaying
                {
                    // Update progress
                    sliderView.setValue(Float(player.currentTime/player.duration), animated: true)
                }
            }
        }
    }
    @IBAction func playheadChanged(_ sender: Any) {
        if let player = audioPlayer {
            // Update progress
            let percentComplete = sliderView.value
            //print(percentComplete)
            player.currentTime = player.duration * Double(percentComplete)
        }
    }
    
    public func setProgressBarColor(red: CGFloat, green: CGFloat, blue: CGFloat) {
        sliderView.minimumTrackTintColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
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
}

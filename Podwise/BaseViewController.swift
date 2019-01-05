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
var downloads: [Download]!
var nowPlayingEpisode: CDEpisode!
var baseViewController: BaseViewController!
let audioSession = AVAudioSession.sharedInstance()
var playlistQueue: [CDEpisode] = []

class BaseViewController: UIViewController, AVAudioPlayerDelegate {
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
    
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var miniPlayerView: MiniPlayerView!
    @IBOutlet weak var miniPlayerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sliderHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sliderView: UISlider!
    let originalMiniPlayerHeightConstant: CGFloat = 70
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    
    var interactor = Interactor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        baseViewController = self
        
        miniPlayerView.artImageView.layer.cornerRadius = 10
        miniPlayerView.artImageView.layer.masksToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        miniPlayerView.addGestureRecognizer(tap)
        
        sliderView.setValue(0, animated: false)
        sliderView.maximumTrackTintColor = UIColor.lightText
        if audioPlayer != nil {
            showMiniPlayer(animated: false)
        } else {
            hideMiniPlayer(animated: false)
        }

        self.view.backgroundColor = .white
        
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
        
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipBackwardCommand.preferredIntervals = [10]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if let player = audioPlayer {
            if !player.isPlaying {
                miniPlayerView.playPauseButton.setImage(UIImage(named: "play-50"), for: .normal)
            } else {
                miniPlayerView.playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
            }
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(startUpdatingSlider), userInfo: nil, repeats: true)
        
        miniPlayerView.layer.borderWidth = 1
        miniPlayerView.layer.borderColor = UIColor(red:169/255, green:169/255, blue:169/255, alpha: 0.5).cgColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        print("Base View is Disappearing")
    }
    
    public func hideMiniPlayer(animated: Bool) {
        
        baseView.layer.shadowOpacity = 0.0
        
        self.sliderHeightConstraint.constant = 0
        self.miniPlayerHeightConstraint.constant = 0
        if animated {
            sliderView.isHidden = true
            UIView.animate(withDuration: 0.25, animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                UIView.animate(withDuration: 0.25, animations: {
                    self.miniPlayerView.artImageView.alpha = 0
                    self.miniPlayerView.playPauseButton.alpha = 0
                    self.miniPlayerView.skipBackButton.alpha = 0
                    self.miniPlayerView.skipForwardButton.alpha = 0
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    self.miniPlayerView.artImageView.isHidden = true
                    self.miniPlayerView.playPauseButton.isHidden = true
                    self.miniPlayerView.skipBackButton.isHidden = true
                    self.miniPlayerView.skipForwardButton.isHidden = true
                })
            })
        } else {
            sliderView.isHidden = true
            miniPlayerView.artImageView.isHidden = true
            miniPlayerView.playPauseButton.isHidden = true
            miniPlayerView.skipBackButton.isHidden = true
            miniPlayerView.skipForwardButton.isHidden = true
            miniPlayerView.artImageView.alpha = 0
            miniPlayerView.playPauseButton.alpha = 0
            miniPlayerView.skipBackButton.alpha = 0
            miniPlayerView.skipForwardButton.alpha = 0
        }
    }
    
    public func showMiniPlayer(animated: Bool) {
        
        if audioPlayer != nil {
            let imageArt = UIImage(data: nowPlayingEpisode.podcast!.image!)
            miniPlayerView.artImageView.image = imageArt
            if audioPlayer.isPlaying {
                miniPlayerView.playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
            } else {
                miniPlayerView.playPauseButton.setImage(UIImage(named: "play-50"), for: .normal)
            }
        }
        
        self.sliderHeightConstraint.constant = 0
        self.miniPlayerHeightConstraint.constant = originalMiniPlayerHeightConstant
        miniPlayerView.artImageView.isHidden = false
        miniPlayerView.playPauseButton.isHidden = false
        miniPlayerView.skipBackButton.isHidden = false
        miniPlayerView.skipForwardButton.isHidden = false
        if animated {
            sliderView.isHidden = false
            UIView.animate(withDuration: 0.25, animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                UIView.animate(withDuration: 0.25, animations: {
                    self.miniPlayerView.artImageView.alpha = 1
                    self.miniPlayerView.playPauseButton.alpha = 1
                    self.miniPlayerView.skipBackButton.alpha = 1
                    self.miniPlayerView.skipForwardButton.alpha = 1
                })
            })
        } else {
            sliderView.isHidden = false
            self.miniPlayerView.artImageView.alpha = 1
            self.miniPlayerView.playPauseButton.alpha = 1
            self.miniPlayerView.skipBackButton.alpha = 1
            self.miniPlayerView.skipForwardButton.alpha = 1
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
        let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent])!
        let outputImage = filter.outputImage!
        let outputExtent = outputImage.extent
        assert(outputExtent.size.width == 1 && outputExtent.size.height == 1)
        
        // Render to bitmap.
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: CIFormat.RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        // Compute result.
        let result = UIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: 1.0)
        return result
    }
    
    @IBAction func openPlayerGesture(sender: UIPanGestureRecognizer) {
//        let translation = sender.translation(in: view)
//
//        let progress = MiniPlayerTransitionHelper.calculateProgress(translationInView: translation, viewBounds: view.bounds, direction: .Up)
//
//        MiniPlayerTransitionHelper.mapGestureStateToInteractor(
//            gestureState: sender.state,
//            progress: progress,
//            interactor: interactor){
//                expandNowPlaying()
//        }
        expandNowPlaying()
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        expandNowPlaying()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if playlistQueue.contains(nowPlayingEpisode) {
            let indexToRemove = playlistQueue.index(of: nowPlayingEpisode)
            if indexToRemove != nil {
                playlistQueue.remove(at: indexToRemove!)
            }
        }
        
        if UserDefaultsHelper.getDeleteAfterEpisodeFinishes() {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "EpisodeEnded"), object: nowPlayingEpisode)
            CoreDataHelper.delete(episode: nowPlayingEpisode, in: managedContext)
        }
        
        if UserDefaultsHelper.getAutoPlayNextEpisode() {
            if playlistQueue.count > 0 {
                AudioHelper.playDownload(for: playlistQueue[0])
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PlayNextEpisodeAnimation"), object: nil)
            } else {
                hideMiniPlayer(animated: true)
            }
        } else {
            hideMiniPlayer(animated: true)
        }
    }
}

extension BaseViewController: UIViewControllerTransitioningDelegate {
//    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        return PresentMiniPlayerAnimator()
//    }
//    
//    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        return DismissMiniPlayerAnimator()
//    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}

extension BaseViewController {
    func expandNowPlaying() {
        
        guard let nowPlayingCard = storyboard?.instantiateViewController(
            withIdentifier: "playerViewController")
            as? PlayerViewController else {
                assertionFailure("No view controller ID playerViewController in storyboard")
                return
        }
        //nowPlayingCard.transitioningDelegate = self
        //nowPlayingCard.interactor = interactor
        
        let imageArt = UIImage(data: nowPlayingEpisode.podcast!.image!)
        nowPlayingCard.image = imageArt
        nowPlayingCard.episodeTitleText = nowPlayingEpisode.title!
        nowPlayingCard.podcastTitleText = nowPlayingEpisode.podcast!.title!
        nowPlayingCard.minimumTrackTintColor = sliderView.minimumTrackTintColor
        nowPlayingCard.backingImage = view.makeSnapshot()
        nowPlayingCard.sourceView = miniPlayerView
        present(nowPlayingCard, animated: false)
    }
}

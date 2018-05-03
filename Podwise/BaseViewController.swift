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
var autoPlay = false
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        print("Base View is Disappearing")
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
//        baseView.layer.shadowColor = UIColor.black.cgColor
//        baseView.layer.shadowOpacity = 0.75
//        baseView.layer.shadowOffset = CGSize.zero
//        baseView.layer.shadowRadius = 5
        
        if audioPlayer != nil {
            let imageArt = UIImage(data: nowPlayingEpisode.podcast!.image!)
            miniPlayerView.artImageView.image = imageArt
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
    
//    func setupNowPlaying(episode: CDEpisode) {
//        // Define Now Playing Info
//        var nowPlayingInfo = [String : Any]()
//        nowPlayingInfo[MPMediaItemPropertyTitle] = "My Movie"
//        if let image = UIImage(named: "lockscreen") {
//            nowPlayingInfo[MPMediaItemPropertyArtwork] =
//                MPMediaItemArtwork(boundsSize: image.size) { size in
//                    return image
//            }
//        }
//        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer.currentTime
//        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = audioPlayer.duration
//        //nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
//        
//        // Set the metadata
//        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
//    }
    
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
    
    @IBAction func openPlayerGesture(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        let progress = MiniPlayerTransitionHelper.calculateProgress(translationInView: translation, viewBounds: view.bounds, direction: .Up)
        
        MiniPlayerTransitionHelper.mapGestureStateToInteractor(
            gestureState: sender.state,
            progress: progress,
            interactor: interactor){
                self.performSegue(withIdentifier: "openPlayer", sender: nil)
        }
    }
    
    @IBAction func openMenu(sender: AnyObject) {
        performSegue(withIdentifier: "openMenu", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? PlayerViewController {
            destinationViewController.transitioningDelegate = self
            destinationViewController.interactor = interactor
            
            let imageArt = UIImage(data: nowPlayingEpisode.podcast!.image!)
            destinationViewController.image = imageArt
            destinationViewController.episodeTitleText = nowPlayingEpisode.title!
            destinationViewController.podcastTitleText = nowPlayingEpisode.podcast!.title!
            destinationViewController.minimumTrackTintColor = sliderView.minimumTrackTintColor
        }
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "openPlayer", sender: nil)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if autoPlay {
            if playlistQueue.contains(nowPlayingEpisode) {
                let indexToRemove = playlistQueue.index(of: nowPlayingEpisode)
                if indexToRemove != nil {
                    playlistQueue.remove(at: indexToRemove!)
                }
                CoreDataHelper.delete(episode: nowPlayingEpisode, in: managedContext)
                
                if playlistQueue.count > 0 {
                    playDownload(for: playlistQueue[0])
                } else {
                    hideMiniPlayer(animated: true)
                }
            }
        }
    }
    
    func playDownload(for episode: CDEpisode) {
        // then lets create your document folder url
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // lets create your destination file url
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(episode.localURL!.lastPathComponent)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: destinationUrl)
            guard let player = audioPlayer else { return }
            player.delegate = self
            player.currentTime = TimeInterval(episode.progress)
            player.prepareToPlay()
            //startAudioSession()
            player.play()
            nowPlayingEpisode = episode
            autoPlay = true
            
            let artworkImage = UIImage(data: episode.podcast!.image!)
            let artwork = MPMediaItemArtwork.init(boundsSize: artworkImage!.size, requestHandler: { (size) -> UIImage in
                return artworkImage!
            })
            
            let mpic = MPNowPlayingInfoCenter.default()
            mpic.nowPlayingInfo = [MPMediaItemPropertyTitle:episode.title!,
                                   MPMediaItemPropertyArtist:episode.podcast!.title!,
                                   MPMediaItemPropertyArtwork: artwork,
                                   MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
                                   MPMediaItemPropertyPlaybackDuration: player.duration
            ]
            
            showMiniPlayer(animated: true)
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

extension BaseViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentMiniPlayerAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissMiniPlayerAnimator()
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}

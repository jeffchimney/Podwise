//
//  PlayerViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2018-01-05.
//  Copyright © 2018 Jeff Chimney. All rights reserved.
//

import UIKit

protocol PlayerViewSourceProtocol: class {
    var originatingFrameInWindow: CGRect { get }
    var originatingCoverImageView: UIImageView { get }
}

class PlayerViewController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate {
    
    // MARK: - Properties
    let cardCornerRadius: CGFloat = 10
    let primaryDuration = 0.5
    let backingImageEdgeInset: CGFloat = 15.0
    var image: UIImage!
    var episodeTitleText: String!
    var podcastTitleText: String!
    var minimumTrackTintColor: UIColor!
    weak var sourceView: PlayerViewSourceProtocol!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var showNotesView: UITextView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var artImageView: UIImageView!
    @IBOutlet weak var artImageBackgroundView: UIView!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var remainingTImeLabel: UILabel!
    @IBOutlet weak var upNextCollectionQueue: UICollectionView!
    @IBOutlet weak var collectionViewHC: NSLayoutConstraint!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var upNextView: UIView!
    @IBOutlet weak var swipeIndicator: UIProgressView!
    
    //backing image
    var backingImage: UIImage?
    @IBOutlet weak var backingImageView: UIImageView!
    @IBOutlet weak var dimmerLayer: UIView!
    @IBOutlet weak var backingImageTopInset: NSLayoutConstraint!
    @IBOutlet weak var backingImageLeadingInset: NSLayoutConstraint!
    @IBOutlet weak var backingImageTrailingInset: NSLayoutConstraint!
    @IBOutlet weak var backingImageBottomInset: NSLayoutConstraint!
    @IBOutlet weak var artImageViewTopInset: NSLayoutConstraint!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var interactor:Interactor? = nil
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        modalPresentationCapturesStatusBarAppearance = true //allow this VC to control the status bar appearance
        modalPresentationStyle = .overFullScreen //dont dismiss the presenting view controller when presented
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backingImageView.image = backingImage
        
        upNextCollectionQueue.contentInsetAdjustmentBehavior = .never
        scrollView.contentInsetAdjustmentBehavior = .never //dont let Safe Area insets affect the scroll view
        
        if let player = audioPlayer {
            if !player.isPlaying {
                playPauseButton.setImage(UIImage(named: "play-50"), for: .normal)
            } else {
                playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
            }
        }
        
        weak var thumbImage = UIImage(named: "first")
        
        let horizontalRatio: CGFloat = 0.5
        let verticalRatio: CGFloat = 0.5
        
        let ratio = max(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: (thumbImage?.size.width)! * ratio, height: (thumbImage?.size.height)! * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        view.draw(CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        thumbImage = newImage!
        
        progressSlider.minimumTrackTintColor = minimumTrackTintColor
        artImageView.image = image
        episodeTitle.text = episodeTitleText
        
        progressSlider.setThumbImage(thumbImage, for: .normal)
        
        startUpdatingSlider()
        
        artImageView.isUserInteractionEnabled = true
        artImageView.layer.cornerRadius = 10
        artImageView.layer.masksToBounds = true
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width, height: upNextCollectionQueue.frame.height)
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        
        upNextCollectionQueue.dataSource = self
        upNextCollectionQueue.delegate = self
        upNextCollectionQueue.collectionViewLayout = layout
        let upNextCellNib = UINib(nibName: "UpNextCell", bundle: nil)
        upNextCollectionQueue.register(upNextCellNib, forCellWithReuseIdentifier: "UpNextCell")
        
        
        var unformattedShowNotes = nowPlayingEpisode.showNotes ?? "There was a problem loading show notes."
        
        if unformattedShowNotes.range(of:"<a href") != nil {
            unformattedShowNotes = unformattedShowNotes.replacingOccurrences(of: "<a href", with: "<br><a href")
        }
        
        print(unformattedShowNotes)

        let showNotesString = NSMutableAttributedString(attributedString: unformattedShowNotes.htmlToAttributedString!)
        
        // Enumerate through all the font ranges
        showNotesString.enumerateAttribute(NSAttributedString.Key.font, in: NSMakeRange(0, showNotesString.length), options: [])
        {
            value, range, stop in
            guard let currentFont = value as? UIFont else {
                return
            }
            
            // An NSFontDescriptor describes the attributes of a font: family name, face name, point size, etc.
            // Here we describe the replacement font as coming from the "Hoefler Text" family
            let fontDescriptor = currentFont.fontDescriptor//.addingAttributes([UIFontDescriptor.AttributeName.family: "Hoefler Text"])
            
            // Ask the OS for an actual font that most closely matches the description above
            if let newFontDescriptor = fontDescriptor.matchingFontDescriptors(withMandatoryKeys: [UIFontDescriptor.AttributeName.family]).first {
                let newFont = UIFont(descriptor: newFontDescriptor, size: 16.0)
                showNotesString.addAttributes([NSAttributedString.Key.font: newFont], range: range)
            }
        }
        
        showNotesView.attributedText = showNotesString
        showNotesView.delegate = self
        showNotesView.isSelectable = true
        showNotesView.isUserInteractionEnabled = true
        
        scrollView.delegate = self
        
        scrollView.layer.cornerRadius = cardCornerRadius
        scrollView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        stackView.layer.cornerRadius = cardCornerRadius
        stackView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        artImageBackgroundView.layer.cornerRadius = cardCornerRadius
        artImageBackgroundView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(startUpdatingSlider), userInfo: nil, repeats: true)
        
        configureImageLayerInStartPosition()
        
        if playlistQueue.count > 0 {
            collectionViewHC.constant = CGFloat((playlistQueue.count - 1) * 70)
            view.layoutIfNeeded()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateBackingImageIn()
        animateImageLayerIn()
    }
        
    @IBAction func handleGesture(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        let progress = MiniPlayerTransitionHelper.calculateProgress(
            translationInView: translation,
            viewBounds: view.bounds,
            direction: .Down
        )
        MiniPlayerTransitionHelper.mapGestureStateToInteractor(
            gestureState: sender.state,
            progress: progress,
            interactor: interactor
        ){
            animateBackingImageOut()
            animateImageLayerOut() { _ in
                self.dismiss(animated: false)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let translation = scrollView.contentOffset
        
        if translation.y < 0 {
            swipeIndicator.alpha = 0.8 + (translation.y/100)
        }
        
        if translation.y < -80 {
            let impact = UIImpactFeedbackGenerator()
            impact.prepare()
            impact.impactOccurred()
            animateBackingImageOut()
            animateImageLayerOut() { _ in
                self.dismiss(animated: false)
            }
//            let progress = MiniPlayerTransitionHelper.calculateProgress(
//                translationInView: translation,
//                viewBounds: view.bounds,
//                direction: .Down
//            )
//
//            MiniPlayerTransitionHelper.mapGestureStateToInteractor(
//                gestureState: scrollView.gestureRecognizers?.first!.state ?? .ended,
//                progress: progress,
//                interactor: interactor){
//                    // 6
//                    self.dismiss(animated: true, completion: nil)
//            }
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
                AudioHelper.updateMediaPlayer(player: player)
                
                CoreDataHelper.save(context: managedContext!)
                player.pause()
            } else {
                playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
                player.play()
            }
        }
    }
    
    @objc public func startUpdatingSlider() {
        if !progressSlider.isTracking {
            if let player = audioPlayer {
                if player.isPlaying
                {
                    // Update progress
                    progressSlider.setValue(Float(player.currentTime/player.duration), animated: true)
                    
                    let formatter = DateComponentsFormatter()
                    formatter.unitsStyle = .positional
                    formatter.allowedUnits = [ .minute, .second ]
                    formatter.zeroFormattingBehavior = [ .pad ]
                    
                    let elapsedTime = formatter.string(from: player.currentTime)
                    let remainingTime = formatter.string(from: player.duration - player.currentTime)
                    
                    elapsedTimeLabel.text = elapsedTime
                    remainingTImeLabel.text = remainingTime
                }
            }
        }
    }
    
    @IBAction func skipBack(_ sender: Any) {
        if let player = audioPlayer {
            // Update progress
            player.currentTime = player.currentTime.advanced(by: -10)
            AudioHelper.updateMediaPlayer(player: player)
            baseViewController.sliderView.setValue(Float(player.currentTime/player.duration), animated: true)
        }
    }
    
    @IBAction func skipForward(_ sender: Any) {
        if let player = audioPlayer {
            // Update progress
            player.currentTime = player.currentTime.advanced(by: 30)
            AudioHelper.updateMediaPlayer(player: player)
            baseViewController.sliderView.setValue(Float(player.currentTime/player.duration), animated: true)
        }
    }
    
    @IBAction func playheadChanged(_ sender: Any) {
        if let player = audioPlayer {
            // Update progress
            let percentComplete = progressSlider.value
            player.currentTime = player.duration * Double(percentComplete)
            
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .positional
            formatter.allowedUnits = [ .minute, .second ]
            formatter.zeroFormattingBehavior = [ .pad ]
            
            let elapsedTime = formatter.string(from: player.currentTime)
            let remainingTime = formatter.string(from: player.duration - player.currentTime)
            
            elapsedTimeLabel.text = elapsedTime
            remainingTImeLabel.text = remainingTime
            
            AudioHelper.updateMediaPlayer(player: player)
        }
    }
    
    // collection view stubs
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if playlistQueue.count > 0 {
            return playlistQueue.count - 1
        } else {
            return 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = upNextCollectionQueue.dequeueReusableCell(withReuseIdentifier:"UpNextCell", for: indexPath as IndexPath) as! UpNextCell
        
        let indexPathRow = indexPath.row+1
        if let imageData = playlistQueue[indexPathRow].podcast?.image {
            cell.artImageView.image = UIImage(data: imageData)
        }
        
        cell.artImageView.layer.cornerRadius = 10
        cell.artImageView.layer.masksToBounds = true
        cell.titleLabel.text = playlistQueue[indexPathRow].podcast?.title
        cell.descriptionLabel.text = playlistQueue[indexPathRow].title
        
        return cell
    };
}

//background image animation
extension PlayerViewController {
    
    private func configureBackingImageInPosition(presenting: Bool) {
        let edgeInset: CGFloat = presenting ? backingImageEdgeInset : 0
        let dimmerAlpha: CGFloat = presenting ? 0.3 : 0
        let cornerRadius: CGFloat = presenting ? cardCornerRadius : 0
        
        backingImageLeadingInset.constant = edgeInset
        backingImageTrailingInset.constant = -edgeInset
        let aspectRatio = backingImageView.frame.height / backingImageView.frame.width
        backingImageTopInset.constant = edgeInset * aspectRatio
        backingImageBottomInset.constant = edgeInset * aspectRatio
        dimmerLayer.alpha = dimmerAlpha
        backingImageView.layer.cornerRadius = cornerRadius
    }
    
    private func animateBackingImage(presenting: Bool) {
        UIView.animate(withDuration: primaryDuration) {
            self.configureBackingImageInPosition(presenting: presenting)
            self.view.layoutIfNeeded()
        }
    }
    
    func animateBackingImageIn() {
        animateBackingImage(presenting: true)
    }
    
    func animateBackingImageOut() {
        animateBackingImage(presenting: false)
    }
}

//Image Container animation.
extension PlayerViewController {
    
    private var startColor: UIColor {
        return UIColor.white.withAlphaComponent(0.3)
    }
    
    private var endColor: UIColor {
        return .white
    }
    
    private var imageLayerInsetForOutPosition: CGFloat {
        let imageFrame = view.convert(sourceView.originatingFrameInWindow, to: view)
        let inset = imageFrame.minY - backingImageEdgeInset
        return inset
    }
    
    func configureImageLayerInStartPosition() {
        artImageBackgroundView.backgroundColor = startColor
        let startInset = imageLayerInsetForOutPosition
        //dismissChevron.alpha = 0
        artImageBackgroundView.layer.cornerRadius = 0
        artImageViewTopInset.constant = startInset
        view.layoutIfNeeded()
    }
    
    func animateImageLayerIn() {
        UIView.animate(withDuration: primaryDuration) {
            self.artImageBackgroundView.backgroundColor = self.endColor
        }
        
        UIView.animate(withDuration: primaryDuration, delay: 0, options: [.curveEaseIn], animations: {
            self.artImageViewTopInset.constant = 0
            //self.dismissChevron.alpha = 1
            self.artImageBackgroundView.layer.cornerRadius = self.cardCornerRadius
            self.view.layoutIfNeeded()
        })
    }
    
    func animateImageLayerOut(completion: @escaping ((Bool) -> Void)) {
        let endInset = imageLayerInsetForOutPosition
        
        UIView.animate(withDuration: primaryDuration,
                       delay: 0,
                       options: [.curveEaseOut], animations: {
                        self.artImageBackgroundView.backgroundColor = self.startColor
        }, completion: { finished in
            completion(finished) //fire complete here , because this is the end of the animation
        })
        
        UIView.animate(withDuration: primaryDuration, delay: 0, options: [.curveEaseOut], animations: {
            self.artImageViewTopInset.constant = endInset
            //self.dismissChevron.alpha = 0
            self.artImageBackgroundView.layer.cornerRadius = 0
            self.view.layoutIfNeeded()
        })
    }
}

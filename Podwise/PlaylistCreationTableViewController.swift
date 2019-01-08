//
//  PlaylistCreationTableViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-27.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import CoreData
import UIKit

public protocol savePlaylistDelegate: class {
    func saveButtonPressed(playlistName: String)
    func dismissPlaylist()
}

class PlaylistCreationTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, savePlaylistDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var playlist: CDPlaylist!
    var podcasts: [CDPodcast] = []
    var podcastsInPlaylist: [CDPodcast] = []
    var selectedPodcasts: [CDPodcast] = []
    @IBOutlet weak var saveButton: UIBarButtonItem!
    //weak var managedContext: NSManagedObjectContext?
    weak var relayoutSectionDelegate: relayoutSectionDelegate!
    var colour = UIColor()
    var colourSet = false
    
    //fileprivate let sectionInsets = UIEdgeInsets(top: 0, left: 8.0, bottom: 4.0, right: 8.0)
        fileprivate let sectionInsets = UIEdgeInsets(top: 4.0, left: 8.0, bottom: 4.0, right: 8.0)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        podcasts = CoreDataHelper.getPodcastsWhere(subscribed: true, in: managedContext!)
        podcasts.sort(by: { $0.title! < $1.title!})
        
        if playlist != nil {
            podcastsInPlaylist = CoreDataHelper.fetchPodcastsFor(playlist: playlist, in: managedContext!)
            saveButton.title = "Save"
        } else {
            saveButton.title = "Create"
        }
        
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "PlaylistCell", bundle: nil), forCellReuseIdentifier: "PlaylistGroupCell")
        let headerViewNib = UINib(nibName: "NewPlaylistHeaderView", bundle: nil)
        tableView.register(headerViewNib, forHeaderFooterViewReuseIdentifier: "SubscriptionSectionHeader")
        
        self.transitioningDelegate = self
        
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        
        colour = UIColor(displayP3Red: 0, green: 122/255, blue: 255/255, alpha: 1.0)
        
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return podcasts.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 50
        } else {
            return 80
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Dequeue with the reuse identifier
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SubscriptionSectionHeader") as! NewPlaylistHeaderView
        headerView.textField.delegate = headerView
        if playlist != nil {
            headerView.textField.text = playlist.name
            headerView.saveButton.setTitle("Save", for: .normal)
            
            let playlistColour = NSKeyedUnarchiver.unarchiveObject(with: playlist.colour!) as? UIColor
            headerView.contentView.backgroundColor = playlistColour
        } else {
            headerView.saveButton.setTitle("Create", for: .normal)
            headerView.contentView.backgroundColor = UIColor(displayP3Red: 0, green: 122/255, blue: 255/255, alpha: 1.0)
        }
        headerView.savePlaylistDelegate = self
        headerView.isUserInteractionEnabled = true
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistColourCell") as! PlaylistColourCell
            
            cell.purpleButton.layer.cornerRadius = 20
            cell.purpleButton.layer.masksToBounds = true
            cell.blueButton.layer.cornerRadius = 20
            cell.blueButton.layer.masksToBounds = true
            cell.greenButton.layer.cornerRadius = 20
            cell.greenButton.layer.masksToBounds = true
            cell.yellowButton.layer.cornerRadius = 20
            cell.yellowButton.layer.masksToBounds = true
            cell.orangeButton.layer.cornerRadius = 20
            cell.orangeButton.layer.masksToBounds = true
            cell.redButton.layer.cornerRadius = 20
            cell.redButton.layer.masksToBounds = true
            cell.greyButton.layer.cornerRadius = 20
            cell.greyButton.layer.masksToBounds = true
            
            //cell.layer.cornerRadius = 15
            //cell.layer.masksToBounds = true
            
            return cell
        } else {
            let indexPathRow = indexPath.row - 1
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistGroupCell", for: indexPath as IndexPath) as! PlaylistCell
            cell.episodeCounterLabel.isHidden = true
            let thisPodcast: CDPodcast = podcasts[indexPathRow]
            
            cell.titleLabel.text = thisPodcast.title
            cell.durationLabel.text = thisPodcast.author
            //cell.percentDowloadedLabel.isHidden = true
            if podcastsInPlaylist.contains(podcasts[indexPathRow]) {
                cell.accessoryType = .checkmark
                selectedPodcasts.append(podcasts[indexPathRow])
            }
            
            cell.titleLabel.text = podcasts[indexPathRow].title
            cell.durationLabel.text = podcasts[indexPathRow].author
            
            cell.artImageView.image = UIImage.image(with: podcasts[indexPathRow].image!)
            
            cell.artImageView.layer.cornerRadius = 3
            cell.artImageView.layer.masksToBounds = true
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let indexPathRow = indexPath.row - 1
        if indexPath.row > 0 {
            let cell = tableView.cellForRow(at: indexPath) as! PlaylistCell
            if cell.accessoryType == .checkmark { // deselect row
                DispatchQueue.main.async {
                    cell.accessoryType = .none
                }
                if selectedPodcasts.contains(podcasts[indexPathRow]) {
                    let index = selectedPodcasts.index(of: podcasts[indexPathRow])
                    selectedPodcasts.remove(at: index!)
                    
                    removeFromPlaylist(podcast: podcasts[indexPathRow])
                }
            } else { // select row
                DispatchQueue.main.async {
                    cell.accessoryType = .checkmark
                }
                selectedPodcasts.append(podcasts[indexPathRow])
            }
        }
    }
    
    func createPlaylist(playlistName: String, selectedPodcasts: [CDPodcast]) {
        let colourData = NSKeyedArchiver.archivedData(withRootObject: colour)
        
        if playlist == nil {
            let existingPlaylists = CoreDataHelper.fetchAllPlaylists(in: managedContext!)
            var playlistAlreadyExists = false
            var preexistingPlaylist: CDPlaylist!
            for existingPlaylist in existingPlaylists {
                if existingPlaylist.name == playlistName {
                    playlistAlreadyExists = true
                    preexistingPlaylist = existingPlaylist
                    preexistingPlaylist.colour = colourData
                }
            }
            
            if !playlistAlreadyExists {
                let playlistEntity = NSEntityDescription.entity(forEntityName: "CDPlaylist", in: managedContext!)!
                let newPlaylist = NSManagedObject(entity: playlistEntity, insertInto: managedContext) as! CDPlaylist
                
                newPlaylist.name = playlistName
                let sortIndex = CoreDataHelper.getHighestPlaylistSortIndex(in: managedContext!)
                newPlaylist.sortIndex = (Int64(sortIndex + Int(1)))
                newPlaylist.id = UUID().uuidString
                newPlaylist.colour = colourData
                newPlaylist.isCollapsed = false

                for podcast in selectedPodcasts {
                    podcast.playlist = newPlaylist
                }
            } else {
                for podcast in selectedPodcasts {
                    podcast.playlist = preexistingPlaylist
                }
            }
            
            CoreDataHelper.save(context: managedContext!)
        } else {
            playlist.name = playlistName
            
            if colourSet {
                playlist.colour = colourData
            }

            for podcast in selectedPodcasts {
                podcast.playlist = playlist
            }
            
            CoreDataHelper.save(context: managedContext!)
        }
        
        relayoutSectionDelegate.reloadCollectionView()
        
        dismiss(animated: true, completion: nil)
    }
    
    func add(podcast: CDPodcast, to playlist: CDPlaylist) {
        podcast.playlist = playlist
        CoreDataHelper.save(context: managedContext!)
    }
    
    func removeFromPlaylist(podcast: CDPodcast) {
        podcast.playlist = CoreDataHelper.fetchAllPlaylists(with: "Unsorted", in: managedContext!)[0]
        CoreDataHelper.save(context: managedContext!)
    }
    
    @IBAction func setPlaylistColour(_ sender: Any) {
        
        let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! PlaylistColourCell
        let buttonPressed = sender as! UIButton
        switch buttonPressed {
        case cell.purpleButton:
            colour = UIColor(displayP3Red: 88/255, green: 86/255, blue: 214/255, alpha: 1.0)
        case cell.blueButton:
            colour = UIColor(displayP3Red: 0, green: 122/255, blue: 255/255, alpha: 1.0)
        case cell.greenButton:
            colour = UIColor(displayP3Red: 76/255, green: 217/255, blue: 100/255, alpha: 1.0)
        case cell.yellowButton:
            colour = UIColor(displayP3Red: 255/255, green: 204/255, blue: 0, alpha: 1.0)
        case cell.orangeButton:
            colour = UIColor(displayP3Red: 255/255, green: 149/255, blue: 0, alpha: 1.0)
        case cell.redButton:
            colour = UIColor(displayP3Red: 255/255, green: 59/255, blue: 48/255, alpha: 1.0)
        case cell.greyButton:
            colour = UIColor(displayP3Red: 142/255, green: 142/255, blue: 147/255, alpha: 1.0)
        default:
            print("default")
        }
        
        let headerView = tableView.headerView(forSection: 0) as! NewPlaylistHeaderView
        headerView.contentView.backgroundColor = colour
        colourSet = true
    }
    
    func saveButtonPressed(playlistName: String) {
        createPlaylist(playlistName: playlistName, selectedPodcasts: selectedPodcasts)
    }
    
    func dismissPlaylist() {
        dismiss(animated: true, completion: nil  )
    }
}

extension PlaylistCreationTableViewController: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if presented == self {
            return PresentationController(presentedViewController: presented, presenting: presenting)
        }
        return nil
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented == self {
            return CardAnimationController(isPresenting: true)
        } else {
            return nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed == self {
            return CardAnimationController(isPresenting: false)
        } else {
            return nil
        }
    }
}

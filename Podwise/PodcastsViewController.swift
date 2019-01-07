//
//  SecondViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-16.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData

public protocol reloadTableViewDelegate: class {
    func reloadTableView()
}

class PodcastsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerPreviewingDelegate, reloadTableViewDelegate {
    
    var subscribedPodcasts: [CDPodcast] = []
    var unSubscribedPodcasts: [CDPodcast] = []
    //weak var managedContext: NSManagedObjectContext?
    fileprivate let sectionInsets = UIEdgeInsets(top: 4.0, left: 8.0, bottom: 4.0, right: 8.0)
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.dataSource = self
        tableView.delegate = self
        
        if( traitCollection.forceTouchCapability == .available){
            registerForPreviewing(with: self, sourceView: view)
        }
        
        tableView.register(UINib(nibName: "PlaylistCell", bundle: nil), forCellReuseIdentifier: "PlaylistGroupCell")
        tableView.register(UINib(nibName: "FooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "footerView")
        
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 0.1))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        subscribedPodcasts = CoreDataHelper.getPodcastsWhere(subscribed: true, in: managedContext!)
        subscribedPodcasts.sort(by: { $0.title! < $1.title!})
        
        let unSubscribedPodcastsUnfiltered = CoreDataHelper.getPodcastsWhere(subscribed: false, in: managedContext!)
        unSubscribedPodcasts = []
        for podcast in unSubscribedPodcastsUnfiltered {
            let episodesForPodcast = CoreDataHelper.fetchEpisodesFor(podcast: podcast, in: managedContext!)
            if episodesForPodcast.count > 0 {
                unSubscribedPodcasts.append(podcast)
            }
        }
        unSubscribedPodcasts.sort(by: { $0.title! < $1.title!})
        
        tableView.reloadData()
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return subscribedPodcasts.count + 1
        } else {
            return unSubscribedPodcasts.count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 40
        } else {
            return 80
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "footerView") as? PlaylistFooterView  {
            if section == 0 {
                let subscribedColour = UIColor(displayP3Red: 0, green: 122/255, blue: 255/255, alpha: 1.0)
                footerView.footerBackgroundView.backgroundColor = subscribedColour
            } else {
                let unsubscribedColour = UIColor(displayP3Red: 255/255, green: 149/255, blue: 0, alpha: 1.0)
                footerView.footerBackgroundView.backgroundColor = unsubscribedColour
            }
            
            footerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30)
            footerView.center = CGPoint(x: tableView.center.x, y: footerView.center.y)
            
            // round top left and right corners
            let cornerRadius: CGFloat = 5
            let maskLayer = CAShapeLayer()
            
            maskLayer.path = UIBezierPath(
                roundedRect: footerView.bounds,
                byRoundingCorners: [.bottomLeft, .bottomRight],
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
                ).cgPath
            
            footerView.layer.mask = maskLayer
            footerView.collapseExpandButton.isHidden = true
            
//            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:)))
//            tap.delegate = self
//            footerView.addGestureRecognizer(tap)
//
//            if playlistStructArray[section].name.isCollapsed {
//                let image = UIImage(named: "down_arrow_24")
//                footerView.collapseExpandButton.setImage(image, for: .normal)
//            } else {
//                let image = UIImage(named: "up_arrow_24")
//                footerView.collapseExpandButton.setImage(image, for: .normal)
//            }
//            footerView.collapseExpandButton.transform = .identity
//            let tapButton = UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:)))
//            tapButton.delegate = self
//            footerView.collapseExpandButton.addGestureRecognizer(tapButton)
            
            return footerView
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell", for: indexPath as IndexPath) as! PlaylistTitleCell
                    
            if indexPath.section == 0 {
                cell.titleTextField.text = "Subscribed"
                let subscribedColour = UIColor(displayP3Red: 0, green: 122/255, blue: 255/255, alpha: 1.0)
                cell.contentView.backgroundColor = subscribedColour
            } else {
                cell.titleTextField.text = "Not Subscribed"
                let unsubscribedColour = UIColor(displayP3Red: 255/255, green: 149/255, blue: 0, alpha: 1.0)
                cell.contentView.backgroundColor = unsubscribedColour
            }
            cell.editPlaylistButton.isHidden = true
            cell.isUserInteractionEnabled = true
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistGroupCell", for: indexPath as IndexPath) as! PlaylistCell
            let thisPodcast: CDPodcast!
            
            if indexPath.section == 0 {
                thisPodcast = subscribedPodcasts[indexPath.row-1]
            } else {
                thisPodcast = unSubscribedPodcasts[indexPath.row-1]
            }
            
            let episodes = CoreDataHelper.fetchEpisodesFor(podcast: thisPodcast, in: managedContext!)
            
            if episodes.count == 0 {
                cell.episodeCounterLabel.isHidden = true
            } else {
                cell.episodeCounterLabel.text = String(episodes.count)
            }
            cell.titleLabel.text = thisPodcast.title
            cell.durationLabel.text = thisPodcast.author
            
            cell.artImageView.image = UIImage.image(with: thisPodcast.image!)
            
            cell.artImageView.layer.cornerRadius = 3
            cell.artImageView.layer.masksToBounds = true
            
            cell.episodeCounterLabel.backgroundColor = .black
            cell.episodeCounterLabel.textColor = .white
            
            cell.episodeCounterLabel.layer.cornerRadius = 9
            cell.episodeCounterLabel.layer.masksToBounds = true
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let podcast: CDPodcast!
        if indexPath.section == 0 {
            podcast = subscribedPodcasts[indexPath.row-1]
        } else {
            podcast = unSubscribedPodcasts[indexPath.row-1]
        }
        
        let resultViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "episodesViewController") as! EpisodesForPodcastViewController
        resultViewController.podcast = podcast
        navigationController?.pushViewController(resultViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let podcast: CDPodcast!
        if indexPath.section == 0 {
            podcast = subscribedPodcasts[indexPath.row-1]
        } else {
            podcast = unSubscribedPodcasts[indexPath.row-1]
        }
        
        let addToPlaylistAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            let alert = UIAlertController(title: "Add To Playlist", message: "", preferredStyle: .actionSheet)
            
            let playlists = CoreDataHelper.fetchAllPlaylists(in: managedContext!)
            
            for eachPlaylist in playlists {
                alert.addAction(UIAlertAction(title: eachPlaylist.name, style: .default, handler: { (action) in
                    self.add(podcast: podcast, to: eachPlaylist)
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
            success(true)
        })
        
        addToPlaylistAction.image = UIImage(named: "playlist")
        addToPlaylistAction.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
        
        return UISwipeActionsConfiguration(actions: [addToPlaylistAction])
    }
    
    func add(podcast: CDPodcast, to playlist: CDPlaylist) {
        podcast.playlist = playlist
        CoreDataHelper.save(context: managedContext!)
    }
    
    // MARK: - Preview Delegate Methods
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // convert point from position in self.view to position in warrantiesTableView
        let cellPosition = tableView.convert(location, from: self.view)
        
        guard let indexPath = tableView.indexPathForRow(at: cellPosition),
            let cell = (tableView.cellForRow(at: indexPath) as? PlaylistCell) else {
                return nil
        }
        
        guard let targetViewController =
            storyboard?.instantiateViewController(
                withIdentifier: "episodesViewController") as?
            EpisodesForPodcastViewController else {
                return nil
        }
        
        var selectedPodcast: CDPodcast!
        if indexPath.section == 0 {
            selectedPodcast = subscribedPodcasts[indexPath.row-1]
        } else {
            selectedPodcast = unSubscribedPodcasts[indexPath.row-1]
        }
        
        targetViewController.podcast = selectedPodcast
        targetViewController.reloadTableViewDelegate = self
        targetViewController.preferredContentSize =
            CGSize(width: 0.0, height: 500)
        
        previewingContext.sourceRect = tableView.convert(cell.frame, to: self.view)
        
        return targetViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        //present(viewControllerToCommit, animated: true, completion: nil)
        navigationController?.pushViewController(viewControllerToCommit, animated: true)
        //show(viewControllerToCommit, sender: self)
    }
    
    func reloadTableView() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        subscribedPodcasts = CoreDataHelper.getPodcastsWhere(subscribed: true, in: managedContext!)
        subscribedPodcasts.sort(by: { $0.title! < $1.title!})
        
        let unSubscribedPodcastsUnfiltered = CoreDataHelper.getPodcastsWhere(subscribed: false, in: managedContext!)
        unSubscribedPodcasts = []
        for podcast in unSubscribedPodcastsUnfiltered {
            let episodesForPodcast = CoreDataHelper.fetchEpisodesFor(podcast: podcast, in: managedContext!)
            if episodesForPodcast.count > 0 {
                unSubscribedPodcasts.append(podcast)
            }
        }
        unSubscribedPodcasts.sort(by: { $0.title! < $1.title!})
        
        DispatchQueue.main.async() {
            self.tableView.reloadData()
        }
    }
}


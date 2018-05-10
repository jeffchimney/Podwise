//
//  BrowseViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-16.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class BrowseViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var searchBar:UISearchBar = UISearchBar(frame: CGRect(x: 0,y: 0,width: 200,height: 20))
    @IBOutlet weak var tableView: UITableView!
    var podcastResults: [[String: Any]] = []
    var feedURL: String = ""
    var authorName: String = ""
    var searching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.searchBarStyle = .prominent
        searchBar.showsCancelButton = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        //let searchBarButtonItem = UIBarButtonItem(customView: searchBar)
        navigationItem.titleView = searchBar
//        navigationItem.title = ""
        //searchBar.becomeFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        podcastResults = []
        iTunesSearch(term: searchBar.text!)
        searchBar.resignFirstResponder()
        searching = true
    }
    
    //
    func iTunesSearch (term: String) {
        // replace spaces with + symbol.
        let iTunesTerm = term.replacingOccurrences(of: " ", with: "+", options: NSString.CompareOptions.caseInsensitive, range: nil)
        // anything that is URL friendly should be escaped
        let escapedTerm = iTunesTerm.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        //stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let path = "https://itunes.apple.com/search?term=\(escapedTerm ?? "")&media=podcast"
        let url: URL = URL(string: path)!
        let request: URLRequest = URLRequest(url: url)//NSURLRequest(URL: url as URL)
        let session: URLSession = URLSession.shared // NSURLConnection(request: rqst, delegate: self, startImmediately: false)!
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.ctnFinishedLoading(data: data!)
        })
        print("URL for searching iTunes API \(url)")
        task.resume()
    }

    func ctnFinishedLoading(data: Data) {
        // should hold the resulting info, request is complete
        // received data is converted into an object through JSON deserialization
        do {
            let jResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! NSDictionary
            let results = jResult["results"] as! [[String: Any]]
            if jResult.count > 0 && results.count > 0 {
                print(results)
                self.podcastResults = results
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        } catch {
            
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching {
            return podcastResults.count
        } else {
            return 14
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searching {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! PodcastCell
            let rowData: [String: Any] = self.podcastResults[indexPath.row]
            print(rowData)
            cell.titleLabel.text = rowData["trackName"] as? String
            cell.descriptionLabel.text = rowData["artistName"] as? String
            cell.collectionID = rowData["collectionId"] as? String
            let urlString: String = rowData["artworkUrl60"] as! String
            let url: URL = URL(string: urlString)!
            let request: URLRequest = URLRequest(url: url)
            let session: URLSession = URLSession.shared
            let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
                // Download representation of the image as NSData at the URL
                do {
                    let imageData: Data = try Data.init(contentsOf: url, options: .mappedIfSafe)
                    DispatchQueue.main.async {
                        cell.artImageView.image = UIImage(data: imageData)
                    }
                } catch {
                    print("Could not load art thumbnail")
                }
            })
            print("URL for searching iTunes API \(url)")
            task.resume()
            
            cell.artImageView.layer.cornerRadius = 10
            cell.artImageView.layer.masksToBounds = true

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell")!
            
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Arts"
            case 1:
                cell.textLabel?.text = "Business"
            case 2:
                cell.textLabel?.text = "Comedy"
            case 3:
                cell.textLabel?.text = "Education"
            case 4:
                cell.textLabel?.text = "Games & Hobbies"
            case 5:
                cell.textLabel?.text = "Government & Organizations"
            case 6:
                cell.textLabel?.text = "Health"
            case 7:
                cell.textLabel?.text = "Music"
            case 8:
                cell.textLabel?.text = "News & Politics"
            case 9:
                cell.textLabel?.text = "Religion & Spirituality"
            case 10:
                cell.textLabel?.text = "Science & Medicine"
            case 11:
                cell.textLabel?.text = "Society & Culture"
            case 12:
                cell.textLabel?.text = "Sports & Recreation"
            case 13:
                cell.textLabel?.text = "Technology"
            default:
                break
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if searching {
            
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searching {
            let rowData: [String: Any] = self.podcastResults[indexPath.row]
            feedURL = rowData["feedUrl"] as! String
            
            let resultViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "resultViewController") as! PodcastHistoryViewController
            resultViewController.feedURL = feedURL
            resultViewController.collectionID = rowData["collectionId"] as! Int
            resultViewController.authorName = rowData["artistName"] as? String
            self.navigationController?.pushViewController(resultViewController, animated: true)
        } else {
            var category = ""
            switch indexPath.row {
            case 0:
                category = "Arts"
            case 1:
                category = "Business"
            case 2:
                category = "Comedy"
            case 3:
                category = "Education"
            case 4:
                category = "Games & Hobbies"
            case 5:
                category = "Government & Organizations"
            case 6:
                category = "Health"
            case 7:
                category = "Music"
            case 8:
                category = "News & Politics"
            case 9:
                category = "Religion & Spirituality"
            case 10:
                category = "Science & Medicine"
            case 11:
                category = "Society & Culture"
            case 12:
                category = "Sports & Recreation"
            case 13:
                category = "Technology"
            default:
                break
            }
            
            let subCategoryViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "subCategoryViewController") as! SubCategoryViewController
            subCategoryViewController.category = category
            self.navigationController?.pushViewController(subCategoryViewController, animated: true)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searching = false
        searchBar.resignFirstResponder()
        tableView.reloadData()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        searchBar.showsCancelButton = true
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        searchBar.showsCancelButton = false
    }
}

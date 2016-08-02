//
//  ViewController.swift
//  Skillz
//
//  Created by Justin Warmkessel on 9/11/15.
//  Copyright © 2015 Justin Warmkessel, Inc. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, VideoCellDelegate {
    //MARK: Outlets and Actions
    @IBOutlet weak var tableView: UITableView!
    
 
    //MARK: properties
    var model : FeedModel?
    let kEstimatedRowHeight : CGFloat = 600.0
    let documentsURL = FileManager.default.urlsForDirectory(.documentDirectory, inDomains: .userDomainMask)[0]
    

    //MARK: UIViewController
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.configureTableView()
        self.view.isUserInteractionEnabled = true
        self.tableView.isUserInteractionEnabled = true
        self.configureNavigationBar()
        
        guard let feedModel = self.model else {
            return
        }
        
        feedModel.videos?.removeAll()
        feedModel.updateVideos()
        
        self.tableView.reloadData()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
        
        self.navigationController?.isNavigationBarHidden = true
        self.model = FeedModel.init()
    }
    
    //MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        if let model = self.model, let videos = model.videos {
            count = videos.count
        }
        
        return count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return (self.model?.sections.count)!
    }
  
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell : VideoCell = (self.tableView.cellForRow(at: indexPath) as? VideoCell)!
        
        if (cell.player?.rate == 0.0)
        {
            cell.player?.play()
            cell.player?.isMuted = false
        }
        else
        {
            cell.player?.pause()
            cell.player?.isMuted = true
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var cell : UITableViewCell?
        
        if let model = self.model, let vid = model.videos, let obj : AnyObject? = vid[(indexPath as NSIndexPath).row] {
            
            // Valid video
            if let _ = obj as? String {
                cell = self.configureVideoCell(tableView, indexPath: indexPath)
                
            } else if let dictionary : NSDictionary = obj as? NSDictionary {
                if let message : String? = dictionary.object(forKey: "message") as? String {
                    cell = UITableViewCell()
                    cell?.textLabel?.text = message
                    cell?.textLabel?.textAlignment = .center
                }
            }
        }
        
        guard let validCell = cell else {
            return UITableViewCell()
        }
        
        return validCell;
    }
    
    func configureVideoCell(_ tableView: UITableView, indexPath : IndexPath) -> VideoCell? {

        if let cell : VideoCell = tableView.dequeueReusableCell(withIdentifier: "videoCell", for: indexPath) as? VideoCell
        {
            if let feedModel = model, let videos = feedModel.videos, let obj : AnyObject? = videos[(indexPath as NSIndexPath).row], let vidName = obj as? String
            {
                cell.delegate = self
                let videoPath = self.documentsURL.path! + "/" + vidName
                cell.mediaPlayerLayer(videoPath, indexPath: indexPath)
                cell.profileUserName.text = (indexPath as NSIndexPath).row == 0 ? "Justin Warmkessel" : "New User"
                cell.profileImageView.image = (indexPath as NSIndexPath).row == 0 ? UIImage(named:"Justin") : UIImage(named:"person-icon")
            }
            else
            {
                //Do nothing
            }
        
            return cell
        }
        else
        {
            //Do nothing
        }
        
        return nil
    }
    
    //MARK: Convenience methods
    func configureNavigationBar() {
        guard let navController = self.navigationController else {
            return
        }
        
        navController.navigationBar.barTintColor = UIColor(red: 255.0/255.0, green: 69.0/255.0, blue: 0, alpha: 1.0)
        navController.navigationBar.barStyle = UIBarStyle.black
        navController.navigationBar.tintColor = UIColor.white()
    }
    
    func configureTableView() {
        self.tableView.delegate             = self
        self.tableView.dataSource           = self
        self.tableView.estimatedRowHeight   = kEstimatedRowHeight
        self.tableView.rowHeight            = UITableViewAutomaticDimension
    }
    
    //MARK: VideoCellDelegate
    func tryLessonButtonHandlerTapped(_ videoCell: VideoCell) {
        videoCell.player?.pause()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "RecordVideoNavigationController") as! UINavigationController
        self.present(vc, animated: true, completion: nil)
    }
}

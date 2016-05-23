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
    let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    

    //MARK: UIViewController
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.configureTableView()
        self.view.userInteractionEnabled = true
        self.tableView.userInteractionEnabled = true
        self.configureNavigationBar()
        
        guard let feedModel = self.model else {
            return
        }
        
        feedModel.videos?.removeAll()
        feedModel.updateVideos()
        
        self.tableView.reloadData()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
        
        self.navigationController?.navigationBarHidden = true
        self.model = FeedModel.init()
    }
    
    //MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        if let model = self.model, let videos = model.videos {
            count = videos.count
        }
        
        return count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (self.model?.sections.count)!
    }
  
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell : VideoCell = (self.tableView.cellForRowAtIndexPath(indexPath) as? VideoCell)!
        
        if (cell.player?.rate == 0.0)
        {
            cell.player?.play()
            cell.player?.muted = false
        }
        else
        {
            cell.player?.pause()
            cell.player?.muted = true
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell : UITableViewCell?
        
        if let model = self.model, let vid = model.videos, let obj : AnyObject? = vid[indexPath.row] {
            
            // Valid video
            if let _ = obj as? String {
                cell = self.configureVideoCell(tableView, indexPath: indexPath)
                
            } else if let dictionary : NSDictionary = obj as? NSDictionary {
                if let message : String? = dictionary.objectForKey("message") as? String {
                    cell = UITableViewCell()
                    cell?.textLabel?.text = message
                    cell?.textLabel?.textAlignment = .Center
                }
            }
        }
        
        guard let validCell = cell else {
            return UITableViewCell()
        }
        
        return validCell;
    }
    
    func configureVideoCell(tableView: UITableView, indexPath : NSIndexPath) -> VideoCell? {

        if let cell : VideoCell = tableView.dequeueReusableCellWithIdentifier("videoCell", forIndexPath: indexPath) as? VideoCell
        {
            if let feedModel = model, let videos = feedModel.videos, let obj : AnyObject? = videos[indexPath.row], let vidName = obj as? String
            {
                cell.delegate = self
                let videoPath = self.documentsURL.path! + "/" + vidName
                cell.mediaPlayerLayer(videoPath, indexPath: indexPath)
                
                cell.profileUserName.text = indexPath.row == 0 ? "Justin Warmkessel" : "New User"
                cell.profileImageView.image = indexPath.row == 0 ? UIImage(named:"Justin") : UIImage(named:"person-icon")
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
        navController.navigationBar.barStyle = UIBarStyle.Black
        navController.navigationBar.tintColor = UIColor.whiteColor()
    }
    
    func configureTableView() {
        self.tableView.delegate             = self
        self.tableView.dataSource           = self
        self.tableView.estimatedRowHeight   = kEstimatedRowHeight
        self.tableView.rowHeight            = UITableViewAutomaticDimension
    }
    
    //MARK: VideoCellDelegate
    func tryLessonButtonHandlerTapped(videoCell: VideoCell) {
        videoCell.player?.pause()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("RecordVideoNavigationController") as! UINavigationController
        self.presentViewController(vc, animated: true, completion: nil)
    }
}
//
//  WatchAndSpeakController.swift
//  Skillz
//
//  Created by Justin Warmkessel on 2/17/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import AVKit

class WatchAndSpeakController: UITableViewController {
    var model : WatchAndSpeakModel?
    let kEstimatedRowHeight : CGFloat = 600.0
    
    convenience init(model : WatchAndSpeakModel) {
        self.init()
        self.model = model
    }
    
    //MARK: Convenience methods
    func configureTableView() {
        self.tableView.delegate             = self
        self.tableView.dataSource           = self
        self.tableView.estimatedRowHeight   = kEstimatedRowHeight
        self.tableView.rowHeight            = UITableViewAutomaticDimension
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureTableView()
        tableView.registerNib(UINib(nibName: "VideoPreviewCell", bundle: nil), forCellReuseIdentifier: "videoPreviewCell")
        tableView.registerNib(UINib(nibName: "RecordVideoCellTableViewCell", bundle: nil), forCellReuseIdentifier: "recordVideoCell")
        
        
    }
    
    func configureVideoCell(cell : RecordVideoCellTableViewCell, indexPath : NSIndexPath) -> RecordVideoCellTableViewCell {
        
        
        
        return cell
    }
    
    func configureVideoCell(cell : VideoPreviewCell, url : NSURL) -> VideoPreviewCell {
        
        cell.selectionStyle = .None
        
        if (cell.player == nil) {
            cell.player = AVPlayer(URL: url)
            
            if let avPlayer = cell.player {
                let playerLayer = AVPlayerLayer(player: avPlayer)
                
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
                playerLayer.frame = cell.videoImageView.bounds
                
                let half : CGFloat = 2.0
                
                cell.videoImageView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI)/half);
                cell.videoImageView.layer.addSublayer(playerLayer)
                cell.setNeedsLayout()
                cell.setNeedsDisplay()
                
                NSNotificationCenter.defaultCenter().addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: cell.player?.currentItem, queue: nil, usingBlock: { (NSNotification) -> Void in
                    
                    cell.player?.currentItem?.seekToTime(kCMTimeZero)
                    cell.player?.play()
                })
                
                avPlayer.play()
            }
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 400.0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : UITableViewCell?
        
        if let model = self.model, let url = model.previewVideoURL {
            
            switch(indexPath.section) {
                case 0: break
                case 1:
                    let videoCell : VideoPreviewCell? = tableView.dequeueReusableCellWithIdentifier("videoPreviewCell", forIndexPath: indexPath) as? VideoPreviewCell
                    
                    if let vidCell = videoCell {
                        cell = self.configureVideoCell(vidCell, url: url)
                    }
                
                default:break
            }
        }
        
        guard let validCell = cell else {
            return UITableViewCell()
        }
        
        return validCell;
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        switch(indexPath.section) {
        case 0: break
        case 1:
            let indexPath : NSIndexPath? = self.tableView.indexPathForSelectedRow
            if let currentCell : VideoPreviewCell? = tableView.cellForRowAtIndexPath(indexPath!) as? VideoPreviewCell {
                
                if (currentCell?.player?.rate != 0 && currentCell?.player?.error == nil) {
                    currentCell?.player?.pause()
                } else {
                    currentCell?.player?.play()
                }
                
            }

        default: break
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
}
//
//  VideoCell.swift
//  Skillz
//
//  Created by Justin Warmkessel on 1/13/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer

protocol VideoCellDelegate: class {
    func tryLessonButtonHandlerTapped(videoCell : VideoCell)
}

class VideoCell: UITableViewCell {
    weak var delegate:VideoCellDelegate?
    
    @IBAction func tryLessonButtonHandler(sender: UIButton, forEvent event: UIEvent) {
        self.delegate?.tryLessonButtonHandlerTapped(self)
    }
    
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var topLineDecoration: UIView!
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var temporaryText: UILabel!
    var player : AVPlayer?
    var playerLayer : AVPlayerLayer?
    
    func mediaPlayerLayer(videoPath : String, indexPath : NSIndexPath)
    {
        self.selectionStyle = .None
        self.topLineDecoration(nil, alpha: 0.0, indexPath: indexPath)
    
        var isDir = ObjCBool(false)
        if NSFileManager.defaultManager().fileExistsAtPath(videoPath, isDirectory: &isDir) {
            
            let pathURL = NSURL.fileURLWithPath(videoPath)
            
            if (self.player != nil)
            {
                let newItem : AVPlayerItem = AVPlayerItem(URL: pathURL)
                self.player?.replaceCurrentItemWithPlayerItem(newItem)
            }
            else
            {
                self.player = AVPlayer(URL: pathURL)
                
                if (self.playerLayer != nil)
                {
                    self.playerLayer?.player = self.player
                }
                else
                {
                    let playerLayer = AVPlayerLayer(player: self.player)
                    playerLayer.setAffineTransform(CGAffineTransformMakeRotation(CGFloat(M_PI)/2.0))
                    
                    let height : CGFloat = CGRectGetHeight(self.videoImageView.layer.frame)
                    let width : CGFloat = CGRectGetWidth(self.videoImageView.layer.frame)
                    let rect : CGRect = CGRectMake(0.0, 0.0, width, height)
                    
                    playerLayer.frame = rect
                    
                    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
                    
                    self.videoImageView.layer.addSublayer(playerLayer)
                }
            }
            
            NSNotificationCenter.defaultCenter().addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: self.player?.currentItem, queue: nil, usingBlock: { (NSNotification) -> Void in
                
                self.player?.currentItem?.seekToTime(kCMTimeZero)
                self.player?.play()
            })

            self.player?.play()
            self.player?.muted = true;
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.player?.pause()
        self.player?.muted = true
    }
    
    func configureTextLabel(text: String?)
    {
        if let textDescription = text
        {
            self.detailLabel.text = textDescription
        }
    }
    
    func topLineDecoration(backgroundColor : UIColor?, alpha : CGFloat, indexPath: NSIndexPath)
    {
        if let color = backgroundColor
        {
            self.topLineDecoration.backgroundColor = color
            self.topLineDecoration.alpha = alpha
        }
        else
        {
            self.topLineDecoration.backgroundColor = !self.isFirstCell(indexPath) ? UIColor.lightGrayColor() : self.topLineDecoration.backgroundColor
            self.topLineDecoration.alpha = 0.8
        }
    }
    
    func isFirstCell(indexPath : NSIndexPath) -> Bool
    {
        return indexPath.row == 0 ? true : false
    }
}

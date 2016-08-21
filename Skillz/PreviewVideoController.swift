//
//  PreviewVideoController.swift
//  Skillz
//
//  Created by Justin Warmkessel on 4/11/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

class PreviewVideoController : UIViewController{
    var model : PreviewVideo?
    var player : AVPlayer?
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var previewVideoView: UIImageView!

    @IBAction func doneButtonHandler(_ sender: AnyObject) {

        if let navController = self.navigationController
        {
            navController.dismiss(animated: true, completion: nil)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureVideoCell()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let player = self.player {
            player.pause()
        }
    }
    
    func configureVideoCell() {
        
        if (self.player == nil) {
            self.player = AVPlayer(url: (model?.contentURL)! as URL)
            
            if let avPlayer = self.player {
                
                let playerLayer = AVPlayerLayer(player: self.player)
                let height : CGFloat = self.previewVideoView.layer.frame.height
                let width : CGFloat = self.previewVideoView.layer.frame.width
                let rect : CGRect = CGRect(x: 0.0, y: 0.0, width: width, height: height)
                
                //FIXME: This is super broken. Will only work for 6S
//                playerLayer.frame = rect
                
                playerLayer.bounds = CGRect(x: 0, y: 0, width: 750.0, height: 824.0)
                
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
                
                self.previewVideoView.layer.addSublayer(playerLayer)

                NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: nil, using: { (NSNotification) -> Void in
                    
                    self.player?.currentItem?.seek(to: kCMTimeZero)
                    self.player?.play()
                })
                
                avPlayer.play()
            }
        }
        else {
            self.player?.seek(to: kCMTimeZero)
            self.player?.play()
        }
        
    }
}

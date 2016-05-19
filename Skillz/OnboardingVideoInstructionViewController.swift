//
//  OnboardingVideoInstructionViewController.swift
//  Skillz
//
//  Created by Justin Warmkessel on 5/17/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import UIKit
import MediaPlayer
//import AVKit

class OnboardingVideoInstructionViewController: UIViewController {
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var beginButton: UIButton!
   
    @IBAction func beginButtonHandler(sender: UIButton, forEvent event: UIEvent) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("MainTabBarController")
        
        UIApplication.sharedApplication().keyWindow?.rootViewController = vc
    }
    var player : AVPlayer?
    var playerLayer : AVPlayerLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let path = NSBundle.mainBundle().pathForResource("InstructorDavid", ofType: "mp4")
        
        if let pathString = path
        {
            let fileManager : NSFileManager = NSFileManager()
            if (fileManager.fileExistsAtPath(pathString))
            {
                let pathURL : NSURL = NSURL.init(fileURLWithPath: pathString, isDirectory: false)
                
                self.player = AVPlayer.init(URL: pathURL)
                self.playerLayer = AVPlayerLayer(player: self.player)
    
                if let playerLayer = self.playerLayer
                {
//                    playerLayer.setAffineTransform(CGAffineTransformMakeRotation(CGFloat(M_PI)/2.0))
    
                    let height : CGFloat = CGRectGetHeight(self.videoImageView.layer.frame)
                    let width : CGFloat = CGRectGetWidth(self.videoImageView.layer.frame)
                    let rect : CGRect = CGRectMake(0.0, 0.0, height, width + 20.0)
    
                    playerLayer.frame = rect
    
                    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    
                    self.videoImageView.layer.addSublayer(playerLayer)
                    
                    if let player = self.player {
                        player.play()
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

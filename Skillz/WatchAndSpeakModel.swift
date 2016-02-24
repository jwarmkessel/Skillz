//
//  WatchAndSpeakModel.swift
//  Skillz
//
//  Created by Justin Warmkessel on 2/17/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

class WatchAndSpeakModel: NSObject {
    var previewVideoURL : NSURL?
    
    
    convenience init(previewURL : NSURL) {
        self.init()
        self.previewVideoURL = previewURL
    }
}
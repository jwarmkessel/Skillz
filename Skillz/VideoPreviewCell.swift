//
//  VideoPreviewCell.swift
//  Skillz
//
//  Created by Justin Warmkessel on 2/22/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer

class VideoPreviewCell: UITableViewCell {

    @IBOutlet weak var videoImageView: UIImageView!
    var player : AVPlayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
}

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
}

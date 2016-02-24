//
//  FeedModel.swift
//  Skillz
//
//  Created by Justin Warmkessel on 1/20/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

enum FeedState {
    case Success
    case Error
    case NoContent
    case Loading
}

class FeedModel: NSObject {
    let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    var thumbnails  : [AnyObject?]? = nil
    var videos      : [AnyObject?]? = nil
    var sections    : [Int] = [1]
    var error       : [AnyObject?]?
    var noContent   : [AnyObject?]?
    var state       : FeedState = .Loading
    
    override init() {
        super.init()
        self.thumbnails = self.pathsForAllImages()
        self.videos = self.pathsForAllVideos()
    }
    
    func updateVideos() {
        self.videos = self.pathsForAllVideos()
    }
    func pathsForAllImages () -> [AnyObject?]? {
        let url = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        var array:[AnyObject?]? = nil
        
        let properties = [NSURLLocalizedNameKey, NSURLCreationDateKey, NSURLLocalizedTypeDescriptionKey]
        
        print (url);
        
        do {
            let directoryUrls = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(url, includingPropertiesForKeys: properties, options:NSDirectoryEnumerationOptions.SkipsHiddenFiles)
            array = directoryUrls.map(){ $0.lastPathComponent }.filter(){ ($0! as! NSString).pathExtension == "jpg" }
            if array?.count == 0 {
                array = nil
            }
        }
        catch let error as NSError {
            print(error.description)
        }
        return array
        
    }
    
    func pathsForAllVideos () -> [AnyObject?]? {
        let url = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        var array : [AnyObject?]? = [String]()
        
        let properties = [NSURLLocalizedNameKey, NSURLCreationDateKey, NSURLLocalizedTypeDescriptionKey]
        
        print (url);
        
        do {
            let directoryUrls = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(url, includingPropertiesForKeys: properties, options:NSDirectoryEnumerationOptions.SkipsHiddenFiles)
            
            array = directoryUrls.map(){
                $0.lastPathComponent }.filter(){
                    ($0! as! NSString).pathExtension == "mp4"
            }
            
            if array?.count == 0 {
                state = .NoContent
                
                self.noContent = [["message": "No content available"]]
                array = self.noContent
            }
        }
        catch let error as NSError {
            print(error.description)
        }
        return array
        
    }
}

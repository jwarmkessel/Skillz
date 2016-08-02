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
    case success
    case error
    case noContent
    case loading
}

class FeedModel: NSObject {
    let documentsURL = FileManager.default.urlsForDirectory(.documentDirectory, inDomains: .userDomainMask)[0]
    var thumbnails  : [AnyObject?]? = nil
    var videos      : [AnyObject?]? = nil
    var sections    : [Int] = [1]
    var error       : [AnyObject?]?
    var noContent   : [AnyObject?]?
    var state       : FeedState = .loading
    
    override init() {
        super.init()
        self.thumbnails = self.pathsForAllImages()
//        self.videos = self.pathsForAllVideos()
    }
    
    func updateVideos() {
        self.videos = self.pathsForAllVideos()
        
        //DEBUG: 
        if (self.videos?.count < 1)
        {
            let path = Bundle.main.pathForResource("InstructorDavid", ofType: "mov")
            
            if let stringPath = path
            {
                self.videos?.append(stringPath)
            }
        }
    }
    func pathsForAllImages () -> [AnyObject?]? {
        let url = FileManager.default.urlsForDirectory(.documentDirectory, inDomains: .userDomainMask)[0]
        var array:[AnyObject?]? = nil
        
        let properties : [String]! = [URLResourceKey.localizedNameKey.rawValue, URLResourceKey.creationDateKey.rawValue, URLResourceKey.localizedTypeDescriptionKey.rawValue]
        
        print (url);
        
        do {
//            let directoryUrls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: properties, options:FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            
            let directoryUrls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: properties, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            
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
        
        var array : [AnyObject?]? = [String]()
        
        // We need just to get the documents folder url
        let documentsUrl =  FileManager.default.urlsForDirectory(.documentDirectory, inDomains: .userDomainMask).first!
        
        // now lets get the directory contents (including folders)
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())
            print(directoryContents)
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        // if you want to filter the directory contents you can do like this:
        
        do {
            let directoryUrls = try  FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())
            print(directoryUrls)
            
            array = directoryUrls.map(){
                $0.lastPathComponent }.filter(){
                    ($0! as! NSString).pathExtension == "mov"
            }
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    
        return array
        
    }
    
    func new () -> [AnyObject?]?
    {
        var array : [AnyObject?]? = [String]()
        
        // We need just to get the documents folder url
        let documentsUrl =  FileManager.default.urlsForDirectory(.documentDirectory, inDomains: .userDomainMask).first!
        
        // now lets get the directory contents (including folders)
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())
            print(directoryContents)
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        // if you want to filter the directory contents you can do like this:
        
        do {
            let directoryUrls = try  FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())
            print(directoryUrls)
            
            array = directoryUrls.map(){
                $0.lastPathComponent }.filter(){
                    ($0! as! NSString).pathExtension == "mov"
            }
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        return array
    }
}

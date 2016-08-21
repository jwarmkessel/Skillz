//
//  EDUViewController.swift
//  Skillz
//
//  Created by Justin Warmkessel on 8/21/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import Foundation
import UIKit


class EDUViewController: UIViewController {

    var activityIndicator = UIActivityIndicatorView()
    let fullRootActivityView : UIView = UIView.init()
    
    //MARK: ACTIVITY INDICATOR 
    func showActivityIndicator(frame: CGRect) {
        
        self.fullRootActivityView.isHidden = false
        self.createFullActivityView(frame: frame)
        self.activityIndicator.startAnimating()
        
        self.view.addSubview(fullRootActivityView)
    }
    
    func createFullActivityView(frame: CGRect) {
        fullRootActivityView.backgroundColor = UIColor.red()
        fullRootActivityView.alpha = 0.8
        fullRootActivityView.frame = frame
        activityIndicator.center = fullRootActivityView.center
        fullRootActivityView.addSubview(activityIndicator)
    }
    
    func hideActivityIndicator()
    {
        DispatchQueue.main.async
        {
            self.activityIndicator.stopAnimating()
            self.fullRootActivityView.isHidden = true
        }
    }
}

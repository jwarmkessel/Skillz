//
//  PreviewVideo.swift
//  Skillz
//
//  Created by Justin Warmkessel on 4/11/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import Foundation
import Speech

class PreviewVideo {
    var contentURL : URL
    
    init(url : URL) {
        
        self.contentURL = url
        self.speechKitTest(fileURL: url as URL)
    }
    
    func speechKitTest(fileURL : URL)
    {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            /*
             The callback may not be called on the main thread. Add an
             operation to the main queue to update the record button's state.
             */
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized: break
                    //User gave access to speech recognition
                    
                case .denied: break
                    //User denied access to speech recognition
                    
                case .restricted: break
                    //Speech recognition restricted on this device
                    
                case .notDetermined: break
                    //Speech recognition not yet authorized
                }
            }
        }
    
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        let recognitionTask: SFSpeechRecognitionTask = (recognizer?.recognitionTask(with: request, resultHandler:
            {
                (result, error)   in
                if let error = error
                {
                    print("There was an error: \(error)")
                }
                else
                {
                    print (result?.bestTranscription.formattedString)
                }
        })
            )!
        
        print(recognitionTask)
    }
}

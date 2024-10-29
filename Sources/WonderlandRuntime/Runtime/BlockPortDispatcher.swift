//
//  BlockPortDispatcher.swift
//  FBPLand
//
//  Created by Reality Builder Team on 2/3/2022.
//

import UIKit

//send message to ports through tunnel
@MainActor class BlockPortDispatcher  {
    
    static let shared = BlockPortDispatcher()
    
    var pairs = [Notification.Name: [(destinationPortName: Notification.Name, destPortIndex: Int)]]()
    
    func route(from outPort: String, to inPort: String, destPortIndex: Int) {
        let outName = Notification.Name(outPort)
        let inName = Notification.Name(inPort)
        
        if pairs[outName] == nil {
            pairs[outName] = []
        }
        
        if pairs[outName]?.isEmpty == true {
            NotificationCenter.default.addObserver(self, selector: #selector(receive(notification:)), name: outName, object: nil)
        }
        
        pairs[outName]?.append((destinationPortName: inName, destPortIndex: destPortIndex))
    }
    
    
    func close() {
        for (outName, _) in pairs {
            NotificationCenter.default.removeObserver(self, name: outName, object: nil)
        }
        pairs.removeAll()
    }
    
    @objc
    func receive(notification: Notification) {
        let name = notification.name
        if let destinations = pairs[name] {
            for dest in destinations {
                self.forward(to: dest.destinationPortName, message: notification.object, destPortIndex: dest.destPortIndex)
            }
        }
    }

    func forward(to inName: Notification.Name, message: Any?, destPortIndex: Int) {
        let userInfo: [AnyHashable: Any] = ["destPortIndex": destPortIndex]
        NotificationCenter.default.post(name: inName, object: message, userInfo: userInfo)
    }

}

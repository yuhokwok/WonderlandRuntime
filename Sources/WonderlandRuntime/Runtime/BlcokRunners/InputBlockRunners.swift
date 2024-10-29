//
//  InputBlockRunners.swift
//  FBPLand
//
//  Created by Reality Builder Team on 3/3/2022.
//

import UIKit
import RealityKit


class WhenGameStartBlock : BlockRunner {
    
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        for outPort in outPorts {
            self.send(port: outPort, message: ["eventType": "trigger"])
        }
    }
}

class TapOnObjectBlock: BlockRunner {
    
    var entity: Entity?
    var touch: UITouch?
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        guard let entity = entity else { return }
        print("TapOnObjectBlock::: execute")
        let messageToSend = ["entity": entity, "eventType": "trigger"] as [String : Any]
        for i in 0..<outPorts.count {
            self.send(port: outPorts[i], message: messageToSend)
        }
    }
    
    @MainActor func touch(at touch: UITouch) {
        DispatchQueue.main.async {
            let location = touch.location(in: Runtime.shared.arView)
            guard let entity = Runtime.shared.arView?.entity(at: location), entity.name != "" else {
                return
            }
            self.entity = entity
            self.touch = touch
            self.execute(message: nil, from: nil)
        }
    }
    
}


class DoubleTapOnScreenBlock: BlockRunner {
    
    var status = 0
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
    }
    
    @MainActor func trigger() {
        status = 1
        let messageToSend = ["eventType": "trigger"] as [String : Any]
        for outPort in outPorts {
            self.send(port: outPort, message: messageToSend)
        }
    }
    
}


class TapOnScreenBlock: BlockRunner {
    
    var status = 0
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
    }
    
    @MainActor func tapDown() {
        status = 1
        let messageToSend = ["eventType": "trigger"] as [String : Any]
        for outPort in outPorts {
            self.send(port: outPort, message: messageToSend)
        }
    }
    
    @MainActor func tapUp() {
        status = 0
        let messageToSend = ["eventType": "trigger"] as [String : Any]
        for outPort in outPorts {
            self.send(port: outPort, message: messageToSend)
        }
    }
    
}


class TouchAtLocationBlock: BlockRunner {
    
    var point = CGPoint.zero
    var touch: UITouch?
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        let messageToSend = ["touch": self.touch, "eventType": "trigger"] as [String : Any]
        for i in 0..<outPorts.count {
            self.send(port: outPorts[i], message: messageToSend)
        }
        
    }
    
    //    func touch(at location : CGPoint) {
    func touch(at touch : UITouch) {
//        let location = touch.location(in: Runtime.shared.arView)
//        self.point = location
//        self.touch = touch
//        self.execute(message: nil, from: nil)
    }
}


class ScheduleActionBlock : BlockRunner {
    var timer: Timer?
    var scheduleTime: Double!
    
    override func loadBlock(block: Block, runtime: Runtime) {
        super.loadBlock(block: block, runtime: runtime)
        
        guard let value = block.outlets[0].value as? [String], let scheduleTime = value.first else {
            return
        }
        //        guard let value = block.attributes["second"] as? String else {
        //            return
        //        }
        //
        self.scheduleTime = Double(scheduleTime)
        
    }
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        timer = Timer.scheduledTimer(timeInterval: scheduleTime, target: self, selector: #selector(schedulePublish), userInfo: nil, repeats: true)
        
        //        self.runtime?.delegate?.runtime(self.runtime!, scheduleTimer: timer)
    }
    
    @MainActor @objc func schedulePublish() {
        let messageToSend = ["eventType": "trigger"] as [String : Any]
        for outPort in outPorts {
            self.send(port: outPort, message: messageToSend)
        }
    }
    
}


class ObjectCollisionBlock: BlockRunner {
    var modelEntitys = [ModelEntity]()
    var canExecute = true // Add this flag

    @MainActor func trigger(input: Any?) {
        print("ObjectCollisionBlock::: trigger")
        if let event = input as? CollisionEvents.Began {
            self.execute(message: event, from: nil)
        }
    }

    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        if let event = message as? CollisionEvents.Began {
            print("ObjectCollisionBlock::: triggered")
            let entityA = event.entityA
            let entityB = event.entityB

            if let modelEntityA = entityA as? ModelEntity,
               let modelEntityB = entityB as? ModelEntity {
                if modelEntityA.collision?.filter.group != Runtime.CollisonGroup.planeGroup &&
                    modelEntityB.collision?.filter.group != Runtime.CollisonGroup.planeGroup {
                    if canExecute { // Check if execution is allowed
                        if modelEntitys.contains(where: { $0 === modelEntityA }) &&
                            modelEntitys.contains(where: { $0 === modelEntityB }) {
                            // Proceed with your logic
                            let messageToSend = ["eventType": "trigger"] as [String: Any]
                            for outPort in outPorts {
                                self.send(port: outPort, message: messageToSend)
                            }
                            canExecute = false // Disable execution
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.canExecute = true // Re-enable after 0.5 seconds
                            }
                        }
                    } else {
                        print("ObjectCollisionBlock::: fail to execute")
                    }
                }
            }
        } else {
            guard let msg = message as? [String: Any],
                  let eventType = msg["eventType"] as? String else {
                return
            }

            guard let receivedEntity = msg["entity"] as? ModelEntity else { return }

            switch eventType {
            case "target", "pivotEntity":
                print("ObjectCollisionBlock::: get\(eventType)")
                modelEntitys.append(receivedEntity)
            default:
                break
            }
        }
    }
}

class ObjectBreakBlock: BlockRunner {
    var modelEntitys = [ModelEntity]()

    @MainActor func trigger(input: Any?) {
        print("ObjectBreakBlock::: trigger")
        if let event = input as? SceneEvents.WillRemoveEntity {
            self.execute(message: event, from: nil)
        }
    }

    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        if let event = message as? SceneEvents.WillRemoveEntity {

            if modelEntitys.contains(where: { $0 === event.entity }) {
                print("ObjectBreakBlock::: triggered")
                let messageToSend = ["eventType": "trigger"] as [String: Any]
                for outPort in outPorts {
                    self.send(port: outPort, message: messageToSend)
                }
            }
            
        } else {
            print("ObjectBreakBlock::: ")
            guard let msg = message as? [String: Any] else {
                return
            }

            guard let receivedEntity = msg["param"] as? ModelEntity else { return }

            modelEntitys.append(receivedEntity)

        }
    }
}

/// 未轉
class ConstantBlock: BlockRunner {
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        let msg = (block?.attributes["value"])! as NSString
        
        for outPort in outPorts {
            self.send(port: outPort, message: "1")
        }
    }
    
}

class StringBlock: BlockRunner {
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        print("execute as string block")
        guard let msg = block?.attributes["value"] else {
            return
        }
        
        for outPort in outPorts {
            print("sending message to \(outPort) with \(msg)")
            self.send(port: outPort, message: msg)
        }
    }
    
}



class BodyAnchorBlock : BlockRunner {
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        //        let config = ARBodyTrackingConfiguration()
        //        runtime!.arView!.session.run(config, options: [])
        //
        //        let anchor = AnchorEntity(.body)
        //
        //        for outPort in outPorts {
        //            self.send(port: outPort, message: anchor)
        //        }
        
    }
    
}

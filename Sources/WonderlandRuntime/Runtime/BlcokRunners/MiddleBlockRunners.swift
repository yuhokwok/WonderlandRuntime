//
//  MiddleBlockRunners.swift
//  FBPLand
//
//  Created by Reality Builder Team on 3/3/2022.
//

import UIKit
import RealityKit

class TrueBlock : BlockRunner {
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        let messageToSend = ["param": "true"] as [String : Any]
        for outPort in outPorts {
            self.send(port: outPort, message: messageToSend)
        }
    }
}

class FalseBlock : BlockRunner {
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        let messageToSend = ["param": "false"] as [String : Any]
        for outPort in outPorts {
            self.send(port: outPort, message: messageToSend)
        }
    }
}

class WaitBlock : BlockRunner {
    
    var message: Any?
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        guard let value = block?.inlets[0].value as? [String], let scheduleTime = value.first, let time = Double(scheduleTime) else {
            return
        }
        
        self.message = message
        Timer.scheduledTimer(timeInterval: time, target: self, selector: #selector(schedulePublish), userInfo: nil, repeats: true)
    }
    
    @MainActor @objc func schedulePublish() {
        for outPort in outPorts {
            self.send(port: outPort, message: message)
        }
    }
}

/// 未做
class CalculatorBlock : BlockRunner {
    
    var params = [String : Int]()
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        guard let message = message as? String, let operate = block?.getString("operator") else {
            return
        }
        
        
        //assign value to parameter
        params[port!.rawValue] = (message as NSString).integerValue
        var result = 0
        var firstNum = 0
        
        for i in 0..<inPorts.count {
            if i == 1 {
                guard let secondNum = params[inPorts[i].rawValue] else {
                    return
                }
                
                switch operate {
                case "+":
                    result = firstNum + secondNum
                    
                case "-":
                    result = firstNum - secondNum
                    
                case "*":
                    result = firstNum * secondNum
                    
                default:
                    if secondNum != 0 {
                        result = firstNum / secondNum
                    }
                }
                
                for outPort in outPorts {
                    self.send(port: outPort, message: String(result))
                }
            }
            
            guard let input = params[inPorts[i].rawValue] else {
                return
            }
            firstNum += input
        }
    }
}

class ComparisonBlock : BlockRunner {
    
    var params = [String : Int]()
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        guard let message = message as? String, let comparison = block?.getString("comparison") else {
            return
        }
        
        
        //assign value to parameter
        params[port!.rawValue] = (message as NSString).integerValue
        var firstNum = 0
        
        //try sending out message (if all ports received value)
        for i in 0..<inPorts.count {
            if i == 1 {
                guard let secondNum = params[inPorts[i].rawValue] else {
                    return
                }
                
                var sendMsg: Bool = false
                
                switch comparison {
                case "=":
                    if firstNum == secondNum {
                        sendMsg = true
                    }
                case ">":
                    if firstNum > secondNum {
                        sendMsg = true
                    }
                default:
                    if firstNum < secondNum {
                        sendMsg = true
                    }
                }
                
                if sendMsg {
                    for outPort in outPorts {
                        self.send(port: outPort, message: String(1))
                        
                    }
                }
            }
            
            guard let input = params[inPorts[i].rawValue] else {
                return
            }
            firstNum += input
        }
    }
}


class LogicBlock : BlockRunner {
    
    var params = [String : Any]()
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        //        guard let message = message as? String, let logic = block?.getString("logic") else {
        //            return
        //        }
        
        guard let logic = block?.getString("logic") else {
            return
        }
        
        
        //assign value to parameter
        params[port!.rawValue] = message
        
        var firstParam: Any?
        
        //try sending out message (if all ports received value)
        for i in 0..<inPorts.count {
            if i == 1 {
                guard let secondParam = params[inPorts[i].rawValue] else {
                    return
                }
                
                switch logic {
                case "AND":
                    if (firstParam as? Int == 1) && (secondParam as? Int == 1) {
                        var count = 0
                        for outPort in outPorts {
                            if count == 0 {
                                self.send(port: outPort, message: String(1))
                                count += 1
                            } else {
                                self.send(port: outPort, message: 1)
                            }
                        }
                    } else if (firstParam as? Entity)?.hashValue == (secondParam as? Entity)?.hashValue {
                        var count = 0
                        for outPort in outPorts {
                            if count == 0 {
                                self.send(port: outPort, message: firstParam)
                                count += 1
                            } else {
                                self.send(port: outPort, message: 1)
                            }
                        }
                    }
                    
                default:
                    if (firstParam as? Int) != (secondParam as? Int) {
                        for outPort in outPorts {
                            self.send(port: outPort, message: String(1))
                        }
                    } else if (firstParam as? Entity)?.hashValue != (secondParam as? Entity)?.hashValue {
                        for outPort in outPorts {
                            self.send(port: outPort, message: firstParam)
                        }
                    }
                }
                
            }
            
            guard let input = params[inPorts[i].rawValue] else {
                return
            }
            firstParam = input
        }
    }
}

class CounterBlock : BlockRunner {
    
    var count: Int = 0
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        if message != nil {
            count += 1
            
            for outPort in outPorts {
                self.send(port: outPort, message: String(count))
            }
        }
        
    }
    
    override func loadBlock(block: Block, runtime: Runtime) {
        
        super.loadBlock(block: block, runtime: runtime)
        
        guard let value = block.attributes["value"] as? String else {
            return
        }
        print("load value \(value)")
        count = Int(value)!
    }
}

class AdjustTimeBlock : BlockRunner {
    var params = [String : Int]()
    var adjust: Int = 0
    var isSet: Bool = false
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        if inPorts[1].rawValue == port!.rawValue {
            guard let message = message as? String else {
                return
            }
            adjust = (message as NSString).integerValue
            return
        }
        
        for outPort in outPorts {
            self.send(port: outPort, message: adjust)
        }
        
    }
    
    override func loadBlock(block: Block, runtime: Runtime) {
        
        super.loadBlock(block: block, runtime: runtime)
        
        guard let value = block.attributes["value"] as? String else {
            return
        }
        print("load value \(value)")
        adjust = Int(value)!
    }
    
}

class RandomPositionBlock : BlockRunner {
    
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        let randomX = Float.random(in: -30...30) * Float(Runtime.factor)
        let randomY = Float.random(in: -1...5) * Float(Runtime.factor)
        let randomZ = Float.random(in: -70...0) * Float(Runtime.factor)
        
        
        for outPort in outPorts {
            self.send(port: outPort, message: [1: randomX, 2: randomY, 3: randomZ])
        }
        
    }
    
}
















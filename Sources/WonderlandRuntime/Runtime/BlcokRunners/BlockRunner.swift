
import UIKit

protocol Initializable {
    init()
}


class BlockRunner : Initializable {
    
    var param = [String : Any]()
    
    var runtime : Runtime?
    var identifier : String = ""
    var block : Block?
    
    var outPorts = [Notification.Name]()
    var inPorts = [Notification.Name]()
    
    
    
    static func initializeObject<T : Initializable>(fromType type: T.Type) -> T {
        return T.init()
    }
    
    @MainActor required init() { }
    
    /// Load Block Content
    /// - Parameter block: A Block Object (Constant)
    @MainActor func loadBlock(block: Block, runtime: Runtime) {
        self.runtime = runtime
        self.block = block
        self.identifier = block.identifier
        for (index, outPort) in block.outlets.enumerated() {
            self.bind(portId: outPort.identifier, isInPort: false)
            runtime.portIdToBlockInfo[outPort.identifier] = (block: block, portIndex: index, isOutlet: true)
            //            print("::: 1. Identifier: \(outPort.identifier)")
        }
        for (index, inPort) in block.inlets.enumerated() {
            self.bind(portId: inPort.identifier, isInPort: true)
            runtime.portIdToBlockInfo[inPort.identifier] = (block: block, portIndex: index, isOutlet: false)
            //            print("::: 2. Identifier: \(inPort.identifier)")
        }
    }
    
    
    //listen to message
    @MainActor func bind(portId: String, isInPort : Bool) {
        if isInPort {
            let name = Notification.Name(portId)
            NotificationCenter.default.addObserver(self, selector: #selector(receive(notification:)), name: name, object: nil)
            self.inPorts.append(name)
        } else {
            let name = Notification.Name(portId)
            self.outPorts.append(name)
        }
    }
    
    //close all connection
    @MainActor func close() {
        for name in inPorts {
            NotificationCenter.default.removeObserver(self, name: name, object: nil)
        }
        inPorts.removeAll()
    }
    
    //send message
    @MainActor func send(port : Notification.Name, message : Any?) {
        NotificationCenter.default.post(name: port, object: message)
    }
    
    //receive message
    @objc
    @MainActor func receive(notification: Notification) {
        let destPortIndex = notification.userInfo?["destPortIndex"] as? Int
        self.execute(message: notification.object, from: notification.name, destPortIndex: destPortIndex)
    }
    
    //execute logic
    @MainActor func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        print("execute the block logic")
    }
    
    //wait for message
    @MainActor func wait() {
        
    }
    
    @MainActor func convert(x: CGFloat, y: CGFloat, z: CGFloat) -> SIMD3<Float> {
        let halfSize = Runtime.size / 2
        let invertedY = Runtime.size - y
        
        let x3d = Float((x - halfSize) * Runtime.factor)
        let y3d = Float((invertedY - halfSize) * Runtime.factor)
        let z3d = Float((z - halfSize) * Runtime.factor)
        
        return SIMD3(x: x3d, y: y3d, z: z3d)
    }
}


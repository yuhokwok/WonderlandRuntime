//
//  Block.swift
//  FBPLand
//
//  Created by Reality Builder Team on 17/2/2022.
//

import UIKit
import RealityKit
struct Block : FlowElement, FlowTransformable, FlowElementLockable, Codable {

    var id : String {
        return identifier
    }
    
    struct ObjectGeo : Codable {
        //deminsion
        var center : SIMD3<Float>
        var scale : SIMD3<Float>
        var rotation : SIMD4<Float>
        static var zero : ObjectGeo {
            return ObjectGeo(center: .zero, scale: .zero, rotation: .zero)
        }
    }
    
    var _identifier = UUID().uuidString
    var _timestamp = Date().timeIntervalSinceReferenceDate
    
    var name : String = ""
    var displayName : String = ""
    
    var type : String = ""
    var category : String = ""
    
    var attributes : [String : String] = [:]
    
    var objectGeo : ObjectGeo
    
    //deminsion
    var center : Block.Point
    var size : Block.Size
    var rotation : Block.Point

    
    var inlets : [Block.Port] = []
    var outlets : [Block.Port] = []
    
    var function : String
    var className : String
    
    var locked: Bool {
        get {
            self.getBool("lock", default: false)
        }
        set {
            self.set(newValue, for: "lock")
        }
    }
    
    init(center: Block.Point = .zero,
         size : Block.Size = .zero,
         rotation : Block.Point = .zero,
         objectGeo : ObjectGeo = .zero,
         function : String = "debug:", className : String = "Debug"){
        self.objectGeo = objectGeo
        self.center = center
        self.size = size
        self.rotation = rotation
        self.function = function
        self.className = className
    }
    
    
    
    var identifier: String {
        return _identifier
    }
    
    var timestamp: TimeInterval {
        return _timestamp
    }
    
    static func ===(lhs : Block, rhs : Block) -> Bool {
        return (lhs.identifier == rhs.identifier && lhs.timestamp == rhs.timestamp && lhs.attributes == rhs.attributes && lhs.inlets == rhs.inlets && lhs.outlets == rhs.outlets)
    }
    
    static func ==(lhs : Block, rhs : Block) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.timestamp == rhs.timestamp && lhs.attributes == rhs.attributes  && lhs.inlets == rhs.inlets && lhs.outlets == rhs.outlets
    }
    
    mutating func update() {
        self._timestamp = Date().timeIntervalSinceReferenceDate
    }
    
    func copy(updateId : Bool = false) -> Block? {
        do {
            let data = try JSONEncoder().encode(self)
            var blockCopy  = try JSONDecoder().decode(Block.self, from: data)
            if updateId {
                blockCopy._identifier = UUID().uuidString
                blockCopy._timestamp = Date().timeIntervalSinceReferenceDate
                blockCopy.inlets = blockCopy.inlets.map( {
                    var port = $0
                    port._identifier = UUID().uuidString
                    port._timestamp = Date().timeIntervalSinceReferenceDate
                    port.connectionIDs.removeAll()
                    return port
                })
                
                blockCopy.outlets = blockCopy.outlets.map( {
                    var port = $0
                    port._identifier = UUID().uuidString
                    port._timestamp = Date().timeIntervalSinceReferenceDate
                    port.connectionIDs.removeAll()
                    return port
                })

            }
            return blockCopy
        } catch _ {
            return nil
        }
    }
    
    func containsPort(with uuid: String) -> Bool {
        let allPorts = self.inlets + self.outlets
        let filteredPort = allPorts.filter({ $0.id == uuid })
        return filteredPort.count > 0
    }
    
    func port(with uuid: String) -> Block.Port? {
        let allPorts = self.inlets + self.outlets
        return allPorts.first(where: { $0.id == uuid })
    }
    
    func duplicate() -> Block {
        var block = self
        //TODO: shuffle 3d object's location
        block._identifier = UUID().uuidString
        block.inlets = block.inlets.map({ $0.duplicate() })     //copy with new id
        block.outlets = block.outlets.map({ $0.duplicate() })   //copy with new id
        block.center = block.center.shuffle(for: -200...200)
        return block
    }
}

//MARK: - Getter / Setter
extension Block {
    mutating func set(_ value : Any, for key : String){
        attributes[key] = "\(value)"
    }
    
    func getInt(_ key : String, default dValue : Int = 0) -> Int {
        if let str = attributes[key], let value = Int(str) {
            return value
        }
        return dValue
    }
    
    func getDouble(_ key : String, default dValue : Double = 0.0) -> Double {
        if let str = attributes[key], let value = Double(str) {
            return value
        }
        return dValue
    }
    
    func getBool(_ key : String, default dValue : Bool = false) -> Bool {
        if let str = attributes[key], let value = Bool(str) {
            return value
        }
        return dValue
    }
    
    func getString(_ key : String) -> String? {
        return attributes[key]
    }
    
    func getText() -> String {
        if let text = attributes["text"], !text.isEmpty {
            return text
        } else {
            return "nil"
        }
    }
//    func getURL(_ key : String, default dValue: URL = URL(fileURLWithPath: <#String#>)) -> URL? {
//        if let str = attributes[key] {
//            if let url = URL(string: str) {
//                return url
//            }
//        }
//    }
}

//Block.Port class
extension Block {
    
    struct Port : FlowElement, Codable {
        
        var id : String  {
            return identifier
        }
        
        var type : String = "in" // or "outlet"
        
        var datatype : String = "int"
        
        var name : String = "input"
        
        var value: [String] = []
        var input: Bool = false
        
        var connectionIDs : [String] = []
        
        var _identifier = UUID().uuidString
        var _timestamp = Date().timeIntervalSinceReferenceDate
        
        init(type : String) {
            self.type = type
        }
        
        var identifier: String {
            return _identifier
        }
        
        var timestamp: TimeInterval {
            return _timestamp
        }
        
        static func ===(lhs : Port, rhs : Port) -> Bool {
            return lhs.identifier == rhs.identifier && lhs.timestamp == rhs.timestamp && lhs.value == rhs.value && lhs.input == rhs.input && lhs.datatype == rhs.datatype
        }
        
        static func ==(lhs : Port, rhs : Port) -> Bool {
            return lhs.identifier == rhs.identifier && lhs.timestamp == rhs.timestamp && lhs.value == rhs.value && lhs.input == rhs.input && lhs.datatype == rhs.datatype
        }

        mutating func update() {
            self._timestamp = Date().timeIntervalSinceReferenceDate
        }
        
        var isInput : Bool {
            return input || type == "in" || type == "input"
        }
        
        func duplicate() -> Block.Port {
            var port = self
            port._identifier = UUID().uuidString
            return port
        }
    }
    
    var url : URL? {
        if self.className == "USDZObject" {
//            print("=== object === \(self.getString("usdz") ?? "nil") ")
            if let usdz = self.getString("usdz") {
                if let url = Bundle.main.url(forResource: usdz, withExtension: "usdz")  {
                    return url
                }
            }
        }
        return nil
    }
    
}

extension Block {
    struct Point : Codable {
        var x,y,z : CGFloat
        static var zero : Point {
            return Point(x: 0, y: 0, z: 0)
        }
        
        func shuffle(for r: ClosedRange<Int> = -50...50) -> Block.Point {
            let displacement = CGFloat(Int.random(in: r))
            return Block.Point(x: self.x + displacement, y: self.y + displacement, z: self.z + displacement)
        }
        
//        func convert2D(_ coordSystem: EditorState.CoordSystem) -> CGPoint {
//            if coordSystem == .xy {
//                return CGPoint(x: x, y: y)
//            } else {
//                return CGPoint(x: x, y: z)
//            }
//        }
        
        /// Convert the block point into cgpoint for the given cgpoint
        /// - Parameter center: Center Point of the Editor View
        func location(relativeTo center : CGPoint, coordSystem: EditorState.CoordSystem = .xy) -> CGPoint {
            if coordSystem == .xy {
                return CGPoint(x: center.x + x , y: center.y + y )
            } else {
                return CGPoint(x: center.x + x, y: center.y + z)
            }
        }
        
        
        /// Updte the coordinate of block with given CGPoint Information
        /// - Parameters:
        ///   - blockViewCenter: center point of the block view
        ///   - editorCenter: cente rof the editor
        ///   - coordSystem: the coord system (Default: xy)
        mutating func set(with blockViewCenter : CGPoint, relativeTo editorCenter : CGPoint,
                             coordSystem: EditorState.CoordSystem = .xy) {
            if coordSystem == .xy {
                self.x = blockViewCenter.x - editorCenter.x
                self.y = blockViewCenter.y - editorCenter.y
            } else {
                self.x = blockViewCenter.x - editorCenter.x
                self.z = blockViewCenter.y - editorCenter.y
            }
        }
    }
    struct Size : Codable {
        var width, height, depth : CGFloat
        static var zero : Size {
            return Size(width: 0, height: 0, depth: 0)
        }
        
        func convert2D(_ coordSystem: EditorState.CoordSystem) -> CGSize {
            if coordSystem == .xy {
                return CGSize(width: width, height: height)
            } else {
                return CGSize(width: width, height: depth)
            }
        }
    }
}

extension Block {
    
    static func build(around center : Block.Point,
                      inletNo: Int = 1, outletNo : Int = 1) -> Block {
        var block = Block()
        
        for _ in 0..<inletNo {
            block.inlets.append(Block.Port(type: "in"))
        }
        for _ in 0..<outletNo {
            block.outlets.append(Block.Port(type: "out"))
        }
        //calculate the minimum block height & depth
        block.adjustSize(around: center)
        return block
    }
    
    
    
    
    mutating func adjustSize(around center : Block.Point = .zero){
        var block = self

        
        
        let inletNo = block.inlets.count
        let outletNo = block.outlets.count
        
        let maxPortNo = max(inletNo, outletNo)
        
        let minHeight = 30 * CGFloat(maxPortNo + 2) + 52
        let minDepth = minHeight
        
        if block.size.width == 1.0 {
            block.size = Block.Size(width: 90.0,
                                    height: minHeight,
                                    depth: minDepth)
        }
        let offsetX = CGFloat(Int.random(in: -100...100))
        let offsetY = CGFloat(Int.random(in: -100...100))
        let offsetZ = CGFloat(Int.random(in: -100...100))
        block.center = Block.Point(x: center.x + offsetX, y: center.y + offsetY, z: center.z + offsetZ)
        
        self = block
    }
}

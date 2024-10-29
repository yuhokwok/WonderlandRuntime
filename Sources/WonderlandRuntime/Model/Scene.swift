//
//  Scene.swift
//  FBPLand
//
//  Created by Reality Builder Team on 19/2/2022.
//

import UIKit
import SwiftUI
import RealityKit

protocol FlowElementLockable {
    var locked : Bool { get set }
}

struct Scene : FlowElement, FlowTransformable, FlowElementLockable , Codable {
    
    var id : String {
        return identifier
    }

    var blocks = [Block]()
    var connections = [Connection]()
    

    var attributes : [String : String] = [:]
    
    var _identifier = UUID().uuidString
    var _timestamp = Date().timeIntervalSinceReferenceDate
    
    var identifier: String {
        return _identifier
    }
    
    var timestamp: TimeInterval {
        return _timestamp
    }
    
    static func ===(lhs : Scene, rhs : Scene) -> Bool {
        return (lhs.identifier == rhs.identifier &&
                lhs.timestamp == rhs.timestamp &&
                lhs.blocks == rhs.blocks)
    }
    
    static func ==(lhs : Scene, rhs : Scene) -> Bool {
        return  lhs.identifier == rhs.identifier &&
                lhs.timestamp == rhs.timestamp &&
                lhs.blocks == rhs.blocks
    }
    
    mutating func update() {
        self._timestamp = Date().timeIntervalSinceReferenceDate
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
    
    
    //Wonderland

    var displayName : String = ""
    var description : String = ""    
    var isThumbnail : Bool = false

    
    var center : Block.Point  = Block.Point(x: 1024, y: 1024, z: 0)
    var size : Block.Size = .init(width: 200, height: 150, depth: 0)
    var rotation : Block.Point = .zero
    
    var inlets : [Block.Port] = []
    var outlets : [Block.Port] = []
    
    var locked: Bool {
        get {
            self.getBool("lock", default: false)
        }
        set {
            self.set(newValue, for: "lock")
        }
    }
    
    //Wonderland
    static func build() -> Scene {
        var scene = Scene()
        //scene.center = Block.Point(x: 1536, y: 1536, z: 1536)
        let randomX = CGFloat.random(in: 20...100)
        let randomY = CGFloat.random(in: 20...100)
        scene.center = Block.Point(x: randomX, y: randomY, z: 0)
        
        var inPort = Block.Port(type: "scene")
        inPort.datatype = "scene"
        inPort.name = "input"
        inPort.input = true
        scene.inlets = [inPort]
        
        var outPort = Block.Port(type: "scene")
        outPort.datatype = "scene"
        outPort.name = "output"
        outPort.input = false
        scene.outlets = [outPort]
        
        return scene
    }
    
    class EditorState : Codable {

        var center : Block.Point
        var coordSystem : CoordSystem
        var scale : CGFloat
        
        init(center : Block.Point, scale: CGFloat = 1, coordSystem : CoordSystem = .xy) {
            self.center = center
            self.scale = scale
            self.coordSystem = coordSystem
        }
        
        enum CoordSystem : String, Codable {
            case xy = "x-y"
            case xz = "x-z"
        }
    }
    
    func duplicate() -> Scene {
        var scene = self
        scene._identifier = UUID().uuidString
        scene.center = scene.center.shuffle(for: -200...200)
        scene.blocks = scene.blocks.map({ $0.duplicate() })
        scene.inlets = scene.inlets.map({ $0.duplicate() })     //copy with new id
        scene.outlets = scene.outlets.map({ $0.duplicate() })   //copy with new id
        return scene
    }
}


//MARK: - Getter / Setter
extension Scene {
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
}

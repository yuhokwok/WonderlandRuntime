//
//  Runtime.swift
//  FBPLand
//
//  Created by Reality Builder Team on 2/3/2022.
//

import UIKit
import RealityKit
import ARKit
import Combine


extension Runtime {
    static let size : CGFloat = 3072
    static let factor : CGFloat = 0.1
}

protocol RuntimeDelegate {
    func runtime(_ runtime : Runtime, debug: Any?)
    func runtime(_ runtime : Runtime, label: Any?, color: Any?)
    func runtime(_ runtime : Runtime, timer: Any?, color: Any?)
    func runtime(_ runtime : Runtime, timeParam: Any?)
    func runtime(_ runtime : Runtime, scheduleTimer: Any?)
    func runtime(_ runtime : Runtime, nextScene: Any?)
}

extension Runtime {

    class CollisonGroup {
        @MainActor static let systemGroup = CollisionGroup(rawValue: 1 << 0)
        @MainActor static let planeGroup = CollisionGroup(rawValue: 1 << 1)
        @MainActor static let cubeGroup = CollisionGroup(rawValue: 1 << 2)
        @MainActor static let beveledCubeGroup = CollisionGroup(rawValue: 1 << 3)
        @MainActor static let sphereGroup = CollisionGroup(rawValue: 1 << 4)
        @MainActor static let usdzGroup = CollisionGroup(rawValue: 1 << 5)
        @MainActor static let outputGroup = CollisionGroup(rawValue: 1 << 6)
        
        @MainActor static let unaffectedGroup = CollisionGroup(rawValue: 1 << 99999)
    }
}



class Runtime : NSObject {
    
    //USDZ
    var collisionSub : Cancellable?
    var sceneEventSub : Cancellable?
    var sceneEventUpdateSub : Cancellable?
    var removeSub: Cancellable?
    
    var delegate : RuntimeDelegate?
    
    var arView : ARView?
    
    var scene : Scene?
    
    let classRepo = BlockRunner.classRepo
    
    var blockRunners = [BlockRunner]()
    @MainActor var blockPortDispatcher = BlockPortDispatcher.shared
    
    var didRemove: Bool = false
    
    var isAR: Bool = true
    
    @MainActor static let shared = Runtime()
    
    @MainActor var session: ARSession? {
        guard let arView else { return nil }
        return arView.session
    }
    
    func link(arView : ARView){
        self.loaded = false
        self.arView = arView
//        self.arView?.session.delegate = self
    }
    
    func unlink() {
        collisionSub?.cancel()
        sceneEventSub?.cancel()
        sceneEventUpdateSub?.cancel()
        removeSub?.cancel()
        self.scene = nil
        
        //self.arView?.session.delegate = self
        self.arView = nil
    }
    
    
    @MainActor func addEntity(entity : AnchorEntity){
        self.arView?.scene.addAnchor(entity)
    }
    
    var hasARPlane = false
    var loaded = false
    
    var portIdToBlockInfo: [String: (block: Block, portIndex: Int, isOutlet: Bool)] = [:]


    
    @MainActor func intialize(scene : Scene, with acnhor : ARPlaneAnchor, build: (BlockRunner)->Void) {
        
        collisionSub?.cancel()
        sceneEventSub?.cancel()
        sceneEventUpdateSub?.cancel()
        removeSub?.cancel()
        
        self.clearUp()
        
        
        self.scene = scene
        
        self.loaded = false
        
//        self.arView?.session.delegate = self
        
        self.collisionSub = self.arView?.scene.subscribe(to: CollisionEvents.Began.self, {
            event in
            
            self.dispatchCollisionEvent(event: event)
            
        })
        
        
        self.sceneEventUpdateSub = self.arView?.scene.subscribe(to: SceneEvents.Update.self, {
            event in
            
            if self.loaded == false {
                
                guard let scene = self.scene else {
                    return
                }
                self.loaded = true
                
                DispatchQueue.main.async {
                    print("yoyo")
                    //1 - create block
                    for block in scene.blocks {
                        let className = "\(block.className)Block"
                        print("Wonderland::Runtime::Creating: \(className)")
                        if let blockClass = Bundle.main.classNamed("Reality_Builder.\(className)")  {
                            if let blockRunner = Runtime.shared.initBlockRunner(classType: blockClass) {
                                blockRunner.loadBlock(block: block, runtime: self)
                                if let blockRunner = blockRunner as? USDZObjectBlock {
                                    if let session = self.session, let query = ObjectBlock.query {
                                        session.trackedRaycast(query, updateHandler: { (results) in
                                            guard let result = results.first, let wrappedBoxEntity = blockRunner.wrappedBoxEntity, let anchorEntity = blockRunner.anchorEntity else {
                                                fatalError("Wonderland::Unexpected case: the update handler is always supposed to return at least one result.")
                                            }
                                            print("Wonderland::Runtime:::trackedRaycast result: \(result)")
                                            wrappedBoxEntity.transform.matrix = result.worldTransform
                                            
                                            if wrappedBoxEntity.parent == nil {
                                                anchorEntity.addChild(wrappedBoxEntity)
                                                Runtime.shared.addEntity(entity: anchorEntity)
                                            }
                                            
                                            
                                        })
                                    }
                                }
                                self.blockRunners.append(blockRunner)
                                print("Wonderland::Runtime::\(className) created")
                            }
                        }
                    }
                    
                    //2 - register for connection
                    for connection in scene.connections {
                        print("Wonderland::Runtime::set route from: \(connection.sourceId) to \(connection.destinationId)")
                        if let destInfo = self.portIdToBlockInfo[connection.destinationId] {
                                        self.blockPortDispatcher.route(from: connection.sourceId, to: connection.destinationId, destPortIndex: destInfo.portIndex)
                                    }
//                        self.blockPortDispatcher.route(from: connection.sourceId, to: connection.destinationId)
                    }
                    
                    //3 - start execute
                    for blockRunner in self.blockRunners {
                        if blockRunner.inPorts.count == 0 {
                            blockRunner.execute()
                        }
                    }
                }
            }
        })
        
        self.sceneEventSub = self.arView?.scene.subscribe(to: SceneEvents.AnchoredStateChanged.self, {
            event in
            //print("this is a event: \(event)")
            
        })
        
    }
    
    @MainActor func intialize(scene : Scene, build: (BlockRunner)->Void) {

        collisionSub?.cancel()
        sceneEventSub?.cancel()
        sceneEventUpdateSub?.cancel()
        self.clearUp()
        
        
        self.scene = scene
        
        self.loaded = false
        
//        self.arView?.session.delegate = self
        
        self.collisionSub = self.arView?.scene.subscribe(to: CollisionEvents.Began.self, {
            event in
            
            self.dispatchCollisionEvent(event: event)
            
        })
        
        self.removeSub = self.arView?.scene.subscribe(to: SceneEvents.WillRemoveEntity.self, {
            event in
            
            self.dispatchRemoveEvent(event: event)
            
        })
        
        if self.loaded == false {
            
            guard let scene = self.scene else {
                return
            }
            self.loaded = true
            
            //                let encoder = JSONEncoder()
            //                if let data = try? encoder.encode(scene) {
            //                    let string = String(data: data, encoding: .utf8)
            //                    print(string)
            //                }
            
            DispatchQueue.main.async {
                print("Wonderland::Runtime::: intialize scene.blocks count: \(scene.blocks .count)")
                //1 - create block
                for block in scene.blocks {
                    let className = "\(block.className)Block"
                    print("Wonderland::Runtime::Creating: \(className)")
                    if let blockClass = Bundle.main.classNamed("Reality_Builder.\(className)")  {
                        if let blockRunner = Runtime.shared.initBlockRunner(classType: blockClass) {
                            blockRunner.loadBlock(block: block, runtime: self)
                            self.blockRunners.append(blockRunner)
                            print("Wonderland::Runtime::\(className) created")
                        }
                    }
                }
                
                //2 - register for connection
                for connection in scene.connections {
                    print("Wonderland::Runtime::set route from: \(connection.sourceId) to \(connection.destinationId)")
//                    self.blockPortDispatcher.route(from: connection.sourceId, to: connection.destinationId)
                    if let destInfo = self.portIdToBlockInfo[connection.destinationId] {
                                    self.blockPortDispatcher.route(from: connection.sourceId, to: connection.destinationId, destPortIndex: destInfo.portIndex)
                                }
                }
                
                //3 - start execute
                for blockRunner in self.blockRunners {
                    if (blockRunner.inPorts.count == 0 || blockRunner.block?.type == "object") && blockRunner.block?.className != "WhenGameStart"{
                    
                            blockRunner.execute()
                        
                    }
                }
                
                for blockRunner in self.blockRunners {
                    if blockRunner.inPorts.count == 0 && blockRunner.block?.className == "WhenGameStart"{
                            blockRunner.execute()
                    }
                }
            }
        }
        
        
        self.sceneEventUpdateSub = self.arView?.scene.subscribe(to: SceneEvents.Update.self, { [self]
            event in

        })
        
        self.sceneEventSub = self.arView?.scene.subscribe(to: SceneEvents.AnchoredStateChanged.self, {
            event in
            //print("this is a event: \(event)")
            
        })
        
        
        
    }

    @MainActor func clearUp(){
        blockPortDispatcher.close()
        
        for blockRunner in blockRunners {
            blockRunner.close()
            
            if let usdzBlockRunner = blockRunner as? USDZObjectBlock {
                usdzBlockRunner.modelEntity?.removeFromParent()
                
                if let anchor = usdzBlockRunner.anchorEntity {
                    self.arView?.scene.removeAnchor(anchor)
                }
                
            } else if let primitive = blockRunner as? PrimitiveObjectBlock {
                primitive.entity?.removeFromParent()
                
                if let anchor = primitive.anchorEntity {
                    self.arView?.scene.removeAnchor(anchor)
                }
            }
        }
        
        self.blockRunners.removeAll()
    }
    
    @MainActor func dispatchCollisionEvent(event : CollisionEvents.Began) {
        for blockRunner in blockRunners {
            print(blockRunner)
            if let objectCollisionRunner = blockRunner as? ObjectCollisionBlock {
                objectCollisionRunner.trigger(input: event)
            }
        }
    }
    
    @MainActor func dispatchRemoveEvent(event : SceneEvents.WillRemoveEntity) {
        for blockRunner in blockRunners {
            print(blockRunner)
            if let objectCollisionRunner = blockRunner as? ObjectBreakBlock {
                objectCollisionRunner.trigger(input: event)
            }
        }
    }
    
    @MainActor func DoubleTap() {
        for blockRunner in blockRunners {
            if let doubleTapOnScreenRunner = blockRunner as? DoubleTapOnScreenBlock {
                doubleTapOnScreenRunner.trigger()
            }
        }
    }
    
    @MainActor func touchDown(){
        for blockRunner in blockRunners {
            if let tapOnScreenRunner = blockRunner as? TapOnScreenBlock {
                tapOnScreenRunner.tapDown()
            }
        }
    }
    
    @MainActor func touchUp(){
        for blockRunner in blockRunners {
            if let tapOnScreenRunner = blockRunner as? TapOnScreenBlock {
                tapOnScreenRunner.tapUp()
            }
        }
    }
    
    //    func touch(at location : CGPoint){
    @MainActor func touch(at touch : UITouch){
        for blockRunner in blockRunners {
            if let touchRunner = blockRunner as? TouchAtLocationBlock {
                //                touchRunner.touch(at: location)
                touchRunner.touch(at: touch)
            } else if let tapOnObjectRunner = blockRunner as? TapOnObjectBlock {
                tapOnObjectRunner.touch(at: touch)
            }
        }
    }
    
    
    var subclasses = [ClassInfo]()
    @MainActor override fileprivate init(){
        self.subclasses = Runtime.getSubclassInfos()
    }
    
    static func getSubclassInfos() -> [ClassInfo]{
        let superObject = BlockRunner.self
        let superClassInfo = ClassInfo(superObject)
        
        var count = UInt32(0)
        guard let classListPoint = objc_copyClassList(&count) else {
            return []
        }
        
        print("count: \(count)")
        return UnsafeBufferPointer(start: classListPoint, count: Int(count))
            .compactMap(ClassInfo.init)
            .filter{
                return $0.superClassInfo == superClassInfo
            }
    }
    
    @MainActor func initBlockRunner(classType : AnyClass) -> BlockRunner? {
        let name = NSStringFromClass(classType)
        for subclass in classRepo {
            if name == NSStringFromClass(subclass) {
                return subclass.init()
            }
        }
        return nil
    }
    
    class ClassInfo : CustomStringConvertible, Equatable {
        let classObject : AnyClass
        let className : String
        
        init?(_ classObject : AnyClass?) {
            guard classObject != nil else { return nil }
            
            self.classObject = classObject!
            
            let cName = class_getName(classObject!)
            
            self.className = String(cString: cName)
        }
        
        var superClassInfo : ClassInfo? {
            let superclassObject : AnyClass? = class_getSuperclass(self.classObject)
            return ClassInfo(superclassObject)
        }
        
        var description: String {
            return self.className
        }
        
        static func ==(lhs: ClassInfo, rhs: ClassInfo) -> Bool {
            return lhs.className == rhs.className
        }
    }
    
    func hexStringToUIColor (hex: String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
}

extension SIMD4 {
    
    var xyz: SIMD3<Scalar> {
        return self[SIMD3(0, 1, 2)]
    }
    
}

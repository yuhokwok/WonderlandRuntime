//
//  Constant.swift
//  FBPLand
//
//  Created by Reality Builder Team on 2/3/2022.
//

import UIKit
import RealityKit

import ARKit


class ObjectBlock : BlockRunner {
    @MainActor static var sharedAnchor : ARAnchor?
    @MainActor static var worldTransform : simd_float4x4?
    @MainActor static var query : ARRaycastQuery?
}

class USDZObjectBlock : BlockRunner {
    var modelEntity : ModelEntity? = nil
    var wrappedBoxEntity : ModelEntity? = nil
    var anchorEntity : AnchorEntity? = nil
    
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        print("Wonderland::USDZObjectBlock::execute")
        guard let modelEntity else { return }
        if let msg = message as? [String: Any]{
            if let entity = msg["param"] as? Entity, entity.name == modelEntity.name {
                for outPort in outPorts {
                    self.send(port: outPort, message: msg)
                }
            }
        } else {
            
            let messageToSend = ["param": modelEntity] as [String : Any]
            for outPort in outPorts {
                self.send(port: outPort, message: messageToSend)
            }
        }
    
    }
        
    override func loadBlock(block: Block, runtime: Runtime) {
        
        print("Wonderland::USDZObjectBlock::load block")
//        print("======")
//        print("\(block)")
//        print("======")
               
        
        super.loadBlock(block: block, runtime: runtime)
        
        if runtime.isAR {
            guard let usdz = block.getString("usdz") else {
                return
            }
            
            let path = block.getString("path")
            let objectType = block.getString("objectType")
            
            //To Do - load object capture, load room scan, load imported usdz
            let entity : ModelEntity?
            
            if let fileName = path, let objectType = objectType {
                print("load user: \(path)")
                if fileName.contains("file:///") {
                    
                    print("loading file")
                    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
                       let originalURL = URL(string: fileName) {
                        
                        let originalPath = originalURL.path
                        let documentsPrefix = "/Documents/"
                        
                        guard let range = originalPath.range(of: documentsPrefix) else { return }
                        
                        let relativePath = originalPath[range.upperBound...]
                        let newFullPath = documentsDirectory.appendingPathComponent(String(relativePath))
                        
                        let url = newFullPath
                        entity = try? ModelEntity.loadModel(contentsOf: url)
                    } else {
                        entity = nil
                    }
                } else {
                    if let url = AppFolderManager.getUSDZURL(objectType: objectType, fileName: fileName) {
                        entity = try? ModelEntity.loadModel(contentsOf: url)
                    } else {
                        entity = nil
                    }
                }
            } else {
                entity = try? ModelEntity.loadModel(named: usdz)
            }
            entity?.name = block.displayName
            self.modelEntity = entity
            
            guard let modelEntity = entity else {
                print("failed to load entity")
                return
            }
            
            if block.category == "My Model" {
                modelEntity.scale = [5, 5, 5]
            }
            print("o scale: \(modelEntity.scale)")
            
            print("scale: \(block.objectGeo.scale)")
            
            print("center : \(block.center)")
            
            
            wrappedBoxEntity = modelEntity.wrapEntityAndSetPivotPosition(to: .bottom)
            modelEntity.transform.rotation = simd_quatf(vector: block.objectGeo.rotation)
            
            guard let wrappedBoxEntity else { return }
            
            let mode = block.getInt("physicsBodyMode")
            
            let canCollide = block.getBool("canCollide", default: false)
            if mode == 0 {
                print("no physics")
            } else {
                let model :  PhysicsBodyMode
                var continuous = false
                if mode == 1{
                    print("static")
                    model = .static
                    continuous = true
                } else if mode == 2 {
                    print("kinematic")
                    model = .kinematic
                    continuous = true
                } else {
                    print("dynamic")
                    model = .dynamic
                    continuous = true
                }
                modelEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: model)
                //            modelEntity.physicsBody?.isContinuousCollisionDetectionEnabled = continuous
                
            }
            
            if canCollide == true {
                print("generate collision")
                modelEntity.generateCollisionShapes(recursive: true)
            }
            
            modelEntity.collision?.filter = CollisionFilter(group: Runtime.CollisonGroup.usdzGroup, mask: .all)
            
#if targetEnvironment(simulator)
            //        anchorEntity = AnchorEntity(world: center)
#else
            
            
            if let anchor = ObjectBlock.sharedAnchor {
                self.anchorEntity = AnchorEntity(anchor: anchor)
            } else {
                anchorEntity = AnchorEntity(plane: .horizontal)
            }
            
            let scale = 0.1 * block.objectGeo.scale
            wrappedBoxEntity.scale = scale
            let center = block.objectGeo.center * 0.1
            wrappedBoxEntity.transform.translation = center
            wrappedBoxEntity.name = block.displayName
            anchorEntity?.addChild(wrappedBoxEntity)
            Runtime.shared.addEntity(entity: anchorEntity!)
            
            
            
            print("cccc: \(block.objectGeo.center)")
#endif
            
            
            let canMove = block.getBool("canMove", default: false)
            let canRotate = block.getBool("canRotate", default: false)
            
            if canMove == true {
                runtime.arView?.installGestures(.translation, for: modelEntity)
            }
            if canRotate == true {
                runtime.arView?.installGestures(.rotation, for: modelEntity)
            }
        } else {
//            guard let entity = findAllEntities(named: "content", runtime: runtime) else { return }
//            self.modelEntity = entity
            let contentEntities = findAllEntities(named: "content", runtime: runtime)
            for contentEntity in contentEntities {
//                    print("Content entity: \(contentEntity.translateEntity?.name)")
                guard let childId = contentEntity.translateEntity?.name else { continue }
                if block.identifier == childId, let contentEntity = contentEntity as? ModelEntity {
                    modelEntity = contentEntity
                    guard let modelEntity = modelEntity else { return }
                    let mode = block.getInt("physicsBodyMode")
                    let canCollide = block.getBool("canCollide", default: false)
                    if mode == 0 {
                        print("no physics")
                    } else {
                        let model :  PhysicsBodyMode
                        var continuous = false
                        if mode == 1{
                            print("static")
                            model = .static
                            continuous = true
                        } else if mode == 2 {
                            print("kinematic")
                            model = .kinematic
                            continuous = true
                        } else {
                            print("dynamic")
                            model = .dynamic
                            continuous = true
                        }
                        modelEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: model)
                        //            modelEntity.physicsBody?.isContinuousCollisionDetectionEnabled = continuous
                        
                        if canCollide == true {
                            print("generate collision")
                            modelEntity.generateCollisionShapes(recursive: true)
                        }
                        
                        modelEntity.collision?.filter = CollisionFilter(group: Runtime.CollisonGroup.usdzGroup, mask: .all)
                    }
                }
            }
        }
    }
    
    @MainActor func findAllEntities(named name: String, runtime: Runtime) -> [Entity] {
        guard let arView = runtime.arView else { return [] }
        var matchingEntities: [Entity] = []
        
        func traverse(entity: Entity) {
            if entity.name == name {
                matchingEntities.append(entity)
            }
            for child in entity.children {
                traverse(entity: child)
            }
        }
        
        for anchor in arView.scene.anchors {
            traverse(entity: anchor)
        }
        
        return matchingEntities
    }
}



class PrimitiveObjectBlock : BlockRunner {
    var entity : ModelEntity? = nil
    var anchorEntity : AnchorEntity? = nil
    
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        if let msg = message as? String {
            if msg == "1" {
                // Add entity to anchor
                anchorEntity!.addChild(self.entity!)
                // Place anchor in the scene
                Runtime.shared.addEntity(entity: anchorEntity!)

                for outPort in outPorts {
                    self.send(port: outPort, message: entity)
                }
            }
        } else if let msg = message as? Int {
            for outPort in outPorts {
                self.send(port: outPort, message: entity)
            }
        } else if let msg = message as? Entity {
            anchorEntity!.addChild(self.entity!)
            Runtime.shared.addEntity(entity: anchorEntity!)

            for outPort in outPorts {
                self.send(port: outPort, message: entity)
            }
            
        } else if let position = message as? SIMD3<Float> {
            // set entity position with received param
            entity!.setPosition(position, relativeTo: nil)

            anchorEntity!.addChild(entity!)
            Runtime.shared.addEntity(entity: anchorEntity!)

            for outPort in outPorts {
                self.send(port: outPort, message: entity)
            }
            
        } else {
            return
        }
    
    }
    
    
    override func loadBlock(block: Block, runtime: Runtime) {
        
        super.loadBlock(block: block, runtime: runtime)
        
        guard let primitive = block.getString("primitive"), let color = block.attributes["color"] as? String else {
            return
        }
        
        let objectColor = UIColor.color(hex: color)
        
        let mesh : MeshResource
        switch primitive {
        case "cube":
            print("generate box")
            mesh = MeshResource.generateBox(size: [Float(block.size.width / 10),
                                                   Float(block.size.height / 10),
                                                   Float(block.size.depth  / 10)])
        default:
            print("generate sphere")
            mesh = MeshResource.generateSphere(radius: Float(block.size.width  / 10))
            
        }
        
        print(block.size)
        
        let _material = SimpleMaterial(color: objectColor, isMetallic: false)
        entity = ModelEntity(mesh: mesh, materials: [_material])
        entity?.setScale([Float(Runtime.factor), Float(Runtime.factor), Float(Runtime.factor)],  relativeTo: nil)
        
        
        var center = self.convert(x: block.center.x ,
                                  y: block.center.y ,
                                  z: block.center.z )
        
        
        let mode = block.getInt("physicsBodyMode")
//        let canBreak = block.getBool("canBreak", default: false)
        let canCollide = block.getBool("canCollide", default: false)
        if mode == 0 {
            print("no physics")
        } else {
            let model :  PhysicsBodyMode
            var continuous = false
            if mode == 1{
                print("static")
                model = .static
                continuous = true
            } else if mode == 2 {
                print("kinematic")
                model = .kinematic
                continuous = false
            } else {
                print("dynamic")
                model = .dynamic
                continuous = true
            }
            entity?.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: model)
            entity?.physicsBody?.isContinuousCollisionDetectionEnabled = continuous
        }
        
        if canCollide == true {
            print("generate collision")
            entity?.generateCollisionShapes(recursive: true)
        }
        
        //print("\(entity.collision)")
        //entity.collision?.filter = .sensor
        
//        entity.collision?.filter = CollisionFilter(group: Runtime.CollisonGroup.usdzGroup, mask: .all)
        if primitive == "cube" {
            entity?.collision?.filter = CollisionFilter(group: Runtime.CollisonGroup.cubeGroup, mask: .all)
        } else {
            entity?.collision?.filter = CollisionFilter(group: Runtime.CollisonGroup.sphereGroup, mask: .all)
        }
        
        //entity.collision = CollisionComponent(shapes: [.generateBox(size: [0.5, 0.5, 0.5])],
        //                                      mode: .trigger,
        //                                      filter: .sensor)
        
        /*
        entity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .dynamic)
        
        entity.physicsMotion = .init(linearVelocity: [0.1 ,0, 0],
                                     angularVelocity: [3, 3, 3])
        */
        print("primitive: \(center), \(entity?.scale)")
        
        let scale = entity!.scale * 1000
        entity?.scale = scale
        // Create anchor
        #if targetEnvironment(simulator)
        anchorEntity = AnchorEntity(world: center)
        #else
        entity?.setPosition(center, relativeTo: nil)
        anchorEntity = AnchorEntity(plane: .horizontal)
        #endif
        
        var isCreateNow : Bool = true
        for con in Runtime.shared.scene!.connections {
            if block.inlets[0].identifier == con.destinationId {
                isCreateNow = false
            }
        }
        
        let canMove = block.getBool("canMove", default: false)
        let canRotate = block.getBool("canRotate", default: false)
        
        if canMove == true {
            runtime.arView?.installGestures(.translation, for: entity!)
        }
        if canRotate == true {
            runtime.arView?.installGestures(.rotation, for: entity!)
        }
        
        if isCreateNow {
            // Add entity to anchor
            anchorEntity?.addChild(self.entity!)
            // Place anchor in the scene
            runtime.addEntity(entity: anchorEntity!)
        }

    }
}


class TextObjectBlock : BlockRunner {
    var modelEntity : ModelEntity? = nil
    var wrappedBoxEntity : ModelEntity? = nil
    var anchorEntity : AnchorEntity? = nil
    
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        print("TextObjectBlock::: execute")
        guard let modelEntity else { return }
        if let msg = message as? [String: Any]{
            if let entity = msg["param"] as? Entity, entity.name == modelEntity.name {
                for outPort in outPorts {
                    self.send(port: outPort, message: msg)
                }
            }
        } else {
            
            let messageToSend = ["param": modelEntity] as [String : Any]
            for outPort in outPorts {
                self.send(port: outPort, message: messageToSend)
            }
        }
    }

    
    override func loadBlock(block: Block, runtime: Runtime) {
        
        super.loadBlock(block: block, runtime: runtime)
        
        let text = block.getText()
//        guard let text = block.getText(), let color = block.attributes["color"] as? String else {
//            return
//        }
    
        let meshText = MeshResource.generateText(text, extrusionDepth: 0.02, font: .systemFont(ofSize: 0.2/2), containerFrame: .zero, alignment: .center, lineBreakMode: .byCharWrapping)
        let material = SimpleMaterial(color: .blue, isMetallic: true)
        let entity = ModelEntity(mesh: meshText, materials: [material])
        
        entity.name = block.displayName
        self.modelEntity = entity
        
        let modelEntity = entity
        
        modelEntity.scale = [5, 5, 5]
        print("o scale: \(modelEntity.scale)")
        
        print("scale: \(block.objectGeo.scale)")

        print("center : \(block.center)")

        wrappedBoxEntity = modelEntity.wrapEntityAndSetPivotPosition(to: .bottom)
        modelEntity.transform.rotation = simd_quatf(vector: block.objectGeo.rotation)
        
        guard let wrappedBoxEntity else { return }
        
        let mode = block.getInt("physicsBodyMode")

        let canCollide = block.getBool("canCollide", default: false)
        if mode == 0 {
            print("no physics")
        } else {
            let model :  PhysicsBodyMode
            var continuous = false
            if mode == 1{
                print("static")
                model = .static
                continuous = true
            } else if mode == 2 {
                print("kinematic")
                model = .kinematic
                continuous = true
            } else {
                print("dynamic")
                model = .dynamic
                continuous = true
            }
            modelEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: model)
//            modelEntity.physicsBody?.isContinuousCollisionDetectionEnabled = continuous

        }
        
        if canCollide == true {
            print("generate collision")
            modelEntity.generateCollisionShapes(recursive: true)
        }
        
        modelEntity.collision?.filter = CollisionFilter(group: Runtime.CollisonGroup.usdzGroup, mask: .all)

        #if targetEnvironment(simulator)
//        anchorEntity = AnchorEntity(world: center)
        #else
        
        
        if let anchor = ObjectBlock.sharedAnchor {
            self.anchorEntity = AnchorEntity(anchor: anchor)
        } else {
            anchorEntity = AnchorEntity(plane: .horizontal)
        }
        
        let scale = 0.1 * block.objectGeo.scale
        wrappedBoxEntity.scale = scale
        let center = block.objectGeo.center * 0.1
        wrappedBoxEntity.transform.translation = center
        wrappedBoxEntity.name = block.displayName
        anchorEntity?.addChild(wrappedBoxEntity)
        Runtime.shared.addEntity(entity: anchorEntity!)
        
        
        
        print("cccc: \(block.objectGeo.center)")
        #endif
        
        
        let canMove = block.getBool("canMove", default: false)
        let canRotate = block.getBool("canRotate", default: false)
        
        if canMove == true {
            runtime.arView?.installGestures(.translation, for: modelEntity)
        }
        if canRotate == true {
            runtime.arView?.installGestures(.rotation, for: modelEntity)
        }

    }
}

class CloneObject {
    
    @MainActor func createObject(originalObject: ModelEntity, position: SIMD3<Float>){
        print("Create USDZ at: \(position)")
        
        let mesh = (originalObject.model?.mesh)!
        let _material = originalObject.model?.materials
        let newEntity = ModelEntity(mesh: mesh, materials: _material!)
        
        newEntity.scale = originalObject.scale
        newEntity.physicsBody = originalObject.physicsBody
        newEntity.collision = originalObject.collision
        newEntity.collision?.filter = originalObject.collision!.filter
        
        newEntity.setPosition(position, relativeTo: nil)
        let anchorEntity = AnchorEntity(world: position)
        
        anchorEntity.addChild(newEntity)
        
        Runtime.shared.addEntity(entity: anchorEntity)
        
    }
    
}

//
//class ToyBiplaneObjectBlock : BlockRunner {
//    var entity : ModelEntity? = nil
//
//    override func loadBlock(block: Block, runtime: Runtime) {
//        //To Do
//        let entity = try? ModelEntity.loadModel(named: "toy_biplane")
//        self.entity = entity
//        guard let entity = entity else {
//            print("failed to load entity")
//            return
//        }
//
//        entity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .dynamic)
//        entity.generateCollisionShapes(recursive: true)
//        entity.physicsMotion = .init(linearVelocity: [0.1 ,0, 0],
//                                     angularVelocity: [3, 3, 3])
//
//
//
//        // Create anchor
//        #if targetEnvironment(simulator)
//        let anchorEntity = AnchorEntity(world: SIMD3(0,-0.2,-0.3))
//        #else
//        let anchorEntity = AnchorEntity(plane: .horizontal)
//        #endif
//
//        //AnchorEntity(world: SIMD3(0,-0.2,-0.3))
//        // Add entity to anchor
//        anchorEntity.addChild(entity)
//        // Place anchor in the scene
//        runtime.addEntity(entity: anchorEntity)
//
//
//        runtime.arView?.installGestures([.translation], for: entity)
//    }
//}
//
//class ToyDrummerObjectBlock : BlockRunner {
//    var entity : ModelEntity? = nil
//
//    override func loadBlock(block: Block, runtime: Runtime) {
//        //To Do
//        let entity = try? ModelEntity.loadModel(named: "toy_drummer")
//        self.entity = entity
//        guard let entity = entity else {
//            print("failed to load entity")
//            return
//        }
//
//        entity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .dynamic)
//
//        entity.physicsMotion = .init(linearVelocity: [0.1 ,0, 0],
//                                     angularVelocity: [3, 3, 3])
//
//        // Create anchor
//        //let anchorEntity = AnchorEntity(world: SIMD3(-0.3,-0.2,-0.3))
//        #if targetEnvironment(simulator)
//        let anchorEntity = AnchorEntity(world: SIMD3(0,-0.2,-0.3))
//        #else
//        let anchorEntity = AnchorEntity(plane: .horizontal)
//        #endif
//        // Add entity to anchor
//        anchorEntity.addChild(entity)
//        // Place anchor in the scene
//        runtime.addEntity(entity: anchorEntity)
//    }
//}




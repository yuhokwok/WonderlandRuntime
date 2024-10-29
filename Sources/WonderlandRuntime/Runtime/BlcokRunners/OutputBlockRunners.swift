//
//  OutputBlockRunners.swift
//  FBPLand
//
//  Created by Reality Builder Team on 3/3/2022.
//

import UIKit
import RealityKit
import AVFoundation

class AnimationBlockRunner: BlockRunner {
    var params = [Int : Any]()
    var originalPhysicsBody: PhysicsBodyComponent?
    var movesInProgress = 0
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        guard let msg = message as? [String: Any] else {
            return
        }
        
        guard let eventType = msg["eventType"] as? String else {
            print("AnimationBlockRunner::: Int: \(destPortIndex)")
            guard let destPortIndex, let receivedParam = msg["param"] else {
                return
            }
            params[destPortIndex] = receivedParam
            return
        }
        let receivedEntity = msg["entity"] as? ModelEntity
        
        switch eventType {
        case "trigger":
            handleTrigger(with: receivedEntity)
        default:
            break
        }
    }
    
    @MainActor func handleTrigger(with receivedEntity: ModelEntity?) {
        // To be implemented by subclasses
    }
    
    @MainActor func parseInlets(from block: Block?, indices: [Int]) -> [[String]]? {
        guard let block = block else {
            print("Block is nil; cannot retrieve inlets.")
            return nil
        }
        
        var values = [[String]]()
        for index in indices {
            if index < block.inlets.count,
               let value = block.inlets[index].value as? [String] {
                values.append(value)
            } else {
                print("Unable to retrieve value from inlet at index \(index).")
                return nil
            }
        }
        return values
    }
}

class MoveBlock: AnimationBlockRunner {
    
    override func handleTrigger(with receivedEntity: ModelEntity?) {
        guard let entity = params[1] as? ModelEntity ?? receivedEntity else {
            print("Entity not found during trigger event.")
            return
        }
        guard let (translation, duration) = parseTranslationAndDuration(from: self.block) else {
            return
        }
        moveObject(object: entity, translation: translation, duration: duration)
    }
    
    @MainActor private func parseTranslationAndDuration(from block: Block?) -> (SIMD3<Float>, CGFloat)? {
        guard let values = parseInlets(from: block, indices: [2, 3]),
              values.count == 2,
              let translationStr = values.first,
              let durationStrArray = values.last,
              let durationStr = durationStrArray.first else {
            print("Unable to parse translation and duration.")
            return nil
        }
        
        guard translationStr.count == 3,
              let xTranslation = Float(translationStr[2]),
              let yTranslation = Float(translationStr[1]),
              let zTranslation = Float(translationStr[0]),
              let duration = Float(durationStr) else {
            print("Unable to parse translation values or duration.")
            return nil
        }
        
        let translation = SIMD3<Float>(
            xTranslation / 10,
            yTranslation / 10,
            zTranslation / 10
        )
        
        return (translation, CGFloat(duration))
    }
    
    @MainActor func moveObject(object: ModelEntity, translation: SIMD3<Float>, duration: Double) {
        if originalPhysicsBody == nil {
            originalPhysicsBody = object.physicsBody
        }
        object.generateCollisionShapes(recursive: true)
        object.physicsBody = PhysicsBodyComponent(
            massProperties: .default,
            material: .default,
            mode: .kinematic
        )
        
        movesInProgress += 1
        let newTranslation = object.transform.translation + translation
        
        let targetTransform = Transform(
            scale: object.transform.scale,
            rotation: object.transform.rotation,
            translation: newTranslation
        )
        
        object.move(
            to: targetTransform,
            relativeTo: object.parent,
            duration: duration,
            timingFunction: .default
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.movesInProgress -= 1 // Decrement the counter
            if self.movesInProgress == 0 {
                // Only reset the physicsBody when all animations have completed
                guard let originalPhysicsBody = self.originalPhysicsBody else { return }
                object.physicsBody = originalPhysicsBody
                print("Final position after animation: \(object.transform.translation)")
            }
        }
    }
}

class RotateBlock: AnimationBlockRunner {
    override func handleTrigger(with receivedEntity: ModelEntity?) {
        guard let entity = params[1] as? ModelEntity ?? receivedEntity else {
            print("Entity not found during trigger event.")
            return
        }
        guard let (rotationAngles, duration) = parseRotationAndDuration(from: self.block) else {
            return
        }
        rotateObject(object: entity, rotationAngles: rotationAngles, duration: duration)
    }
    
    @MainActor private func parseRotationAndDuration(from block: Block?) -> ([CGFloat], CGFloat)? {
        guard let values = parseInlets(from: block, indices: [2, 3]),
              values.count == 2,
              let rotationStr = values.first,
              let durationStrArray = values.last,
              let durationStr = durationStrArray.first else {
            print("Unable to parse rotation angles and duration.")
            return nil
        }
        
        guard rotationStr.count == 3,
              let xRotation = Double(rotationStr[0]),
              let yRotation = Double(rotationStr[1]),
              let zRotation = Double(rotationStr[2]),
              let duration = Double(durationStr) else {
            print("Unable to parse rotation angles or duration.")
            return nil
        }
        
        let rotationAngles = [CGFloat(xRotation), CGFloat(yRotation), CGFloat(zRotation)]
        return (rotationAngles, CGFloat(duration))
    }
    
    @MainActor func rotateObject(object: ModelEntity, rotationAngles: [CGFloat], duration: CGFloat) {
        if originalPhysicsBody == nil {
            originalPhysicsBody = object.physicsBody
        }
        let rotation = simd_quatf(angle: Float(rotationAngles[0] * (.pi / 180.0)), axis: SIMD3<Float>(1, 0, 0)) *
        simd_quatf(angle: Float(rotationAngles[1] * (.pi / 180.0)), axis: SIMD3<Float>(0, 1, 0)) *
        simd_quatf(angle: Float(rotationAngles[2] * (.pi / 180.0)), axis: SIMD3<Float>(0, 0, 1))
        movesInProgress += 1
        let targetTransform = Transform(
            scale: object.transform.scale,
            rotation: object.transform.rotation * rotation,
            translation: object.transform.translation
        )
        
        object.generateCollisionShapes(recursive: true)
        object.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic)
        
        object.move(to: targetTransform, relativeTo: object.parent, duration: duration, timingFunction: .linear)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.movesInProgress -= 1 // Decrement the counter
            if self.movesInProgress == 0 {
                // Only reset the physicsBody when all animations have completed
                guard let originalPhysicsBody = self.originalPhysicsBody else { return }
                object.physicsBody = originalPhysicsBody
                print("Final position after animation: \(object.transform.translation)")
            }
        }
    }
}

class OrbitBlock: AnimationBlockRunner {
    override func handleTrigger(with receivedEntity: ModelEntity?) {
        guard let entity = params[1] as? ModelEntity ?? receivedEntity else {
            print("Entity not found during trigger event.")
            return
        }
        let pivotEntity = params[2] as? ModelEntity ?? ModelEntity()
        
        guard let (radius, duration) = parseOrbitParameters(from: self.block) else {
            return
        }
        
        orbitObject(object: entity, centerEntity: pivotEntity, radius: radius, duration: duration)
    }
    
    @MainActor private func parseOrbitParameters(from block: Block?) -> (Float, Double)? {
        guard let values = parseInlets(from: block, indices: [3, 4]),
              values.count == 2,
              let radiusStrArray = values.first,
              let durationStrArray = values.last,
              let radiusStr = radiusStrArray.first,
              let durationStr = durationStrArray.first,
              let radius = Float(radiusStr),
              let duration = Double(durationStr) else {
            print("Unable to parse radius or duration.")
            return nil
        }
        return (radius, duration)
    }
    
    @MainActor func orbitObject(object: ModelEntity, centerEntity: ModelEntity, radius: Float, duration: CGFloat) {
        guard let objectParent = object.parent, let centerParentEntity = centerEntity.parent else { return }
        
        object.generateCollisionShapes(recursive: false)
        object.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
        
        let yAxis: SIMD3<Float> = [0, 1, 0]
        
        objectParent.transform.translation = centerParentEntity.transform.translation
        let startingPosition = SIMD3<Float>(radius, 0, 0)
        
        let orbit = OrbitAnimation(
            name: "orbitAroundCenter",
            duration: duration,
            axis: yAxis,
            startTransform: Transform(translation: startingPosition),
            spinClockwise: false,
            orientToPath: true,
            rotationCount: 1,
            bindTarget: .transform,
            repeatMode: .repeat
        )
        
        if let animationResource = try? AnimationResource.generate(with: orbit) {
            object.playAnimation(animationResource)
        }
    }
}


class ShootBallBlock : BlockRunner {
    var ball : ModelEntity? = nil
    var color: UIColor?
    var ballSize: Float = 0
    var ballSpeed: Float = 0
    var canCollide: Bool = false
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        guard let msg = message as? [String: Any],
              let eventType = msg["eventType"] as? String else {
            return
        }
        
        switch eventType {
        case "trigger":
            let mesh = MeshResource.generateSphere(radius: ballSize)
            let _material = SimpleMaterial(color: color!, isMetallic: false)
            
            let ballEntity = ModelEntity(mesh: mesh, materials: [_material])
            
            let camX = (Runtime.shared.arView?.cameraTransform.translation)!.x
            let camY = (Runtime.shared.arView?.cameraTransform.translation)!.y
            let camZ = (Runtime.shared.arView?.cameraTransform.translation)!.z - 0.01
            
            let anchorEntity = AnchorEntity(world: SIMD3(x: camX, y: camY, z: camZ))
            
            ballEntity.setScale([Float(Runtime.factor), Float(Runtime.factor), Float(Runtime.factor)],  relativeTo: nil)
            
            ballEntity.setPosition(SIMD3(x: camX, y: camY, z: camZ), relativeTo: nil)
            
            if canCollide == true {
                print("generate collision")
                ballEntity.generateCollisionShapes(recursive: true)
                ballEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic)
                ballEntity.collision?.filter = CollisionFilter(group: Runtime.CollisonGroup.outputGroup, mask: .all)
            }
            
            let results = runtime!.arView!.raycast(from:  runtime!.arView!.center, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let firstResults = results.first {
                print("Entry: Result Position: \(firstResults)")
                
                anchorEntity.addChild(ballEntity)
                self.runtime!.arView?.scene.addAnchor(anchorEntity)
                
                let shootPoint = simd_make_float3(firstResults.worldTransform.columns.3)
                
                let shootBehaviour = simd_make_float3(ballEntity.transform.translation.x + (shootPoint.x), ballEntity.transform.translation.y + (shootPoint.y) + 0.02, ballEntity.transform.translation.z + (shootPoint.z))
                
                anchorEntity.move(to: Transform(scale: simd_make_float3(0.5, 0.5, 0.5),
                                                rotation: anchorEntity.orientation,
                                                translation: shootBehaviour),
                                  relativeTo: anchorEntity, duration: TimeInterval(ballSpeed), timingFunction: .default)
                
                if canCollide == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        ballEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .dynamic)
                    }
                }
            }
        default:
            break
        }
        
    }
    
    
    override func loadBlock(block: Block, runtime: Runtime) {
        
        super.loadBlock(block: block, runtime: runtime)
        
        guard let inputC = block.attributes["color"] as? String, let inputSpeed = block.getInt("speed") as? Int else {
            return
        }
        
        //        canCollide = block.getBool("canCollide", default: false)
        canCollide = true
        
        color = UIColor.color(hex: inputC)
        
        ballSize = Float(block.size.width / 90)
        
        switch inputSpeed {
        case 0:
            ballSpeed = 0.7
        case 1:
            ballSpeed = 0.4
        default:
            ballSpeed = 0.15
        }
        
    }
    
}

class DestroyObjectBlock : AnimationBlockRunner {
    override func handleTrigger(with receivedEntity: ModelEntity?) {
        guard let entity = params[1] as? ModelEntity ?? receivedEntity else {
            print("Entity not found during trigger event.")
            return
        }
        entity.removeFromParent()
        
    }
}

class FixedBlock : AnimationBlockRunner {
    override func handleTrigger(with receivedEntity: ModelEntity?) {
        guard let entity = params[1] as? ModelEntity ?? receivedEntity else {
            print("Entity not found during trigger event.")
            return
        }
        entity.generateCollisionShapes(recursive: true)
        entity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
        entity.collision?.filter = CollisionFilter(group: Runtime.CollisonGroup.usdzGroup, mask: .all)
    }
    
}

class KinematicsBlock : AnimationBlockRunner {
    override func handleTrigger(with receivedEntity: ModelEntity?) {
        guard let entity = params[1] as? ModelEntity ?? receivedEntity else {
            print("Entity not found during trigger event.")
            return
        }
        print("KinematicsBlock::: execute")
        entity.generateCollisionShapes(recursive: true)
        entity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic)
        entity.collision?.filter = CollisionFilter(group: Runtime.CollisonGroup.usdzGroup, mask: .all)
        
        guard let runtime else { return }
        if let move = params[2] as? String, move == "true"{
            print("KinematicsBlock::: move")
            runtime.arView?.installGestures(.translation, for: entity)
        }
        if let rotate = params[3] as? String, rotate == "true"{
            print("KinematicsBlock::: rotate")
            runtime.arView?.installGestures(.rotation, for: entity)
        }
    }
}

class DynamicBlock : AnimationBlockRunner {
    override func handleTrigger(with receivedEntity: ModelEntity?) {
        guard let entity = params[1] as? ModelEntity ?? receivedEntity else {
            print("Entity not found during trigger event.")
            return
        }
        entity.generateCollisionShapes(recursive: true)
        entity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .dynamic)
        entity.collision?.filter = CollisionFilter(group: Runtime.CollisonGroup.usdzGroup, mask: .all)
    }
    
}

///  未轉
class DebugBlock : BlockRunner {
    
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        guard let message = message else {
            return
        }
        print("Debug: \(message)")
        self.runtime?.delegate?.runtime(self.runtime!, debug: "Debug: \(message)")
    }
    
}

class EventSoundBlock : BlockRunner {
    
    //    var audioPlaybackController: AudioPlaybackController?
    var preparedSound: AudioResource?
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        guard let entity = message as? ModelEntity else {
            return
        }
        
        if let audioPlaybackController = entity.prepareAudio(preparedSound!) as?  AudioPlaybackController {
            if !(audioPlaybackController.isPlaying) {
                audioPlaybackController.play()
                
                print("Event Sound played")
            }
            
        } else {
            print("Failed to play Sound entity")
            return
        }
    }
    
    
    override func loadBlock(block: Block, runtime: Runtime) {
        
        super.loadBlock(block: block, runtime: runtime)
        
        guard let soundSelect = block.getString("mp3") else {
            return
        }
        
        let sourceFileName: String = block.getString(soundSelect)!
        print(sourceFileName)
        guard let audioResource =
                try? AudioFileResource.load(named: "\(sourceFileName).mp3",
                                            in: nil,
                                            inputMode: .spatial,
                                            loadingStrategy: .preload,
                                            shouldLoop: false) else {
            print("Failed to load Sound entity")
            return
        }
        
        preparedSound = audioResource
    }
}


class BGMBlock : BlockRunner {
    
    var player: AVAudioPlayer?
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        if message != nil {
            if !(player!.isPlaying) {
                player?.numberOfLoops = -1
                player?.play()
                
                print("BGM Sound played")
            }
            
        }
    }
    
    
    override func loadBlock(block: Block, runtime: Runtime) {
        
        super.loadBlock(block: block, runtime: runtime)
        
        guard let soundSelect = block.getString("mp3") else {
            return
        }
        
        let sourceFileName: String = block.getString(soundSelect)!
        
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playback, mode: .moviePlayback, options: [])
        } catch {
            print("Failed to activate audio session")
        }
        
        if let url = Bundle.main.url(forResource: "\(sourceFileName)", withExtension: "mp3") {
            
            player = try? AVAudioPlayer(contentsOf: url)
        }
        
    }
}


class NextSceneBlock : BlockRunner {
    
    var consumed : Bool = false
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        guard let runtime = self.runtime else {
            return
        }
        
        guard consumed == false else {
            return
        }
        
        self.runtime?.delegate?.runtime(runtime, nextScene: nil)
        consumed = true
    }
}

class GoToSceneBlock : BlockRunner {
    var consumed : Bool = false
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        guard let runtime = self.runtime else {
            return
        }
        
        guard consumed == false else {
            return
        }
        
        self.runtime?.delegate?.runtime(runtime, nextScene: nil)
        consumed = true
    }
}

class TimerOnScreenBlock : BlockRunner {
    var timer: Timer?
    var count: Int = 0
    var isCountDown: Bool = false
    var displayTime: String = ""
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        guard let msg = message as? Int  else {
            return
        }
        print("Adjust Time: \(msg)")
        count += msg
    }
    
    override func loadBlock(block: Block, runtime: Runtime) {
        
        super.loadBlock(block: block, runtime: runtime)
        
        guard let msg = block.getString("value") else {
            return
        }
        
        let time = (msg as NSString).integerValue
        
        isCountDown = false
        if time == 0 {
            timer?.invalidate()
        } else {
            count = count + time
            isCountDown = true
        }
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
        
        let color = block.attributes["color"]!
        
        self.runtime?.delegate?.runtime(self.runtime!, timer: timer, color: color)
    }
    
    @objc func timerCounter() {
        if isCountDown {
            count = count - 1
        } else {
            count = count + 1
        }
        displayTime = timerDiaplayFormat(count)
        
        self.runtime?.delegate?.runtime(self.runtime!, timeParam: displayTime)
    }
    
    func timerDiaplayFormat(_ seconds: Int) -> String {
        var timeString = ""
        
        if seconds <= 0 {
            timeString = "Time Out"
        } else {
            let min = seconds % 3600 / 60
            let sec = (seconds % 3600) % 60
            
            timeString += String(format: "%02d", min)
            timeString += " : "
            timeString += String(format: "%02d", sec)
        }
        return timeString
    }
    
}


class LabelOnScreenBlock : BlockRunner {
    var color: String = ""
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        guard let msg = message as? String else {
            return
        }
        
        self.runtime?.delegate?.runtime(self.runtime!, label: msg, color: color)
    }
    
    override func loadBlock(block: Block, runtime: Runtime) {
        
        super.loadBlock(block: block, runtime: runtime)
        
        guard let input = block.attributes["value"] as? String else {
            return
        }
        
        color = block.attributes["color"]!
        
        self.runtime?.delegate?.runtime(self.runtime!, label: input, color: color)
    }
}

class AddForceBlock : BlockRunner {
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        guard let entity = message as? ModelEntity else {
            return
        }
        
        print(entity)
        //        entity.addForce([-5, 0, 0], relativeTo: entity)
        
        //        for model in entity.children {
        //            print(model)
        //            if let modelEntity = model as? ModelEntity {
        //                print("addforce: \(modelEntity)")
        //                entity.addForce([-5, 0, 0], relativeTo: nil)
        //            }
        //        }
        
    }
    
}

class RealTimeAddOnBlock : BlockRunner {
    
    
    override func execute(message: Any? = nil, from port: Notification.Name? = nil, destPortIndex: Int? = nil) {
        
        guard let entity = message as? ModelEntity else {
            return
        }
        
        let mesh = (entity.model?.mesh)!
        let _material = entity.model?.materials
        let newEntity = ModelEntity(mesh: mesh, materials: _material!)
        
        newEntity.scale = entity.scale
        newEntity.physicsBody = entity.physicsBody
        newEntity.collision = entity.collision
        newEntity.collision?.filter = entity.collision!.filter
        
        let camX = (Runtime.shared.arView?.cameraTransform.translation)!.x
        let camY = (Runtime.shared.arView?.cameraTransform.translation)!.y - 0.05
        let camZ = (Runtime.shared.arView?.cameraTransform.translation)!.z - 0.2
        
        newEntity.setPosition(SIMD3(x: camX, y: camY, z: camZ), relativeTo: nil)
        let anchorEntity = AnchorEntity(world: SIMD3(x: camX, y: camY, z: camZ))
        
        anchorEntity.addChild(newEntity)
        
        Runtime.shared.addEntity(entity: anchorEntity)
    }
    
}


//
//  ModelEntity+Pivot.swift
//  Reality Builder
//
//  Created by Po hin Ma on 9/4/24.
//

import Foundation
import RealityKit


public extension ModelEntity {
    
    enum PivotPosition {
        case top
        case center
        case bottom
    }
    
    func wrapEntityAndSetPivotPosition(to targetPosition: PivotPosition) -> ModelEntity {
        setPivotPosition(to: targetPosition, animated: false)
        
        let entity = ModelEntity()
        entity.position.y = self.visualBounds(relativeTo: nil).center.y
        entity.position.x = self.visualBounds(relativeTo: nil).center.x

        entity.addChild(self)
        
        position.y -= entity.position.y
        position.x -= entity.position.x
        
        /// debug mode
        //        let boundingBox = visualBounds(relativeTo: nil)
        //        let w = (abs(boundingBox.max.x - boundingBox.min.x))
        //        let h = (abs(boundingBox.max.y - boundingBox.min.y))
        //        let d = (abs(boundingBox.max.z - boundingBox.min.z))
        //
        //        let mesh = MeshResource.generateBox(width: w, height: h, depth: d)
        //        let material = SimpleMaterial(color: .black.withAlphaComponent(0.3), roughness: 1.0, isMetallic: false)
        //
        //        let boxEntity = ModelEntity(mesh: mesh, materials: [material])
        //        boxEntity.name = "selectedBox"
        //
        //        self.addChild(boxEntity)
        
        return entity
    }
    
    func setPivotPosition(to targetPosition: PivotPosition, animated: Bool = false) {
        let boundingBox = visualBounds(relativeTo: nil)
        let min = boundingBox.min
        let max = boundingBox.max
        
        let yTranslation: Float
        
        switch targetPosition {
        case .top:
            yTranslation = -max.y
        case .center:
            yTranslation = -(min.y + (max.y - min.y) / 2)
        case .bottom:
            yTranslation = -min.y
        }
        
        let targetPosition = simd_float3(
            x: boundingBox.center.x * -1,
            y: yTranslation,
            z: boundingBox.center.z * -1
        )
        
        guard animated else {
            position = targetPosition
            return
        }
        
        guard isAnchored, parent != nil else {
            print("Warning: to set the Entities pivot position animated make sure it is already anchored and has a parent set.")
            return
        }
        
        var translationTransform = transform
        translationTransform.translation = targetPosition
        move(to: translationTransform, relativeTo: parent, duration: 0.3, timingFunction: .easeOut)
    }
    
    
    
}


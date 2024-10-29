//
//  Enity+Pivot.swift
//  Reality Builder
//
//  Created by Wonderland Team on 25/8/2023.
//

import Foundation
import RealityKit


public extension Entity {
    //0st  scale
    //1nd parent rotation
    //2rd parant translate
    
    
    public var scaleEntity : Entity? {
        return self
    }
    
    public var offsetEntity : Entity? {
        return self.parent
    }
    
    public var rotationEntity : Entity? {
        return self.parent?.parent
    }
    
    public var controlEntity : Entity? {
        return self.parent?.parent?.parent
    }
    
    public var translateEntity : Entity? {
        return self.parent?.parent?.parent?.parent
    }
    
}

public extension Entity {
    
    enum RelativePosition {
        case topLeft, topRight, topFront, topBack
        case bottomLeft, bottomRight, bottomFront, bottomBack
    }


    func calculateRelativePosition(cameraPosition: SIMD3<Float>) -> RelativePosition {
        let relativePosition = cameraPosition - self.transform.translation
        
        let isTop = relativePosition.y > 0
        let absX = abs(relativePosition.x)
        let absZ = abs(relativePosition.z)
        
        if isTop {
            if absX > absZ {
                return relativePosition.x < 0 ? .topRight : .topLeft
            } else {
                return relativePosition.z > 0 ? .topFront : .topBack
            }
        } else {
            if absX > absZ {
                return relativePosition.x < 0 ? .bottomRight : .bottomLeft
            } else {
                return relativePosition.z > 0 ? .bottomFront : .bottomBack
            }
        }
    }
    
    func calculateTranslationAdjustment(cameraPosition: SIMD3<Float>, translate: CGPoint, sensitivity: Float) -> Float {
        let relativePosition = cameraPosition - self.transform.translation
        let absX = abs(relativePosition.x)
        let absZ = abs(relativePosition.z)
        
        let sign: Float
        let translateComponent: Float
        
        if absX > absZ {
            sign = relativePosition.x < 0 ? 1 : -1
            translateComponent = Float(translate.x)
        } else {
            sign = relativePosition.z > 0 ? 1 : -1
            translateComponent = Float(translate.y)
        }
        
        return sign * translateComponent * sensitivity
    }
    
    func calculateTranslationXAdjustment(cameraPosition: SIMD3<Float>, translate: CGPoint, sensitivity: Float) -> Float {
        let relativePosition = cameraPosition - self.transform.translation

        let absX = abs(relativePosition.x)
        let absZ = abs(relativePosition.z)

        let adjustment: Float
        if absX > absZ {
            let isLeft = relativePosition.x > 0
            let sign: Float = isLeft ? 1 : -1
            adjustment = sign * Float(translate.y) * sensitivity
        } else {
            let isFront = relativePosition.z > 0
            let sign: Float = isFront ? 1 : -1
            adjustment = sign * Float(translate.x) * sensitivity
        }
        
        return adjustment
    }

    func calculateRelativeTranslationAdjustment(cameraPosition: SIMD3<Float>, translate: CGPoint, sensitivity: Float) -> [Float] {
        let relativePosition = cameraPosition - self.transform.translation

        let absX = abs(relativePosition.x)
        let absZ = abs(relativePosition.z)

        let adjustmentX: Float
        let adjustmentY: Float = Float(-translate.y) * sensitivity
        let adjustmentZ: Float

        if absX > absZ {
            let isLeft = relativePosition.x < 0
            let signZ: Float = isLeft ? 1.0 : -1.0
            adjustmentX = 0.0
            adjustmentZ = signZ * Float(translate.x) * sensitivity
        } else {
            let isFront = relativePosition.z > 0
            let signX: Float = isFront ? 1.0 : -1.0
            adjustmentX = signX * Float(translate.x) * sensitivity
            adjustmentZ = 0.0
        }

        return [adjustmentX, adjustmentY, adjustmentZ]
    }
    
    enum RelativeDetailPosition {
        case topFrontLeft, topFrontRight, topBackLeft, topBackRight
        case bottomFrontLeft, bottomFrontRight, bottomBackLeft, bottomBackRight
    }

    func calculateRelativeDetailPosition(cameraPosition: SIMD3<Float>) -> RelativeDetailPosition {
        let relativePosition = cameraPosition - self.transform.translation
        let isTop = relativePosition.y > 0
        let isLeft = relativePosition.x > 0
        let isFront = relativePosition.z > 0

        if isTop {
            if isFront {
                return isLeft ? .topFrontLeft : .topFrontRight
            } else {
                return isLeft ? .topBackLeft : .topBackRight
            }
        } else {
            if isFront {
                return isLeft ? .bottomFrontLeft : .bottomFrontRight
            } else {
                return isLeft ? .bottomBackLeft : .bottomBackRight
            }
        }
    }
    
}

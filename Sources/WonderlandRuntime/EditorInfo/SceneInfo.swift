//
//  SceneInfo.swift
//  FBPLand
//
//  Created by Yu Ho Kwok on 10/20/24.
//

import Foundation

struct SceneInfo : Identifiable, Codable {
    var id : String
    var orbitPoint : SIMD3<Float>
    var radius : Float
    var azimuth : Float
    var elevation : Float
    
    static func new (_ id : String) -> SceneInfo {
        let sceneInfo = SceneInfo(id: id,
                                        orbitPoint: [0,0,0],
                                        radius: 16,
                                        azimuth: Float.pi / 2,
                                        elevation: Float.pi / 4)
        return sceneInfo
    }
    
    static func new () -> SceneInfo {
        return SceneInfo.new(UUID().uuidString)
    }
}



//
//  EditorInfo.swift
//  FBPLand
//
//  Created by Yu Ho Kwok on 10/20/24.
//

import Foundation

struct EditorInfo : Identifiable, Codable {
    
    var id : String {
        get {
            return node.id
        }
        set {
            node.id = newValue
            scene.id = newValue
        }
    }
    
    var node : NodeInfo
    var scene : SceneInfo
    
    static func new(_ id : String) -> EditorInfo {
        let info = EditorInfo(node: NodeInfo.new(id), scene: SceneInfo.new(id))
        return info
    }
    
    static func new() -> EditorInfo {
        let info = EditorInfo(node: NodeInfo.new(), scene: SceneInfo.new())
        return info
    }
}

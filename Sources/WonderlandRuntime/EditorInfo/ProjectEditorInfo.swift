//
//  EditorInfo.swift
//  FBPLand
//
//  Created by Yu Ho Kwok on 10/20/24.
//

import Foundation
import SwiftUI

struct ProjectEditorInfo : Codable {
    var project : EditorInfo
    var scenes : [EditorInfo]

    
    /// verify all scenes and project info exit
    /// - Parameter project: project to load
    /// - Parameter clearMissing : clear missing scene
    mutating func verify(_ project : Project, clearMissing : Bool = false) {
        
        if clearMissing == false {
            for scene in project.scenes {
                if scenes.firstIndex(where: { $0.id == scene.id }) == nil {
                    let ei = EditorInfo.new(scene.id)
                    scenes.append(ei)
                }
            }
        } else {
            //remove all dependency
            self.scenes = scenes.filter( {
                editorInfo in
                return project.scenes.contains(where: { $0.id == editorInfo.id})
            })
        }
    }
    
    
    
    static func new() -> ProjectEditorInfo {
        return ProjectEditorInfo(project: EditorInfo.new(),
                                 scenes: [])
    }
    
    static func new(_ project : Project) -> ProjectEditorInfo {
        
        let nodeInfo = NodeInfo.new()
        let sceneInfo = SceneInfo.new()
        
        let projectInfo = EditorInfo(node: nodeInfo, scene: sceneInfo)
        
        var sceneInfos : [EditorInfo] = []
        for ( _ , scene) in project.scenes.enumerated() {
            let nodeInfo = NodeInfo.new(scene.id)
            let sceneInfo = SceneInfo.new(scene.id)
            let editorInfo  = EditorInfo(node: nodeInfo, scene: sceneInfo)
            sceneInfos.append(editorInfo)
        }
        
        let projectEditorInfo = ProjectEditorInfo(project: projectInfo, scenes: sceneInfos)
        return projectEditorInfo
    }
    
}



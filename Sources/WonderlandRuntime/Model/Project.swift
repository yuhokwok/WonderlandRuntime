//
//  Project.swift
//  FBPLand
//
//  Created by Reality Builder Team on 19/2/2022.
//

import SwiftUI
import Combine
import UIKit

struct Project : FlowElement, Codable, Identifiable, Equatable {
    
    var id : String {
        return identifier
    }
    
    static let documentsDirectory = FileManager.default.urls(for: .documentDirectory,  in: .userDomainMask).first!
    
    var isCreated = true
    
    //for scene start
    var startBlock = Block()
    var startConn : Connection?
    
    var arScale : Int? = nil

    /// the scene uuid of thumbnail used by the project
    var thumbnail : String = ""
    
    var scenes : [Scene] = [Scene]()
    
    //wonderland
    var connections = [Connection]()
    //wonderland
    
    var _identifier = UUID().uuidString
    var _timestamp = Date().timeIntervalSinceReferenceDate
    
    var state = ProjectState()
    
    var identifier: String {
        return _identifier
    }
    
    var timestamp: TimeInterval {
        return _timestamp
    }
    
    static func ===(lhs : Project, rhs : Project) -> Bool {
        return  lhs.identifier == rhs.identifier &&
                lhs.scenes == rhs.scenes &&
                lhs.timestamp == rhs.timestamp &&
                lhs.startBlock == rhs.startBlock &&
                lhs.startConn == rhs.startConn
    }
    
    static func ==(lhs : Project, rhs : Project) -> Bool {
        return  lhs.identifier == rhs.identifier &&
                lhs.scenes == rhs.scenes &&
                lhs.timestamp == rhs.timestamp &&
                lhs.startBlock == rhs.startBlock &&
                lhs.startConn == rhs.startConn
    }
    
    mutating func update() {
        self._timestamp = Date().timeIntervalSinceReferenceDate
    }
    
    struct Diff {
        let from : Project
        let to : Project
        
        fileprivate init(from: Project, to: Project){
            self.from = from
            self.to = to
        }
        
        var hasChanges : Bool {
            return !(from === to)
        }
    }
    
    func diffed(with other: Project) -> Diff {
        return Diff(from: self, to: other)
    }
    
    
    /// Copy a project file (convert to json and create a instant)
    /// - Returns: A copied project or nil
    func copy() -> Project? {
        do {
            let data = try JSONEncoder().encode(self)
            let projectCopy  = try JSONDecoder().decode(Project.self, from: data)
            return projectCopy
        } catch _ {
            return nil
        }
    }
    
    func getStartScene() -> Scene {
        guard let startConn = self.startConn else {
            fatalError()
        }
        
        for scene in scenes {
            if scene.inlets[0].identifier == startConn.destinationId {
                return scene
            }
        }
        
        fatalError()
    }
}

extension Project {
    class ProjectState : Codable {
        var params : [String : String] = [:]
        
        var selectedSceneId : String? {
            get {
                return params["selectedSceneId"]
            }
            set {
                params["selectedSceneId"] = newValue
            }
        }
        
        var affectedSceneId : String? {
            get {
                return params["affectedSceneId"]
            }
            set {
                params["affectedSceneId"] = newValue
            }
        }
    }
}

extension Project {
    static func new() -> Project {
        
        print("Project::new")
        var project = Project()
        
        //build a scene
        var scene = Scene.build()
        scene.displayName = "Scene"
        project.scenes.append(scene)
        //project's first selected scene is the first scene
        project.state.selectedSceneId = project.scenes[0].identifier
        project.state.affectedSceneId = project.scenes[0].identifier

        
        
        
        //make the start block
        var block = Block()
        block.type = "start"
        var outPort = Block.Port(type: "scene")
        outPort.datatype = "scene"
        outPort.name = "output"
        outPort.input = false
        block.outlets.append(outPort)
        block.center = Block.Point(x: -200, y: 0, z: 0)
        block.size = Block.Size(width: 54, height: 54, depth: 54)
        
        //make the connection
        var connection = Connection()
        connection.sourceId = block.outlets[0].identifier
        connection.destinationId = scene.inlets[0].identifier
        
        project.startBlock = block
        project.startConn = connection
        
        
        return project
    }
}


class TestJSONObject : Codable {
    var data : String
    init(data : String){
        self.data = data
    }
}

//
//  DocumentHandler.swift
//  Reality Builder
//
//  Created by Wonderland Team on 9/7/2023.
//

import SwiftUI

@MainActor
class DocumentHandler {
    
    var document : WonderlandProject?
    var project : Project
    var editorInfo : ProjectEditorInfo
    
    init?(document : WonderlandProject) {
        self.document = document

        if document.project != nil, document.editorInfo != nil {
            self.project = document.project!
            self.editorInfo = document.editorInfo!
            //get a copy of the project
        } else {
            return nil
        }
    }
    
    init(project : Project) {
        self.project = project
        self.editorInfo = ProjectEditorInfo.new(project)
    }

    func updateBlock(_ block : Block, for sceneId : String ) {
        if let sindex  = project.scenes.firstIndex(where: { $0.id == sceneId }) {
            if let bindex = project.scenes[sindex].blocks.firstIndex(where: { $0.id == block.id }) {
                
                var project = project
                project.scenes[sindex].blocks[bindex] = block
                project.update()
                self.project = project
                
            }
        }
    }
    
    func thumbnail(for identifier : String, type : ImageCache.ThumbnailType) -> UIImage? {
        return document?.thumbnail(for: identifier, type: type)
    }
    
    func saveThumbnail(image : UIImage?, for identifier : String, type : ImageCache.ThumbnailType) -> URL? {
        return document?.saveThumbnail(image: image, for: identifier, type: type)
    }
    
    func getElementContains(port uuid : String) -> (any FlowElement)? {

        if project.startBlock.containsPort(with: uuid) {
            return project.startBlock
        }
        
        for scene in project.scenes {
            if scene.containsPort(with: uuid) {
                return scene
            }
            
            for block in scene.blocks {
                if block.containsPort(with: uuid) {
                    return block
                }
            }
        }
        return nil
    }
    
    func getPort(_ uuid : String) -> Block.Port? {
        
        var port : Block.Port?
        
        port = project.startBlock.port(with: uuid)
        guard port == nil else {
            return port
        }
        
        for scene in project.scenes {
            port = scene.port(with: uuid)
            guard port == nil else { return port }
            
            for block in scene.blocks {
                port = block.port(with: uuid)
                guard port == nil else { return port }
            }
        }
        
        return port
    }
    
    
    func getElement(_ uuid : String) -> (any FlowElement)? {
        var element : (any FlowElement)? = nil
        
        element = project.scenes.first(where: { $0.identifier == uuid })
        guard element == nil else {
            return element
        }

        
        element = project.connections.first(where: { $0.identifier == uuid })
        guard element == nil else {
            return element
        }
        
        for scene in project.scenes {
            element = scene.blocks.first(where: { $0.identifier == uuid })
            guard element == nil else {
                return element
            }
        }

        
        for scene in project.scenes {
            element = scene.connections.first(where: { $0.identifier == uuid })
            guard element == nil else {
                return element
            }
            
        }

        
        if project.startConn?.id == uuid {
            if let startConn = project.startConn {
                return startConn
            }
        }
        
        return element
    }
    
    func duplicateElement(_ element : any FlowElement) {
        if let block = element as? Block {
            var project = project
            let copy = block.duplicate()
            guard let index = project.scenes.firstIndex(where: { $0.blocks.contains(where: {$0.id == block.id})}) else {
                return
            }
            project.scenes[index].blocks.append(copy)
            self.project = project
        } else if let scene = element as? Scene {
            var project = project
            let copy = scene.duplicate()
            
            //copy scene transform
            if let index = editorInfo.scenes.firstIndex(where: { $0.id == scene.id }) {
                var editorInfo = self.editorInfo
                var info = editorInfo.scenes[index]
                info.id = copy.id
                editorInfo.scenes.append(info)
                self.editorInfo = editorInfo
            }
            
            //copy thumbnail
            if let thumbnail = self.thumbnail(for: scene.id, type: .worldmap),
               let url = self.saveThumbnail(image: thumbnail, for: copy.id, type: .worldmap) {
                ImageCache.shared[url] = thumbnail
            }
            
            //copy thumbnail
            if let thumbnail = self.thumbnail(for: scene.id, type: .startup),
               let url = self.saveThumbnail(image: thumbnail, for: copy.id, type: .startup) {
                ImageCache.shared[url] = thumbnail
            }
            
            project.scenes.append(copy)
            self.project = project
        }
    }
    
    func lockElement(_ element : any FlowElement) {
        if let block = element as? Block {
            var project = project
            var block = block
            block.locked = !block.locked
            guard let sindex = project.scenes.firstIndex(where: { $0.blocks.contains(where: {$0.id == block.id})}), let bindex = project.scenes[sindex].blocks.firstIndex(where: { $0.id == block.id}) else {
                return
            }
            project.scenes[sindex].blocks[bindex] = block
            self.project = project
            
        } else if let scene = element as? Scene {
            var project = project
            var scene = scene
            scene.locked = !scene.locked
            guard let index = project.scenes.firstIndex(where: { $0.id == scene.id }) else {
                return
            }
            project.scenes[index] = scene
            self.project = project
        }
    }
    
    func deleteElement(_ uuid : String) {
        if let block = getElement(uuid) as? Block {
            
            var project = self.project
            
            if let index = project.scenes.firstIndex(where: {
                scene in
                return scene.blocks.firstIndex(where: { $0.id == block.id }) != nil
            }) {
            
                //remove all connection
                project.scenes[index].connections.removeAll(where: {
                    conn in
                    return block.inlets.contains(where: { $0.id ==  conn.destinationId} ) || block.outlets.contains(where: { $0.id ==  conn.sourceId})
                })
                
                //remove all blocks
                project.scenes[index].blocks.removeAll(where: { $0.id == block.id })
            }
            
            self.project = project
            
        } else if let scene = getElement(uuid) as? Scene {
            
            //remove all connection
            var project = self.project
            
            if let conn = project.startConn {
                if scene.inlets.contains(where: { $0.id ==  conn.destinationId}) || scene.outlets.contains(where: { $0.id ==  conn.sourceId}) {
                    project.startConn = nil
                }
            }
            
            project.connections.removeAll(where: {
                conn in
                return scene.inlets.contains(where: { $0.id ==  conn.destinationId}) || scene.outlets.contains(where: { $0.id ==  conn.sourceId})
            })
            
            //remove scene
            if let index = project.scenes.firstIndex(where: { $0.id == scene.id } ) {
                _ = project.scenes.remove(at: index)
            }
            
            self.project = project
            
        } else if let connection = getElement(uuid) as? Connection {
            
            
            
            //remove all connection
            var project = self.project
            
            if connection.id == project.startConn?.id {
                project.startConn = nil
            } else {
                project.connections.removeAll(where: { $0.id == connection.id })
                
                for (index, _ ) in project.scenes.enumerated() {
                    project.scenes[index].connections.removeAll(where: { $0.id == connection.id })
                }
            }
            
            self.project = project
        }
    }

    func addScene(with uuid : String) -> Scene {
        var scene = Scene.build()
        scene._identifier = uuid
        scene.displayName = generateSceneDisplayName()
        
        self.project.scenes.append(scene)
        
        let editorInfo = EditorInfo.new(scene._identifier)
        self.editorInfo.scenes.append(editorInfo)
        
        return scene
    }
    
    func addBlock(_ block : Block , into selectedSceneId : String) {
        
        var project = project
        if let index = project.scenes.firstIndex(where: {
            $0.identifier == selectedSceneId
        }) {
            project.scenes[index].blocks.append(block)
        }
        project.update()
        self.project = project
    }
    
    func addWorldConnection(sourceId : String, destinationId : String) {

        let connection = Connection(sourceId: sourceId, destinationId: destinationId)
        
        //replace existing start conn if the output is the outlet of start port
        if let port = project.startBlock.outlets.first {
            if sourceId == port.id {
                self.project.startConn = connection
                return
            }
        }
        
        self.project.connections.append(connection)
    }
    
    func addSceneConnection(sceneId : String , sourceId : String, destinationId : String) {
        
        guard let index = project.scenes.firstIndex(where:  { $0.id == sceneId }) else {
            return
        }
        
        let connection = Connection(sourceId: sourceId, destinationId: destinationId)
        self.project.scenes[index].connections.append(connection)
    }
    
    
    func update(_ element : any FlowElement) {
        if let project = element as? Project {
            
            self.project = project
            
        } else if let block = element as? Block {
           
            var project = self.project
            
            for (sindex, _) in project.scenes.enumerated() {

                if let bindex = project.scenes[sindex].blocks.firstIndex(where: { $0.id == block.id }) {
                    project.scenes[sindex].blocks[bindex] = block
                }
            }

            self.project = project
            
        } else if let scene = element as? Scene {
            
            var project = self.project
            
            //tick off other thumbnail scene
            if scene.isThumbnail == true {
                project.scenes = project.scenes.map({
                    scene in
                    var scene = scene
                    scene.isThumbnail = false
                    return scene
                })
            }
            
            if let index = project.scenes.firstIndex(where: { $0.id == scene.id }) {
                project.scenes[index] = scene
            }
            
            project.thumbnail = scene.isThumbnail ? scene.id : ""
            
            self.project = project
            
        } else if let connection = element as? Connection {
            
        }
    }
    
    private func generateSceneDisplayName() -> String {
        var i = 0
        while(true){
            if i == 0 {
                var hasScene = false
                for scene in project.scenes {
                    if scene.displayName == "Scene" {
                        hasScene = true
                    }
                }
                if hasScene == false {
                    break
                }
            } else  {
                var hasScene = false
                for scene in project.scenes {
                    if scene.displayName == "Scene \(i)" {
                        hasScene = true
                    }
                }
                if hasScene == false {
                    break
                }
            }
            i += 1
        }
        if i == 0 {
            return "Scene"
        } else {
            return "Scene \(i)"
        }
    }
    
}

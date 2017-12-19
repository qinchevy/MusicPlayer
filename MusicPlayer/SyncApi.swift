//
//  SyncApi.swift
//  MusicPlayer
//
//  Created by Zhang Qin, EG-CN-70 on 8/11/17.
//  Copyright © 2017 qinchevy. All rights reserved.
//

import Foundation
import MobileCoreServices

protocol SyncApiProtocol {
    func sync(completionHandler: ([Song]?, String?) -> Void)
}

struct MockSyncApi : SyncApiProtocol {
    func sync(completionHandler: ([Song]?, String?) -> Void) {
        var songs = [Song]()
        for i in 1...7 {
            songs.append(Song(title: "title\(i)", image_uri: "image_uri\(i)", song_uri: "song_uri\(i)"))
        }

        completionHandler(songs, nil);
    }
}

extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
//    var localizedName: String? {
//        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
//    }
}

struct LocalSyncApi : SyncApiProtocol {
    func sync(completionHandler: ([Song]?, String?) -> Void) {
        var songs = [Song]()
        
        if let resPath = Bundle.main.resourceURL?.appendingPathComponent("res") {
            if let songFolderEnumerator = FileManager.default.enumerator(at: resPath, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
                for case let songFolderUrl as URL in songFolderEnumerator {
                    let title = songFolderUrl.lastPathComponent
                    var image: String? = nil
                    var song: String? = nil
                    if let songResEnumberator = FileManager.default.enumerator(at: songFolderUrl, includingPropertiesForKeys: nil) {
                        for case let fileUrl as URL in songResEnumberator {
                            if (UTTypeConformsTo(fileUrl.typeIdentifier! as CFString, kUTTypeImage)) {
                                image = fileUrl.relativePath
                            } else if (UTTypeConformsTo(fileUrl.typeIdentifier! as CFString, kUTTypeAudio)) {
                                song = fileUrl.relativePath
                            } else {
                                continue
                            }
                        }
                        
                        if image != nil && song != nil {
                            songs.append(Song(title: title, image_uri: image!, song_uri: song!))
                        }
                    }
                }
            }
        }
        
        completionHandler(songs, nil);
    }
}

//
//  Clip.swift
//  CrissCross
//
//  Created by Kyle Lee on 9/3/20.
//  Copyright © 2020 Kilo Loco. All rights reserved.
//

import Foundation
import WevModel

struct Clip {
    let id: String
    let username: String
    let caption: String
    let creationDate: Date
    let videoURL: String
    let likeCount: Int64
    let type: VideoTypes
    
    init(tiktok: TikTokVideo) {
        self.id = String(tiktok.id)
        username = UUID().uuidString
        caption = tiktok.title ?? ""
        creationDate = Date()
        videoURL = tiktok.m3u8Url
        likeCount = tiktok.likeCount ?? 0
        self.type = VideoTypes.type(url: tiktok.m3u8Url)
    }
    
    init(item: Item) {
        self.id = String(item.id)
        username = UUID().uuidString
        caption = item.snippet.title
        creationDate = item.snippet.publishedAt
        videoURL = item.contentDetails.upload.videoID
        self.likeCount = 0
        self.type = VideoTypes.youtube
    }
    
    init(watchLater: WatchLaterVideo) {
        username = UUID().uuidString
        creationDate = Date()
        likeCount = watchLater.likeCount ?? 0
        
        if let title = watchLater.youTubeTitle, let id = watchLater.youtubeId {
            caption = title
            videoURL = id
            self.id = id.description
            self.type = VideoTypes.youtube
        } else if let id = watchLater.rumbleId, let title = watchLater.rumbleTitle {
            caption = title
            self.id = id.description
            videoURL = watchLater.rumblem3u8 ?? watchLater.rumbleEmbedUrl ?? ""
            self.type = VideoTypes.rumble
        } else if let id = watchLater.tiktokId, let title = watchLater.tiktokTitle {
            caption = title
            self.id = id.description
            videoURL = watchLater.tiktokem3u8 ?? watchLater.tiktokEmbedUrl ?? ""
            self.type = VideoTypes.tiktok
        } else if let id = watchLater.clipId, let clipURL = watchLater.clipEmbedUrl, let title = watchLater.clipTitle {
            caption = title
            self.id = id.description
            videoURL = clipURL + "&autoplay=true&parent=streamernews.example.com&parent=embed.example.com"
            self.type = VideoTypes.rumble
        } else  {
            debugPrint(watchLater)
            caption = "No Any Videos for it"
            videoURL = ""
            self.type = VideoTypes.youtube
            self.id = watchLater.id.description
        }
    }
}

public enum VideoTypes: Int {
    case youtube = 1
    case twitch = 2
    case rumble = 3
    case tiktok = 4
    
    static func type(url: String) -> VideoTypes {
        if url.contains("rumble") {
            return VideoTypes.rumble
        } else if url.contains("youtube") {
            return VideoTypes.youtube
        } else if url.contains("tiktok") {
            return VideoTypes.tiktok
        } else if url.contains("twitch") {
            return VideoTypes.twitch
        }
        return VideoTypes.tiktok
    }
}

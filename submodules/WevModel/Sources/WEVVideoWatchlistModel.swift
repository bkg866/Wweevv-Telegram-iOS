//
//  WEVChannel.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

//insert WatchLater Model
public struct NewWatchLaterVideo: Codable, Hashable {
  
    public let videoType: Int
    public let userId: Int64
    public let twitchId: Int64?
    public let youtubeId: String?
    public let rumbleId: Int64?
    public let tiktokId: Int64?

    public init(videoType: Int, userId:Int64, twitchId: Int64?, youtubeId: String?, rumbleId: Int64?, tiktokId: Int64?) {
        self.videoType = videoType
        self.userId = userId
        self.twitchId = twitchId
        self.youtubeId = youtubeId
        self.rumbleId = rumbleId
        self.tiktokId = tiktokId
    }
    
    enum CodingKeys: String, CodingKey {
        case videoType = "video_type"
        case userId = "user_id"
        case twitchId = "twitch_id"
        case youtubeId = "youtube_id"
        case rumbleId = "rumble_id"
        case tiktokId = "tiktok_id"
    }
}
// MARK: - Watach Later codeable
public struct WatchLaterVideo: Codable {
    public let id: Int64
    public let userId: Int64
    public let youtubeId: String?
    public let rumbleId: Int64?
    public let tiktokId: Int64?
    public let videoType: Int
    public let twitchId: Int64?
    public let clipId: String?
    public let clipEmbedUrl: String?
    public let clipTitle: String?
    public let clipViewCount: Int64?
    public let clipThumbnailUrl: String?
    public let clipsUsername: String?
    public let blob: String?
    public var youTubeTitle: String?
    public var youTubeDescription: String?
    public var youTubeThumbnail: String?
    public var youTubeViewCounts: Int64?
    public let rumbleTitle: String?
    public let rumbleThumbnailUrl: String?
    public let rumbleEmbedUrl: String?
    public let rumblem3u8: String?
    public let rumbleViewerCount: Int64?
    public let tiktokTitle: String?
    public let tiktokThumbnailUrl: String?
    public let tiktokEmbedUrl: String?
    public let tiktokem3u8: String?
    public let tiktokViewerCount: Int64?
    public let likeCount: Int64?

    enum CodingKeys: String, CodingKey {
        case id
        case blob
        case youTubeTitle
        case youTubeDescription
        case youTubeThumbnail
        case youTubeViewCounts
        case userId = "user_id"
        case youtubeId = "youtube_id"
        case rumbleId = "rumble_id"
        case videoType = "video_type"
        case twitchId = "twitch_id"
        case clipId = "clip_id"
        case clipEmbedUrl = "clip_embed_url"
        case clipTitle = "clip_title"
        case clipViewCount = "clip_view_count"
        case clipThumbnailUrl = "clip_thumbnail_url"
        case clipsUsername = "clips_username"
        case rumbleTitle = "rumble_title"
        case rumbleThumbnailUrl = "rumble_thumbnail_url"
        case rumbleEmbedUrl = "rumble_embed_url"
        case rumblem3u8 = "rumble_m3u8"
        case rumbleViewerCount = "rumble_viewer_count"
        case tiktokId = "tiktok_id"
        case tiktokTitle = "tiktok_title"
        case tiktokThumbnailUrl = "tiktok_thumbnail_url"
        case tiktokEmbedUrl = "tiktok_embed_url"
        case tiktokem3u8 = "tiktok_m3u8"
        case tiktokViewerCount = "tiktok_viewer_count"
        case likeCount = "video_likes"
    }
        
}
let KeyForUserDefaults = "watchLaterList"

public func saveWatchList(_ videowatchList: [WatchLaterVideo]) {
    let data = videowatchList.map { try? JSONEncoder().encode($0) }
    UserDefaults.standard.set(data, forKey: KeyForUserDefaults)
}

public func fetchWatchList() -> [WatchLaterVideo] {
    guard let encodedData = UserDefaults.standard.array(forKey: KeyForUserDefaults) as? [Data] else {
        return []
    }
    return encodedData.map { try! JSONDecoder().decode(WatchLaterVideo.self, from: $0) }
}

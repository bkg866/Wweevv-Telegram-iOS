//
//  WEVChannel.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

// MARK: - Watach Later codeable
public struct SubscribedVideo: Codable {
    public let id: Int64
    public let userId: Int64
    public let youtubeId: String?
    public let rumbleId: Int64?
    public let videoType: Int
    public let twitchId: Int64?
    public let clipId: String?
    public let clipEmbedUrl: String?
    public let clipTitle: String?
    public let clipViewCount: Int64?
    public let clipThumbnailUrl: String?
    public let clipsUsername: String?
    public let blob: String?
    public let youTubeChannelId: String?
    public let youTubeChannelTitle: String?
    public var youTubeTitle: String?
    public var youTubeDescription: String?
    public var youTubeThumbnail: String?
    public var youTubeViewCounts: Int64?
    public let rumbletitle: String?
    public let rumblethumbnailUrl: String?
    public let rumbleEmbedUrl: String?
    public let rumblem3u8: String?
    public let rumbleViewerCount: Int64?

    public enum CodingKeys: String, CodingKey {
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
        case rumbletitle = "rumble_title"
        case rumblethumbnailUrl = "rumble_thumbnail_url"
        case rumbleEmbedUrl = "rumble_embed_url"
        case rumblem3u8 = "rumble_m3u8"
        case rumbleViewerCount = "rumble_viewer_count"
        case youTubeChannelId = "youtubechannelid"
        case youTubeChannelTitle = "youtubechanneltitle"
    }
        
}
public let KeySubsribeForUserDefaults = "subscribeVideo"

public func saveSubscribedVideoList(_ videowatchList: [SubscribedVideo]) {
    let data = videowatchList.map { try? JSONEncoder().encode($0) }
    UserDefaults.standard.set(data, forKey: KeySubsribeForUserDefaults)
}

public func fetchSubscribedList() -> [SubscribedVideo] {
    guard let encodedData = UserDefaults.standard.array(forKey: KeySubsribeForUserDefaults) as? [Data] else {
        return []
    }
    return encodedData.map { try! JSONDecoder().decode(SubscribedVideo.self, from: $0) }
}

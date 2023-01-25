//
//  WEVDiscoverVideo.swift
//  _idx_AccountContext_8C6B681C_ios_min13.0
//
//  Created by Apple on 14/09/22.
//

import Foundation
import UIKit

struct LiveVideos: Codable {
    public let id: String
    public let channelId: String
    public let liveId : String
    public let videoId: String
    public let videoPublishedAt: String?
    public let videoTitle: String
    public let videoDescription: String
    public let videoThumbnailsUrl: String?
    public let createtime: Int?
    public let updatetime: Int?
    public let openflag: Int?
    public let refreshtime: Int?
    public let opentime: String?
    public let viewerCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case channelId = "channel_id"
        case liveId = "live_id"
        case videoId = "video_id"
        case videoPublishedAt = "video_published_at"
        case videoTitle = "video_title"
        case videoDescription = "video_description"
        case videoThumbnailsUrl = "video_thumbnails_url"
        case createtime = "create_time"
        case updatetime = "update_time"
        case openflag = "open_flag"
        case refreshtime = "refresh_time"
        case opentime = "open_time"
        case viewerCount = "viewer_count"
    }
}
public enum channelType: String, CaseIterable {
    case youtube = "YouTube"
    case twitch = "Twitch"
    case facebook = "Facebook"
}
public struct Columns {
    public static let liveVideos = "id,channel_id,live_id,video_id,video_published_at,video_title,video_description,video_thumbnails_url,create_time,update_time,open_flag,refresh_time,open_time,viewer_count"
}

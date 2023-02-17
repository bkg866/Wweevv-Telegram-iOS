//
//  LJConfig.swift
//  Wweevv
//
//  Created by panjinyong on 2020/12/22.
//

import Foundation
import TelegramCore

public struct LJConfig {
        
    
    public static var baseURL: String {
        return ""
    }
        
    //youtube api key
    public struct Youtube {
        public static let apiKey = ""
    }
    
    public static var videoUrl: String {
        return ""
    }

    public static let AppID = ""
    
    /// Twitch授权
    public struct Twitch {
        public static let clientId = ""
        public static let state = ""
        public static let uri = ""
    }
    
    /// YouTube授权
    public struct YouTube {
        static let clientID = ""
        static let redirectURL = "https://wweevv.app/"
    }
        
    public struct SupabaseKeys {
        //Production
        public static let supabaseUrl = ""
        public static let supabaseKey = ""
        
//        //Development
//        public static let supabaseUrl = ""
//        public static let supabaseKey = ""
        
    }
    
    public struct API {
        public static let token = ""
    }
    
    public struct SupabaseColumns {
        public static let clips = "id,user_id,user_name,profile_image_url,clip_id,clip_embed_url,clip_title,clip_view_count,clip_thumbnail_url"
        public static let youtube = "id,blob,channelId,channelTitle,is_live"
        public static let rumble = "id,title,thumbnail_url,embed_url,m3u8,viewer_count"
        public static let tiktok = "id,title,thumbnail_url,embed_url,m3u8,viewer_count"
    }
    
    public struct SupabaseTablesName {
        public static let youtube = "slim_video"
        public static let clips = "clips"
        public static let rumble = "rumble"
        public static let tiktok = "tiktok"
        public static let watchLater = "watch_later"
        public static let videoLikes = "video_likes"
        public static let subscribeVideo = "subscribed_channel"
    }
    
    public struct SupabaseViews {
        public static let watchLater = "watch_later_view"
        public static let subscribeView = "subscribed_channels_view"
        public static let feedLive = "fetch_live_videos"
    }
}

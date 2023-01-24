import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import DeviceAccess
import AccountContext
import AlertUI
import PresentationDataUtils
import TelegramPermissions
import TelegramNotices
import ContactsPeerItem
import SearchUI
import TelegramPermissionsUI
import AppBundle
import StickerResources
import ContextUI
import QrCodeUI
import UndoUI
import ContactsUI
import HandyJSON
import Alamofire
import GalleryUI
import Postbox
import TelegramCore
import InstantPageUI
import MBProgressHUD
import HandyJSON
import ShareController
import CoreLocation
//import Kingfisher
import Realtime
import PostgREST
import LegacyComponents
import SwiftSignalKit
import WevConfig
import WevModel
import SnapKit
import WevNetworkManager
import RESegmentedControl

public class WEVDiscoverRootNode: ASDisplayNode {
    
    let contactListNode: ContactListNode
    var controller:WEVRootViewController!
    
    private let context: AccountContext
    private(set) var searchDisplayController: SearchDisplayController?
    private var offersTableViewNode:ASDisplayNode?
    private var containerLayout: (ContainerViewLayout, CGFloat)?
    //var interactor:WCInteractor?
    var navigationBar: NavigationBar?
    var listNode:ListView!
    var requestDeactivateSearch: (() -> Void)?
    var requestOpenPeerFromSearch: ((ContactListPeer) -> Void)?
    var requestAddContact: ((String) -> Void)?
    var openPeopleNearby: (() -> Void)?
    var openInvite: (() -> Void)?

    var ytVideos: [YoutubeVideo] = []
    var twichVideos: [SlimTwitchVideo] = []
    var rumbleVideos: [RumbleVideo] = []
    var tiktokVideos: [TikTokVideo] = []
    var isLaunchSync: Bool = false
    var arrWatchLater: [WatchLaterVideo] = []
    var arrSubscribedVideos: [SubscribedVideo] = []

    private let supabaseUrl = LJConfig.SupabaseKeys.supabaseUrl
    private let supabaseKey = LJConfig.SupabaseKeys.supabaseKey
    
    /// 根据状态返回该显示的视频
    private var showDataArray: [WEVVideoModel] {
        get {
            switch searchStatus {
            case .searchCompleted:
                return searchDataArray
            case .youtube:
                return []
            case .twitch:
                return []
            case .rumble:
                return []
            case .tiktok:
                return []
            case .filtered:
                return dataArray
            case .searching:
                return []
            }
        }
        set {
            switch searchStatus {
            case .searchCompleted:
                searchDataArray = newValue
            case .youtube:
                break
            case .twitch:
                break
            case .rumble, .tiktok:
                break
            case .filtered:
                dataArray = newValue
            case .searching:
                break
            }
        }
    }
    
    //var ytVideos: [YoutubeVideo] = []
    
    /// bannerView数据列表
    private var bannerDataArray: [WEVVideoModel] = []
    //filter
    private var selectedChannelArray: [WEVChannel] = WEVChannel.allCases
    /// 关键字搜索情况下的请求才需要传，由上个请求得到，第一页传nil
    private var segementChannelAraay: [WEVChannel] = [WEVChannel.youtube]
    private var searchOffset: Int?
    //seatch VC
    private var searchStatus: DiscoverSearchStatus = .youtube
    private var searchWord: String? = nil
    
    private var searchDataArray: [WEVVideoModel] = []
    /// 下一页数据
    ///  /// 数据列表
    private var dataArray: [WEVVideoModel] = []
    private var nextPageToken: String?

    /// 当前位置
    private var currentLocation: CLLocation?
    
    private lazy var emptyView: WEVEmptyHintView = {
        let view = WEVEmptyHintView()
        view.presentationData = self.presentationData
        return view
    }()
    
    /// 是否需要刷新banner
    private var isShouldLoadBannerData: Bool {
        get {
            // 非搜索非筛选
            (selectedChannelArray.isEmpty || selectedChannelArray.count == WEVChannel.allCases.count)
            && (searchStatus == .youtube || searchStatus == .twitch)
        }
    }
    
    /// 是否应该显示banner
    private var isShowBannerView: Bool {
        get {
            isShouldLoadBannerData && !bannerDataArray.isEmpty
        }
    }
    
    var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private var mServicesTableView:ASDisplayNode?
    
    
    //segment control
    private lazy var segmentControl: RESegmentedControl = {
        let segmentControl = RESegmentedControl()
        
        var segmentItems: [SegmentModel] = DiscoverRootItems.readOptions()
        
        var preset = MaterialPreset(backgroundColor: self.presentationData.theme.rootController.tabBar.backgroundColor, tintColor: self.presentationData.theme.rootController.tabBar.selectedIconColor, normalColor: self.presentationData.theme.list.itemPrimaryTextColor)

        preset.segmentItemAxis = .horizontal
        preset.segmentItemStyle.spacing = 7
        preset.spaceBetweenImageAndLabel = 0.5
        preset.segmentItemStyle.separator = DefaultSeparator()
        preset.segmentSelectedItemStyle.size = SelectedSegmentSize.height(3, position: .bottom)
        segmentControl.configure(segmentItems: segmentItems, preset: preset)
        segmentControl.delegate = self
        segmentControl.canCollectionViewIndexChange = true
        return segmentControl
    }()
    
    lazy var segmentHeight: CGFloat = 44
    lazy var navigationBarHeight: CGFloat = 50

    
    private lazy var searchView: WEVDiscoverSearchView = {
        let view = WEVDiscoverSearchView()
        view.presentationData = self.presentationData
        view.recordArray = WEVSearchRecordManager.recordArray
        view.didSelected = {[weak self] word in
            guard let self = self else {return}
            self.search(word: word)
            self.refreshSearchStatusView()
            self.searchBar.text = word
        }
        view.deleteRecord = {[weak self] record in
            guard let self = self else {return}
            WEVSearchRecordManager.remove(record: record)
            self.searchView.recordArray.removeAll(where: {$0 == record})
        }
        return view
    }()
    
    
    
    private lazy var searchBar: WEVDiscoverSearchBar = {
        let view = WEVDiscoverSearchBar()
        view.presentationData = self.presentationData
        view.filterAction = {[weak self] in
            guard let self = self else {return}
            /*let vc = WEVDiscoverFilterViewController(allChannel: WEVChannel.allCases, selectedArray: self.selectedChannelArray)
            vc.selectedArray = self.selectedChannelArray
            vc.didSelected = {[weak self] channelArray in
                guard let self = self else {return}
                if channelArray.count == WEVChannel.allCases.count {
                    self.searchStatus = .youtube
                } else {
                    self.searchStatus = .filtered
                }
                self.showDataArray = []
                DispatchQueue.main.async {
                    self.collectionView!.reloadData()
                    self.updateCollectionViewContraint(isShowing: channelArray.count == WEVChannel.allCases.count ? true : false)
                    if self.searchStatus != .filtered {
                        self.refreshEmptyView()
                    }
                }
                //fetch filter data
                self.selectedChannelArray = channelArray
                self.scrollViewLoadData(isHeadRefesh: true)
            }*/
            let push: (ViewController) -> Void = { [weak self] c in
                guard let strongSelf = self, let navigationController = strongSelf.controller?.navigationController as? NavigationController else {
                    return
                }
                var updatedControllers = navigationController.viewControllers
                for controller in navigationController.viewControllers.reversed() {
                    if controller !== strongSelf && !(controller is TabBarController) {
                        updatedControllers.removeLast()
                    } else {
                        break
                    }
                }
                updatedControllers.append(c)
                navigationController.setViewControllers(updatedControllers, animated: true)
            }
            push(WEVSubscribeController(context: self.context))
        }
        
        view.cancelAction = {[weak self] in
            guard let self = self else {return}
            self.searchStatus = self.segmentControl.selectedSegmentIndex == 0 ? .youtube : .twitch
            self.searchWord = nil
            self.searchBar.text = ""
            self.searchDataArray.removeAll()
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
            self.refreshSearchStatusView()
            self.refreshEmptyView()
        }
        
        view.didBeginEditing = {[weak self] in
            guard let self = self else {return}
            self.searchView.isShowRecordList = self.searchBar.text.isEmpty
            self.searchStatus = .searching
            self.refreshSearchStatusView()
        }
        
        view.searchAction = {[weak self] word in
            guard let self = self else {return}
            self.search(word: word)
            self.refreshSearchStatusView()
        }
        
        view.textDidChange = {[weak self] word in
            guard let self = self else {return}
            self.searchLiveName(word: word)
            self.searchView.isShowRecordList = word.isEmpty
        }
        
        return view
    }()
    
    
    
    func fetchYoutubeVideos(completion: @escaping (_ success: Bool) -> Void) {
        self.controller.database?.from(LJConfig.SupabaseTablesName.youtube)
            .select(columns:LJConfig.SupabaseColumns.youtube)
            .eq(column: "is_live", value: true)
            .execute() { result in
            switch result {
            case let .success(response):
                do {
                    let videos = try response.decoded(to: [SlimVideo].self)
                    let decoder = JSONDecoder()
                    self.ytVideos.removeAll()
                    for  vid in videos{
                        do {
                            if let data = vid.blob.data(using: .utf8) {
                                var video:YoutubeVideo = try decoder.decode(YoutubeVideo.self, from:data )
                                print("video:",video)
                                video.channelId = vid.channelId
                                video.channelTitle = vid.channelTitle
                                self.ytVideos.append(video)
                            }
                        }catch (let ex){
                            print(ex)
                        }
                    }
                } catch (let error){
                    /*DispatchQueue.main.async {
                        MBProgressHUD.lj.showHint(error.localizedDescription)
                    }*/
                    debugPrint(error.localizedDescription)
                }
            case let .failure(error):
                /*DispatchQueue.main.async {
                    MBProgressHUD.lj.showHint(error.localizedDescription)
                }*/
                debugPrint(error.localizedDescription)
            }
            completion(true)
        }
    }
    
    func fetchTwithVideo(completion: @escaping (_ success: Bool) -> Void) {
        self.controller.database?.from(LJConfig.SupabaseTablesName.clips).select(columns:LJConfig.SupabaseColumns.clips).execute() { result in
            switch result {
            case let .success(response):
                var errMsg = ""
                do {
                    print("🌻 :",response)
                    let videos = try response.decoded(to: [SlimTwitchVideo].self)
                    self.twichVideos.removeAll()
                    self.twichVideos.append(contentsOf: videos)
                    
                } catch let DecodingError.dataCorrupted(context) {
                    errMsg = "Decoding Error: " + context.debugDescription + "\n\( context.codingPath)"
                } catch let DecodingError.keyNotFound(key, context) {
                    errMsg = "Key '\(key)' not found:" + context.debugDescription + "\n\( context.codingPath)"
                } catch let DecodingError.valueNotFound(value, context) {
                    errMsg = "Value '\(value)' not found:" + context.debugDescription + "\n\( context.codingPath)"
                } catch let DecodingError.typeMismatch(type, context)  {
                    errMsg = "Type '\(type)' mismatch:" + context.debugDescription + "\n\( context.codingPath)"
                } catch {
                    errMsg = "error: " + error.localizedDescription
                }
                if !errMsg.isEmpty {
                    print("<<<<<<<<",errMsg,">>>>>>")
                }
            case let .failure(error):
                /*DispatchQueue.main.async {
                    MBProgressHUD.lj.showHint(error.localizedDescription)
                }*/
                debugPrint(error.localizedDescription)
            }
            completion(true)
        }
    }
    
    func fetchRumbleVideo(completion: @escaping (_ success: Bool) -> Void) {
        self.controller.database?.from(LJConfig.SupabaseTablesName.rumble).select(columns:LJConfig.SupabaseColumns.rumble).execute() { result in
            switch result {
            case let .success(response):
                var errMsg = ""
                do {
                    print("🌻 :",response)
                    let videos = try response.decoded(to: [RumbleVideo].self)
                    self.rumbleVideos.removeAll()
                    self.rumbleVideos.append(contentsOf: videos)
                    
                } catch let DecodingError.dataCorrupted(context) {
                    errMsg = "Decoding Error: " + context.debugDescription + "\n\( context.codingPath)"
                        
                } catch let DecodingError.keyNotFound(key, context) {
                    errMsg = "Key '\(key)' not found:" + context.debugDescription + "\n\( context.codingPath)"
                } catch let DecodingError.valueNotFound(value, context) {
                    errMsg = "Value '\(value)' not found:" + context.debugDescription + "\n\( context.codingPath)"

                } catch let DecodingError.typeMismatch(type, context)  {
                    errMsg = "Type '\(type)' mismatch:" + context.debugDescription + "\n\( context.codingPath)"
                } catch {
                    errMsg = "error: " + error.localizedDescription
                }
                if !errMsg.isEmpty {
                    print("<<<<<<<<",errMsg,">>>>>>")
                }
            case let .failure(error):
                /*DispatchQueue.main.async {
                    MBProgressHUD.lj.showHint(error.localizedDescription)
                }*/
                debugPrint(error.localizedDescription)
            }
            completion(true)
        }
    }
    
    func fetchTiktokVideo(completion: @escaping (_ success: Bool) -> Void) {
        self.controller.database?.from(LJConfig.SupabaseTablesName.tiktok).select(columns:LJConfig.SupabaseColumns.tiktok).execute() { result in
            switch result {
            case let .success(response):
                var errMsg = ""
                do {
                    print("🌻 :",response)
                    let videos = try response.decoded(to: [TikTokVideo].self)
                    self.tiktokVideos.removeAll()
                    self.tiktokVideos.append(contentsOf: videos)
                    
                } catch let DecodingError.dataCorrupted(context) {
                    errMsg = "Decoding Error: " + context.debugDescription + "\n\( context.codingPath)"
                        
                } catch let DecodingError.keyNotFound(key, context) {
                    errMsg = "Key '\(key)' not found:" + context.debugDescription + "\n\( context.codingPath)"
                } catch let DecodingError.valueNotFound(value, context) {
                    errMsg = "Value '\(value)' not found:" + context.debugDescription + "\n\( context.codingPath)"

                } catch let DecodingError.typeMismatch(type, context)  {
                    errMsg = "Type '\(type)' mismatch:" + context.debugDescription + "\n\( context.codingPath)"
                } catch {
                    errMsg = "error: " + error.localizedDescription
                }
                if !errMsg.isEmpty {
                    print("<<<<<<<<",errMsg,">>>>>>")
                }
            case let .failure(error):
                /*DispatchQueue.main.async {
                    MBProgressHUD.lj.showHint(error.localizedDescription)
                }*/
                debugPrint(error.localizedDescription)
            }
            completion(true)
        }
    }
    
    private func search(word: String) {
        searchBar.textField.resignFirstResponder()
        searchWord = word
        searchStatus = .searchCompleted
        searchLiveVideos(isHeadRefesh: true)
        WEVSearchRecordManager.add(record: word)
        searchView.recordArray = WEVSearchRecordManager.recordArray
    }
    
    
    /// 刷新空白提示页面
    func refreshEmptyView() {
        if !isShowBannerView {
            switch searchStatus {
            case .youtube:
                if ytVideos.isEmpty && isLaunchSync {
                    let model = Model(title: "No videos live", image: "empty_discover_list", desc: "There are no videos live at\nthis moment!")
                    emptyView.model = model
                    self.showEmptyView()
                } else {
                    emptyView.removeFromSuperview()
                }
            case .twitch:
                if twichVideos.isEmpty && isLaunchSync {
                    let model = Model(title: "No videos live", image: "empty_discover_list", desc: "There are no videos live at\nthis moment!")
                    emptyView.model = model
                    self.showEmptyView()
                } else {
                    emptyView.removeFromSuperview()
                }
            case .rumble:
                if rumbleVideos.isEmpty && isLaunchSync {
                    let model = Model(title: "No videos live", image: "empty_discover_list", desc: "There are no videos live at\nthis moment!")
                    emptyView.model = model
                    self.showEmptyView()
                } else {
                    emptyView.removeFromSuperview()
                }
            case .tiktok:
                if tiktokVideos.isEmpty && isLaunchSync {
                    let model = Model(title: "No videos live", image: "empty_discover_list", desc: "There are no videos live at\nthis moment!")
                    emptyView.model = model
                    self.showEmptyView()
                } else {
                    emptyView.removeFromSuperview()
                }
            case .searchCompleted, .filtered:
                if showDataArray.isEmpty {
                    let model = Model(title: "Oops!... no results found", image: "empty_discover_search", desc: "There are no results matching your search. Check your spelling or try another keyword.")
                    emptyView.model = model
                    self.showEmptyView()
                } else {
                    emptyView.removeFromSuperview()
                }
            default:
                emptyView.removeFromSuperview()
                break
            }
        }else {
            emptyView.removeFromSuperview()
        }
    }
    
    func showEmptyView() {
        emptyView.removeFromSuperview()
        collectionView!.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview()
            make.size.equalToSuperview()
        }
    }
    
    /// 刷新搜索状态相关视图
    private func refreshSearchStatusView(isInitial: Bool = false) {
        
        /// 是否显示搜索界面
        func updateListView(_ isShowSearchView: Bool) {
            collectionView!.isHidden = isShowSearchView
            searchView.isHidden = !isShowSearchView
        }
        
        switch searchStatus {
        case .searching:
            updateListView(true)
            searchBar.style = .searching
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                if !isInitial {
                    self.updateCollectionViewContraint(isShowing: false)
                }
            }
        case .youtube:
            updateListView(false)
            searchBar.style = .normal
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                if !isInitial && self.selectedChannelArray.count == WEVChannel.allCases.count {
                    self.updateCollectionViewContraint(isShowing: true)
                }
            }
        case .twitch:
            updateListView(false)
            searchBar.style = .normal
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                if !isInitial && self.selectedChannelArray.count == WEVChannel.allCases.count {
                    self.updateCollectionViewContraint(isShowing: true)
                }
            }
        case .searchCompleted:
            updateListView(false)
            searchBar.style = .searchCompleted
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                /*if !isInitial {
                    self.updateCollectionViewContraint(isShowing: false)
                }*/
            }
        default:
            break
        }
    }
    
    func updateCollectionViewContraint(isShowing: Bool) {
        if isShowing {
            self.collectionView?.snp.updateConstraints({ make in
                make.top.equalToSuperview().offset(navigationBarHeight + segmentHeight)
            })
        } else {
            self.collectionView?.snp.updateConstraints({ make in
                make.top.equalToSuperview().offset(navigationBarHeight)
            })
        }
        UIView.animate(withDuration: 0.25) {
            self.controller.view.layoutIfNeeded()
        }
    }
    
    init(context: AccountContext, sortOrder: Signal<ContactsSortOrder, NoError>, present: @escaping (ViewController, Any?) -> Void, controller: WEVRootViewController) {
        self.context = context
        
        self.controller = controller
        //BlockchainTest().decode()
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        
        let options = [ContactListAdditionalOption(title: presentationData.strings.Contacts_AddPeopleNearby, icon: .generic(UIImage(bundleImageName: "Contact List/PeopleNearbyIcon")!), action: {
            //addNearbyImpl?()
        }), ContactListAdditionalOption(title: presentationData.strings.Contacts_InviteFriends, icon: .generic(UIImage(bundleImageName: "Contact List/AddMemberIcon")!), action: {
            //inviteImpl?()
        })]
        
        let presentation = sortOrder |> map { sortOrder -> ContactListPresentation in
            switch sortOrder {
            case .presence:
                return .orderedByPresence(options: options)
            case .natural:
                return .natural(options: options, includeChatList: false)
            }
        }
        
        
        self.contactListNode = ContactListNode.init(context: context, presentation: presentation)
        
        super.init()

        self.setViewBlock({
            return UITracingLayerView()
        })
        
        self.backgroundColor = presentationData.theme.chatList.backgroundColor
    }
    
    private func getUserPeer(engine: TelegramEngine, peerId: EnginePeer.Id) -> Signal<EnginePeer?, NoError> {
        return engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
        |> mapToSignal { peer -> Signal<EnginePeer?, NoError> in
            guard let peer = peer else {
                return .single(nil)
            }
            if case let .secretChat(secretChat) = peer {
                return engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: secretChat.regularPeerId))
            } else {
                return .single(peer)
            }
        }
    }
    
    func twitchRealTimeSync() {
        let rt = RealtimeClient(endPoint: "\(supabaseUrl)/realtime/v1", params: ["apikey": supabaseKey])
        
        rt.onOpen {
            print("Socket opened.")
            let allUsersUpdateChanges =  rt.channel(.table(LJConfig.SupabaseTablesName.clips, schema: "public"))

            allUsersUpdateChanges.on(.all) { message in
            }
            allUsersUpdateChanges.subscribe()
        }
        
        rt.onError{error in
            print("Socket error: ", error.localizedDescription)
        }
        
        rt.onClose {
            print("Socket closed")
        }
        
        rt.onMessage{message in
            switch message.event {
            case .insert:
                if let record = message.payload["record"] as? [String:Any] {
                    do {
                        if let collectionView = self.collectionView, self.searchStatus == .twitch {
                            DispatchQueue.main.async {
                                UIView.performWithoutAnimation {
                                    collectionView.performBatchUpdates {
                                        do {
                                            let video = try DictionaryDecoder().decode(SlimTwitchVideo.self, from: record)
                                            self.twichVideos.insert(video, at: 0)
                                            let indertIndexPaths = IndexPath(item: 0, section: 0)
                                            collectionView.insertItems(at: [indertIndexPaths])
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                    } completion: { isFinished in
                                        self.refreshEmptyView()
                                    }
                                }
                            }
                        } else {
                            let video = try DictionaryDecoder().decode(SlimTwitchVideo.self, from: record)
                            self.twichVideos.insert(video, at: 0)
                        }
                    }catch {
                    }
                }
            case .update:
                if let oldRecord = message.payload["old_record"] as? [String:Any], let id = oldRecord["id"] as? Int64, let record = message.payload["record"] as? [String:Any] {
                    do {
                        if let collectionView = self.collectionView, self.searchStatus == .twitch {
                            DispatchQueue.main.async {
                                UIView.performWithoutAnimation {
                                    collectionView.performBatchUpdates {
                                        do {
                                            if let index = self.twichVideos.firstIndex(where: {$0.id == id}) {
                                                let video = try DictionaryDecoder().decode(SlimTwitchVideo.self, from: record)
                                                self.twichVideos[index] = video
                                                let indertIndexPaths = IndexPath(item: index, section: 0)
                                                collectionView.reloadItems(at: [indertIndexPaths])
                                            }
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                    } completion: { isFinished in
                                    }
                                }
                            }
                        } else if let index = self.twichVideos.firstIndex(where: {$0.id == id}) {
                            let video = try DictionaryDecoder().decode(SlimTwitchVideo.self, from: record)
                            self.twichVideos[index] = video
                        }
                    }catch {
                    }
                }
            case .delete:
                if let record = message.payload["old_record"] as? [String:Any], let id = record["id"] as? Int64 {
                    if let collectionView = self.collectionView, self.searchStatus == .twitch {
                        UIView.performWithoutAnimation {
                            DispatchQueue.main.async {
                                collectionView.performBatchUpdates {
                                    if let index = self.twichVideos.firstIndex(where: {$0.id == id}) {
                                        self.twichVideos.remove(at: index)
                                        let deleteIndexPaths = IndexPath(item: index, section: 0)
                                        collectionView.deleteItems(at: [deleteIndexPaths])
                                    }
                                } completion: { isFinished in
                                    self.refreshEmptyView()
                                }
                            }
                        }
                    } else if let index = self.twichVideos.firstIndex(where: {$0.id == id}) {
                        self.twichVideos.remove(at: index)
                    }
                }
                break
            default:
                break
            }
         }
        rt.connect()
    }
    
    func watchLaterRealTimeSync() {
        let rt = RealtimeClient(endPoint: "\(supabaseUrl)/realtime/v1", params: ["apikey": supabaseKey])
        
        rt.onOpen {
            print("Socket opened.")
            let allUsersUpdateChanges =  rt.channel(.table(LJConfig.SupabaseTablesName.watchLater, schema: "public"))

            allUsersUpdateChanges.on(.all) { message in
            }
            allUsersUpdateChanges.subscribe()
        }
        
        rt.onError{error in
            print("Socket error: ", error.localizedDescription)
        }
        
        rt.onClose {
            print("Socket closed")
        }
        
        rt.onMessage{message in
            switch message.event {
                case .insert, .update, .delete:
                    self.doWatchLaterFetch()
                default:
                    break
            }
         }
        rt.connect()
    }
    
    func subscribeRealTimeSync() {
        let rt = RealtimeClient(endPoint: "\(supabaseUrl)/realtime/v1", params: ["apikey": supabaseKey])
        
        rt.onOpen {
            print("Socket opened.")
            let allUsersUpdateChanges =  rt.channel(.table(LJConfig.SupabaseTablesName.subscribeVideo, schema: "public"))

            allUsersUpdateChanges.on(.all) { message in
            }
            allUsersUpdateChanges.subscribe()
        }
        
        rt.onError{error in
            print("Socket error: ", error.localizedDescription)
        }
        
        rt.onClose {
            print("Socket closed")
        }
        
        rt.onMessage{message in
            switch message.event {
                case .insert, .update, .delete:
                    self.doFetchSubscribeVideo()
                default:
                    break
            }
         }
        rt.connect()
    }
    
    func rumbleRealTimeSync() {
        let rt = RealtimeClient(endPoint: "\(supabaseUrl)/realtime/v1", params: ["apikey": supabaseKey])
        
        rt.onOpen {
            print("Socket opened.")
            let allUsersUpdateChanges =  rt.channel(.table(LJConfig.SupabaseTablesName.rumble, schema: "public"))

            allUsersUpdateChanges.on(.all) { message in
            }
            allUsersUpdateChanges.subscribe()
        }
        
        rt.onError{error in
            print("Socket error: ", error.localizedDescription)
        }
        
        rt.onClose {
            print("Socket closed")
        }
        
        rt.onMessage{message in
            switch message.event {
            case .insert:
                if let record = message.payload["record"] as? [String:Any] {
                    do {
                        if let collectionView = self.collectionView, self.searchStatus == .rumble {
                            DispatchQueue.main.async {
                                UIView.performWithoutAnimation {
                                    collectionView.performBatchUpdates {
                                        do {
                                            let video = try DictionaryDecoder().decode(RumbleVideo.self, from: record)
                                            self.rumbleVideos.insert(video, at: 0)
                                            let indertIndexPaths = IndexPath(item: 0, section: 0)
                                            collectionView.insertItems(at: [indertIndexPaths])
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                    } completion: { isFinished in
                                        self.refreshEmptyView()
                                    }
                                }
                            }
                        } else {
                            let video = try DictionaryDecoder().decode(RumbleVideo.self, from: record)
                            self.rumbleVideos.insert(video, at: 0)
                        }
                    }catch {
                    }
                }
            case .update:
                if let oldRecord = message.payload["old_record"] as? [String:Any], let id = oldRecord["id"] as? Int64, let record = message.payload["record"] as? [String:Any] {
                    do {
                        if let collectionView = self.collectionView, self.searchStatus == .rumble {
                            DispatchQueue.main.async {
                                UIView.performWithoutAnimation {
                                    collectionView.performBatchUpdates {
                                        do {
                                            if let index = self.rumbleVideos.firstIndex(where: {$0.id == id}) {
                                                let video = try DictionaryDecoder().decode(RumbleVideo.self, from: record)
                                                self.rumbleVideos[index] = video
                                                let indertIndexPaths = IndexPath(item: index, section: 0)
                                                collectionView.reloadItems(at: [indertIndexPaths])
                                            }
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                    } completion: { isFinished in
                                    }
                                }
                            }
                        } else if let index = self.rumbleVideos.firstIndex(where: {$0.id == id}) {
                            let video = try DictionaryDecoder().decode(RumbleVideo.self, from: record)
                            self.rumbleVideos[index] = video
                        }
                    }catch {
                    }
                }
            case .delete:
                if let record = message.payload["old_record"] as? [String:Any], let id = record["id"] as? Int64 {
                    if let collectionView = self.collectionView, self.searchStatus == .rumble {
                        UIView.performWithoutAnimation {
                            DispatchQueue.main.async {
                                collectionView.performBatchUpdates {
                                    if let index = self.rumbleVideos.firstIndex(where: {$0.id == id}) {
                                        self.rumbleVideos.remove(at: index)
                                        let deleteIndexPaths = IndexPath(item: index, section: 0)
                                        collectionView.deleteItems(at: [deleteIndexPaths])
                                    }
                                } completion: { isFinished in
                                    self.refreshEmptyView()
                                }
                            }
                        }
                    } else if let index = self.rumbleVideos.firstIndex(where: {$0.id == id}) {
                        self.rumbleVideos.remove(at: index)
                    }
                }
                break
            default:
                break
            }
         }
        rt.connect()
    }
    
    func youTubeRealTimeSync() {
        let rt = RealtimeClient(endPoint: "\(supabaseUrl)/realtime/v1", params: ["apikey": supabaseKey])
        
        rt.onOpen {
            print("Socket opened.")
            let allUsersUpdateChanges =  rt.channel(.table(LJConfig.SupabaseTablesName.youtube, schema: "public"))

            allUsersUpdateChanges.on(.all) { message in
            }
            allUsersUpdateChanges.subscribe()
        }
        
        rt.onError{error in
            print("Socket error: ", error.localizedDescription)
        }
        
        rt.onClose {
            print("Socket closed")
        }
        
        rt.onMessage{message in
            switch message.event {
            case .insert:
                /*if let record = message.payload["record"] as? [String:Any] {
                    do {
                        if let collectionView = self.collectionView, self.searchStatus == .youtube {
                            DispatchQueue.main.async {
                                UIView.performWithoutAnimation {
                                    collectionView.performBatchUpdates {
                                        do {
                                            let video = try DictionaryDecoder().decode(SlimVideo.self, from: record)
                                            if let data = video.blob.data(using: .utf8) {
                                                var ytVideo = try JSONDecoder().decode(YoutubeVideo.self, from:data)
                                                ytVideo.channelId = video.channelId
                                                ytVideo.channelTitle = video.channelTitle
                                                self.ytVideos.insert(ytVideo, at: 0)
                                                let indertIndexPaths = IndexPath(item: 0, section: 0)
                                                collectionView.insertItems(at: [indertIndexPaths])
                                            }
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                    } completion: { isFinished in
                                        self.refreshEmptyView()
                                    }
                                }
                            }
                        } else {
                            let video = try DictionaryDecoder().decode(SlimVideo.self, from: record)
                            if let data = video.blob.data(using: .utf8) {
                                var ytVideo = try JSONDecoder().decode(YoutubeVideo.self, from:data )
                                ytVideo.channelId = video.channelId
                                ytVideo.channelTitle = video.channelTitle
                                self.ytVideos.insert(ytVideo, at: 0)
                            }
                        }
                    }catch {
                    }
                }*/
                break
            case .update:
                if let oldRecord = message.payload["old_record"] as? [String:Any], let id = oldRecord["id"] as? String, let record = message.payload["record"] as? [String:Any] {
                    do {
                        if let collectionView = self.collectionView, self.searchStatus == .youtube {
                            DispatchQueue.main.async {
                                UIView.performWithoutAnimation {
                                    collectionView.performBatchUpdates {
                                        do {
                                            if let index = self.ytVideos.firstIndex(where: {$0.id == id}) {
                                                let video = try DictionaryDecoder().decode(SlimVideo.self, from: record)
                                                if let data = video.blob.data(using: .utf8) {
                                                    var ytVideo = try JSONDecoder().decode(YoutubeVideo.self, from:data)
                                                    ytVideo.channelId = video.channelId
                                                    ytVideo.channelTitle = video.channelTitle
                                                    ytVideo.isLive = video.is_live
                                                    self.ytVideos[index] = ytVideo
                                                    let indertIndexPaths = IndexPath(item: index, section: 0)
                                                    collectionView.reloadItems(at: [indertIndexPaths])
                                                }
                                            }
                                        } catch {
                                            print(error.localizedDescription)
                                        }
                                    } completion: { isFinished in
                                    }
                                }
                            }
                        } else if let index = self.ytVideos.firstIndex(where: {$0.id == id}) {
                            let video = try DictionaryDecoder().decode(SlimVideo.self, from: record)
                            if let data = video.blob.data(using: .utf8) {
                                var ytVideo = try JSONDecoder().decode(YoutubeVideo.self, from:data)
                                ytVideo.channelId = video.channelId
                                ytVideo.channelTitle = video.channelTitle
                                ytVideo.isLive = video.is_live
                                self.ytVideos[index] = ytVideo
                            }
                        }
                    }catch {
                    }
                }
            case .delete:
                /*if let record = message.payload["old_record"] as? [String:Any], let id = record["id"] as? String {
                    if let collectionView = self.collectionView, self.searchStatus == .youtube {
                        UIView.performWithoutAnimation {
                            DispatchQueue.main.async {
                                collectionView.performBatchUpdates {
                                    if let index = self.ytVideos.firstIndex(where: {$0.id == id}) {
                                        self.ytVideos.remove(at: index)
                                        let deleteIndexPaths = IndexPath(item: index, section: 0)
                                        collectionView.deleteItems(at: [deleteIndexPaths])
                                    }
                                } completion: { isFinished in
                                    self.refreshEmptyView()
                                }
                            }
                        }
                    } else if let index = self.ytVideos.firstIndex(where: {$0.id == id}) {
                        self.ytVideos.remove(at: index)
                    }
                }*/
                break
            default:
                break
            }
         }
        rt.connect()
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    var collectionView: UICollectionView?
    
    func updateThemeAndStrings() {
        self.backgroundColor = self.presentationData.theme.chatList.backgroundColor
        self.searchDisplayController?.updatePresentationData(self.presentationData)
        self.emptyView.presentationData = self.presentationData
        self.searchBar.presentationData = self.presentationData
        self.searchView.presentationData = self.presentationData
        if let collectionView = collectionView {
            collectionView.backgroundColor = presentationData.theme.chatList.backgroundColor
        }
        segmentControl.preset = MaterialPreset(backgroundColor: self.presentationData.theme.rootController.tabBar.backgroundColor, tintColor: self.presentationData.theme.rootController.tabBar.selectedIconColor, normalColor: self.presentationData.theme.list.itemPrimaryTextColor)
    }
    
    func scrollToTop() {
        if let contentNode = self.searchDisplayController?.contentNode as? ContactsSearchContainerNode {
            contentNode.scrollToTop()
        } else {
            self.contactListNode.scrollToTop()
        }
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, actualNavigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        print("containerLayoutUpdated \(layout)")
        self.containerLayout = (layout, navigationBarHeight)
        
        var insets = layout.insets(options: [.input])
        insets.top += navigationBarHeight
        
        var headerInsets = layout.insets(options: [.input])
        headerInsets.top += actualNavigationBarHeight
        
        if let searchDisplayController = self.searchDisplayController {
            searchDisplayController.containerLayoutUpdated(layout, navigationBarHeight: navigationBarHeight, transition: transition)
        }
        
        self.contactListNode.containerLayoutUpdated(ContainerViewLayout(size: layout.size, metrics: layout.metrics, deviceMetrics: layout.deviceMetrics, intrinsicInsets: insets, safeInsets: layout.safeInsets, additionalInsets: layout.additionalInsets, statusBarHeight: layout.statusBarHeight, inputHeight: layout.inputHeight, inputHeightIsInteractivellyChanging: layout.inputHeightIsInteractivellyChanging, inVoiceOver: layout.inVoiceOver), headerInsets: headerInsets, transition: transition)
        
        if(mServicesTableView?.supernode == nil) { // load only once
            
            // 1. convert to ASDisplayNode
            let segmentControlNode = ASDisplayNode { () -> UIView in
                return self.segmentControl
            }
            print(navigationBarHeight)
            print(actualNavigationBarHeight)
            print(insets.top)
            print(headerInsets.top)
            
            print(layout.deviceMetrics.hasTopNotch)
            // 2. add node to view hierachy > then snapkit
            self.addSubnode(segmentControlNode)
            self.navigationBarHeight = navigationBarHeight //+ (layout.deviceMetrics.hasTopNotch ? 0 : (layout.statusBarHeight ?? 0))
            segmentControl.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(self.navigationBarHeight)
                make.height.equalTo(segmentHeight)
            }
            
           // 1. convert to ASDisplayNode
            mServicesTableView = ASDisplayNode { () -> UIView in
                return self.getCollectionView(frame: .zero)
            }
            // 2. add node to view hierachy > then snapkit
            self.addSubnode(mServicesTableView!)
            collectionView?.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(self.navigationBarHeight + segmentHeight)
                make.bottom.equalToSuperview().offset(-layout.intrinsicInsets.bottom)
            }
            
            //Filter view to select channel
            let searchBarNode =  ASDisplayNode { () -> UIView in
                return self.searchBar
            }
            self.addSubnode(searchBarNode)
            searchBar.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(layout.statusBarHeight ?? 0)
                make.height.equalTo(44)
            }
            
            //seachbar result view
            let searchNode =  ASDisplayNode { () -> UIView in
                return self.searchView
            }
            self.addSubnode(searchNode)
            
            searchView.snp.makeConstraints { (make) in
                make.edges.equalTo(collectionView!)
            }
            
            if isLaunchSync {
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    self.refreshEmptyView()
                }
            }
        }
        
//        if let selectedItem = segmentItems.first {
//            searchStatus = selectedItem.searchStatus
//            DispatchQueue.main.async {
//                self.collectionView?.reloadData()
//                self.refreshEmptyView()
//            }
//        }
        
        refreshSearchStatusView(isInitial: true)
        
    }
    
    func getCollectionView(frame:CGRect) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        let width = (LJScreen.width - 1 * 2 - 1) / 2
        layout.itemSize = CGSize(width: width, height: 97 * width / 186)
        let view = UICollectionView.init(frame: frame, collectionViewLayout: layout)
        view.backgroundColor = presentationData.theme.chatList.backgroundColor
        view.delegate = self
        view.dataSource = self
        view.register(WEVDiscoverCollectionViewCell.self, forCellWithReuseIdentifier: "WEVDiscoverCollectionViewCell")
        view.register(WEVDiscoverBannerView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "WEVDiscoverBannerView")
        view.contentInsetAdjustmentBehavior = .never
        //Code for pull to refresh
        view.lj.addMJReshreHeader(delegate: self)
        //view.lj.addMJReshreFooter(delegate: self)
        self.collectionView = view
        return view
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension WEVDiscoverRootNode: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        .init(top: 1, left: 1, bottom: 1, right: 1)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        1
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        1
    }
    
    public  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if isShowBannerView {
            return CGSize.init(width: LJScreen.width, height: 210 * LJScreen.width / 375)
        }else {
            return CGSize.zero
        }
    }
}

extension WEVDiscoverRootNode: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch searchStatus {
        case .youtube:
            return ytVideos.count
        case .twitch:
            return twichVideos.count
        case .rumble:
            return rumbleVideos.count
        case .tiktok:
            return tiktokVideos.count
        default:
            return showDataArray.count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WEVDiscoverCollectionViewCell", for: indexPath) as! WEVDiscoverCollectionViewCell
        switch searchStatus {
        case .youtube:
            cell.ytModel = ytVideos[indexPath.row]
        case .twitch:
            cell.twitchModel = twichVideos[indexPath.row]
        case .rumble:
            cell.rumbleModel = rumbleVideos[indexPath.row]
        case .tiktok:
            cell.tiktokModel = tiktokVideos[indexPath.row]
        default:
            cell.model = showDataArray[indexPath.row]
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let bannerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "WEVDiscoverBannerView", for: indexPath) as? WEVDiscoverBannerView else {
            return UICollectionReusableView()
        }
        bannerView.dataArray = bannerDataArray
        bannerView.didSelected = {[weak self] (video) in
            guard let self = self else {return}
            self.playVideo(video: video)
            print("self:",self)
        }
        
        return bannerView
    }
    private var navigationController: NavigationController? {
        if let navigationController = self.controller.navigationController as? NavigationController {
            return navigationController
        }
        //        else if case let .inline(navigationController) = self.presentationInterfaceState.mode {
        //            return navigationController
        //        } else if case let .overlay(navigationController) = self.presentationInterfaceState.mode {
        //            return navigationController
        //        } else {
        //            return nil
        //        }
        return nil
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var image: UIImage? = nil
        if let cell = collectionView.cellForItem(at: indexPath) as? WEVDiscoverCollectionViewCell {
            image = cell.imageView.image
        }
        switch searchStatus {
        case .youtube:
            self.playClips(video: ytVideos[indexPath.row], image: image)
        case .twitch:
            self.playClips(clip: twichVideos[indexPath.row], image: image)
        case .rumble:
            self.playClips(rumbleVideo: rumbleVideos[indexPath.row], image: image)
        case .tiktok:
            self.playClips(titktokVideo: tiktokVideos[indexPath.row], image: image)
        default:
            self.playVideo(video: showDataArray[indexPath.row])
        }
    }
    
    func playVideo(video: WEVVideoModel) {
        if let url = video.videlLiveUrl {
            let size = CGSize(width:1280,height:720)
            
            let updatedContent: TelegramMediaWebpageContent = .Loaded(TelegramMediaWebpageLoadedContent(url: url, displayUrl: url, hash: 0, type: "video", websiteName: "YouTube", title:video.videoTitle, text: video.videoDescription, embedUrl: url, embedType: "iframe", embedSize: PixelDimensions(size), duration: nil, author: nil, image: nil, file: nil, attributes: [], instantPage: nil))
            let webPage = TelegramMediaWebpage(webpageId: MediaId(namespace: 0, id: 1), content: updatedContent)
            
            //let messageAttribute = MessageAttribute
            //JP HACK
            // attributes = ishdidden / type = Url / reactions
            let message = Message(stableId: 1, stableVersion: 1, id: MessageId(peerId: PeerId(0), namespace: Namespaces.Message.Local, id: 0), globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, threadId: nil, timestamp: 0, flags: [], tags: [], globalTags: [], localTags: [], forwardInfo: nil, author: nil, text: "", attributes: [], media: [webPage], peers: SimpleDictionary(), associatedMessages: SimpleDictionary(), associatedMessageIds: [], associatedMedia: [:], associatedThreadInfo: nil)
            
            
            // Source is message?
            let source = GalleryControllerItemSource.standaloneMessage(message)
            let context = self.controller.accountContext()
            let galleryVC = GalleryController(context: context, source: source , invertItemOrder: false, streamSingleVideo: true, fromPlayingVideo: false, landscape: false, timecode: 0, playbackRate: 1, synchronousLoad: false, replaceRootController: { _, ready in
                print("👹  we're in replaceRootController....")
                self.controller?.navigationController?.popToRootViewController(animated: true)
            }, baseNavigationController: navigationController, actionInteraction: nil)
            //galleryVC.isChannel = true
            galleryVC.temporaryDoNotWaitForReady = false
            
            //let nv = NavigationController(/
            //self.controller.push(galleryVC)
            
            self.controller.present(galleryVC, in: .window(.root))
        }
    }
    
    func playClips(video: YoutubeVideo? = nil, clip: SlimTwitchVideo? = nil, rumbleVideo: RumbleVideo? = nil, titktokVideo: TikTokVideo? = nil, image: UIImage? = nil) {
        
        var videoTitle = ""
        var videoDescription = ""
        let websiteName = "YouTube"
        var url = ""
        var isLikedVideo = false
        var isSubscribed = false
        var isShowSubscribe = false
        var isShowLike = true
        if let ytVideo = video {
            videoTitle = ytVideo.title
            videoDescription = ytVideo.description ?? ""
            url = "https://www.youtube.com/watch?v=" + ytVideo.id
            isLikedVideo = arrWatchLater.firstIndex(where: {$0.youtubeId == ytVideo.id}) == nil ? false : true
            isSubscribed = arrSubscribedVideos.firstIndex(where: {$0.youTubeChannelId == ytVideo.channelId})  == nil ? false : true
            isShowSubscribe = true
        } else if let twitch = clip {
            url = twitch.clipEmbedUrl + "&autoplay=true&parent=streamernews.example.com&parent=embed.example.com"
            videoTitle = twitch.clipTitle
            isLikedVideo = arrWatchLater.firstIndex(where: {$0.twitchId == twitch.id}) == nil ? false : true
            //let thumbURL = URL(string: twitch.clipThumbnailUrl)
            //KingfisherManager.shared.cache.retrieveImage(forKey: twitch.clipThumbnailUrl) { result in
                //print(result)
            //}
        } else if let rumble = rumbleVideo {
            url = rumble.embedUrl
            videoTitle = rumble.title
            isLikedVideo = arrWatchLater.firstIndex(where: {$0.rumbleId == rumble.id}) == nil ? false : true
        } else if let tiktok = titktokVideo {
            url = tiktok.m3u8Url
            videoTitle = tiktok.title ?? ""
            isLikedVideo = arrWatchLater.firstIndex(where: {$0.tiktokId == tiktok.id}) == nil ? false : true
            isShowLike = false
        } else {
            return
        }
        
        /*let thumbnail = UIImage(named: "channel_youtube")
        var previewRepresentations: [TelegramMediaImageRepresentation] = []
        var finalDimensions = CGSize(width:1280,height:720)
        finalDimensions = TGFitSize(finalDimensions,CGSize(width:1280,height:720))*/
        
        let size = CGSize(width:1280,height:720)
        let updatedContent: TelegramMediaWebpageContent = .Loaded(TelegramMediaWebpageLoadedContent(url: url, displayUrl: url, hash: 0, type: nil, websiteName: websiteName, title: videoTitle, text: videoDescription, embedUrl: url, embedType: "iframe", embedSize: PixelDimensions(size), duration: nil, author: nil, image: nil, file: nil, attributes: [], instantPage: nil))

        
        /*if let thumbnail = thumbnail {
            let resource = LocalFileMediaResource(fileId: Int64.random(in: Int64.min ... Int64.max))
            let thumbnailSize = finalDimensions.aspectFitted(CGSize(width:1280,height:720))
            let thumbnailImage = TGScaleImageToPixelSize(thumbnail, thumbnailSize)!
            if let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.4) {
                //account.postbox.mediaBox.storeResourceData(resource.id, data: thumbnailData)
                previewRepresentations.append(TelegramMediaImageRepresentation(dimensions: PixelDimensions(thumbnailSize), resource: resource, progressiveSizes: [], immediateThumbnailData: nil))
            //}
            //let data = thumbnail.pngData()
            let media = TelegramMediaImage(imageId: MediaId(namespace: 0, id: 0), representations: previewRepresentations, immediateThumbnailData: thumbnailData, reference: nil, partialReference: nil, flags: [])
            
            updatedContent = .Loaded(TelegramMediaWebpageLoadedContent(url: url, displayUrl: url, hash: 0, type: nil, websiteName: websiteName, title: videoTitle, text: videoDescription, embedUrl: url, embedType: "iframe", embedSize: PixelDimensions(size), duration: nil, author: nil, image: media, file: nil, attributes: [], instantPage: nil))
            }

        }*/
        
       // let media = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: Int64.random(in: Int64.min ... Int64.max)), partialReference: nil, resource: resource, previewRepresentations: previewRepresentations, videoThumbnails: [], immediateThumbnailData: nil, mimeType: "video/mp4", size: nil, attributes: fileAttributes)



        let webPage = TelegramMediaWebpage(webpageId: MediaId(namespace: Namespaces.Media.CloudWebpage, id: 0), content: updatedContent)
        
        //let messageAttribute = MessageAttribute
        //JP HACK
        // attributes = ishdidden / type = Url / reactions
        let message = Message(stableId: 1, stableVersion: 1, id: MessageId(peerId: PeerId(0), namespace: 0, id: 0), globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, threadId: nil, timestamp: 0, flags: [MessageFlags(rawValue: 64)], tags: [], globalTags: [], localTags: [], forwardInfo: nil, author: nil, text: url, attributes: [], media: [webPage], peers: SimpleDictionary(), associatedMessages: SimpleDictionary(), associatedMessageIds: [], associatedMedia: [:], associatedThreadInfo: nil)
        
        
        // Source is message?
        let source = GalleryControllerItemSource.standaloneMessage(message)
        let context = self.controller.accountContext()
        let galleryVC = GalleryController(context: context, source: source , invertItemOrder: false, streamSingleVideo: true, fromPlayingVideo: false, landscape: false, timecode: nil, playbackRate: 1, synchronousLoad: false, isShowLike: isShowLike, isVideoLiked: isLikedVideo, isShowSubcribe: isShowSubscribe, isVideoSubscribed: isSubscribed, isShowShare: isShowSubscribe, replaceRootController: { controller, ready in
            print("👹  we're in replaceRootController....")
            if let baseNavigationController = self.navigationController {
                baseNavigationController.replaceTopController(controller, animated: false, ready: ready)
            }
        }, baseNavigationController: navigationController, actionInteraction: nil)
        galleryVC.temporaryDoNotWaitForReady = true
        galleryVC.temporaryDoNotWaitForReady = true
        galleryVC.useSimpleAnimation = true

        
        galleryVC.onLike = {
            self.likeVideo(video: video, clip: clip, rumbleVideo: rumbleVideo, tiktokVideo: titktokVideo, isLiked: true)
        }
        
        galleryVC.onDislike = {
            self.likeVideo(video: video, clip: clip, rumbleVideo: rumbleVideo, tiktokVideo: titktokVideo, isLiked: false)
        }
        
        galleryVC.onSubscribe = {
            debugPrint("Pressed subscribe")
            self.subscribeYTVideo(video: video, isSubscribe: true)
        }
        
        galleryVC.onDesubscribe = {
            debugPrint("Pressed onDesubscribe")
            self.subscribeYTVideo(video: video, isSubscribe: false)
        }
        
        galleryVC.onShare = {
            debugPrint("On share pressed....")
            guard let ytVideo = video else {
                return
            }
            self.shareButtonAction(video: ytVideo)
        }
        self.controller.present(galleryVC, in: .window(.root))
    }
    
    private func shareButtonAction(video: YoutubeVideo) {
        let code = "https://wweevv.app/video?videoId=\(video.id)&type=1"
        let controller = ShareController(context: self.context, subject: .url(code), preferredAction: .default)
        self.controller.present(controller, in: .window(.root), blockInteraction: true)
    }
    
    func likeVideo(video: YoutubeVideo? = nil, clip: SlimTwitchVideo? = nil, rumbleVideo: RumbleVideo? = nil, tiktokVideo: TikTokVideo? = nil, isLiked: Bool) {
        if let ytVideo = video {
            if isLiked {
                let video = NewWatchLaterVideo(videoType: 1, userId: context.account.peerId.id._internalGetInt64Value(), twitchId: nil, youtubeId: ytVideo.id, rumbleId: nil, tiktokId: nil)
                self.doPerformAddWatchLater(videoObj: video)
            } else if let index = arrWatchLater.firstIndex(where: {$0.youtubeId == ytVideo.id}) {
                self.doPerformRemoveWatchLater(id: arrWatchLater[index].id)
            }
        } else if let twitch = clip {
            if isLiked {
                let video = NewWatchLaterVideo(videoType: 2, userId: context.account.peerId.id._internalGetInt64Value(), twitchId: twitch.id, youtubeId: nil, rumbleId: nil, tiktokId: nil)
                self.doPerformAddWatchLater(videoObj: video)
            } else if let index = arrWatchLater.firstIndex(where: {$0.twitchId == twitch.id}) {
                self.doPerformRemoveWatchLater(id: arrWatchLater[index].id)
            }
        } else if let rumble = rumbleVideo {
            if isLiked {
                let video = NewWatchLaterVideo(videoType: 3, userId: context.account.peerId.id._internalGetInt64Value(), twitchId: nil, youtubeId: nil, rumbleId: rumble.id, tiktokId: nil)
                self.doPerformAddWatchLater(videoObj: video)
            } else if let index = arrWatchLater.firstIndex(where: {$0.rumbleId == rumble.id}) {
                self.doPerformRemoveWatchLater(id: arrWatchLater[index].id)
            }
        } else if let tiktok = tiktokVideo {
            if isLiked {
                let video = NewWatchLaterVideo(videoType: 4, userId: context.account.peerId.id._internalGetInt64Value(), twitchId: nil, youtubeId: nil, rumbleId: nil, tiktokId: tiktok.id)
                self.doPerformAddWatchLater(videoObj: video)
            } else if let index = arrWatchLater.firstIndex(where: {$0.tiktokId == tiktok.id}) {
                self.doPerformRemoveWatchLater(id: arrWatchLater[index].id)
            }
        }
    }
    
    func subscribeYTVideo(video: YoutubeVideo? = nil, isSubscribe: Bool) {
        if let ytVideo = video {
            if isSubscribe {
                let video = NewWatchLaterVideo(videoType: 1, userId: context.account.peerId.id._internalGetInt64Value(), twitchId: nil, youtubeId: ytVideo.id, rumbleId: nil, tiktokId: nil)
                self.doPerformSubscribeVideo(videoObj: video)
            } else if let index = arrSubscribedVideos.firstIndex(where: {$0.youtubeId == ytVideo.id}) {
                self.doPerformRemoveSubscribe(id: arrSubscribedVideos[index].id)
            }
        } /*else if let twitch = clip {
            if isLiked {
                let video = NewWatchLaterVideo(videoType: 2, userId: context.account.peerId.id._internalGetInt64Value(), twitchId: twitch.id, youtubeId: nil, rumbleId: nil)
                self.doPerformAddWatchLater(videoObj: video)
            } else if let index = arrSubscribedVideos.firstIndex(where: {$0.twitchId == twitch.id}) {
                self.doPerformRemoveWatchLater(id: arrSubscribedVideos[index].id)
            }
        } else if let rumble = rumbleVideo {
            if isLiked {
                let video = NewWatchLaterVideo(videoType: 3, userId: context.account.peerId.id._internalGetInt64Value(), twitchId: nil, youtubeId: nil, rumbleId: rumble.id)
                self.doPerformAddWatchLater(videoObj: video)
            } else if let index = arrSubscribedVideos.firstIndex(where: {$0.rumbleId == rumble.id}) {
                self.doPerformRemoveWatchLater(id: arrSubscribedVideos[index].id)
            }
        }*/
    }
    
    func doPerformSubscribeVideo(videoObj: NewWatchLaterVideo) {
        Task {
            await performSubscribeVideo(videoObj: videoObj)
        }
    }
    
    func performSubscribeVideo(videoObj: NewWatchLaterVideo) async {
        guard let client = await self.controller.database else {
            return
        }
        do {
            let insertedVideo = try await client.from(LJConfig.SupabaseTablesName.subscribeVideo)
                .insert(
                    values: videoObj,
                    returning: .representation
                )
                .execute()
                .json()
            print(insertedVideo)
        } catch  {
            print(error.localizedDescription)
        }
    }
    
    func doPerformAddWatchLater(videoObj: NewWatchLaterVideo) {
        Task {
            await performAddWatchLater(videoObj: videoObj)
        }
    }
    
    func performAddWatchLater(videoObj: NewWatchLaterVideo) async {
        guard let client = await self.controller.database else {
            return
        }
        do {
            let insertedVideo = try await client.from(LJConfig.SupabaseTablesName.watchLater)
                .insert(
                    values: videoObj,
                    returning: .representation
                )
                .execute()
                .json()
            print(insertedVideo)
        } catch  {
            print(error.localizedDescription)
        }
    }
    
    func doPerformRemoveWatchLater(id: Int64) {
        Task {
            await performRemoveWatchLater(id: id)
        }
    }
    
    func performRemoveWatchLater(id: Int64) async {
        guard let client = await self.controller.database else {
            return
        }
        do {
            try await client.from(LJConfig.SupabaseTablesName.watchLater).delete().eq(column: "id", value: "\(id)").execute()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func doPerformRemoveSubscribe(id: Int64) {
        Task {
            await performRemoveSubscribe(id: id)
        }
    }
    
    func performRemoveSubscribe(id: Int64) async {
        guard let client = await self.controller.database else {
            return
        }
        do {
            try await client.from(LJConfig.SupabaseTablesName.subscribeVideo).delete().eq(column: "id", value: "\(id)").execute()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func doWatchLaterFetch() {
        Task {
            await fetchWatchLater()
        }
    }

    
    func fetchWatchLater() async {
        guard let client = await self.controller.database else {
            return
        }
        
        var errMsg = ""
        // Get twitch videos
        do {
             let watchLater = try await client
                .from(LJConfig.SupabaseViews.watchLater)
            .select()
            .eq(column: "user_id", value: "\(context.account.peerId.id._internalGetInt64Value())")
            .execute()
            .decoded(to: [WatchLaterVideo].self)
            
            //assign watch later data to array
            self.arrWatchLater = watchLater
            //get watch later object
            for index in 0..<arrWatchLater.count where arrWatchLater[index].videoType == 1 {
                if let blob = arrWatchLater[index].blob, let data = blob.data(using: .utf8) {
                    do {
                        let video:YoutubeVideo = try JSONDecoder().decode(YoutubeVideo.self, from:data)
                        print("video:",video)
                        arrWatchLater[index].youTubeTitle = video.title
                        arrWatchLater[index].youTubeDescription = video.description
                        arrWatchLater[index].youTubeThumbnail = video.thumbnails[0]?.url ?? ""
                        arrWatchLater[index].youTubeViewCounts = video.viewCount
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            saveWatchList(arrWatchLater)
        } catch let DecodingError.dataCorrupted(context) {
            errMsg = "Decoding Error: " + context.debugDescription + "\n\( context.codingPath)"
                
        } catch let DecodingError.keyNotFound(key, context) {
            errMsg = "Key '\(key)' not found:" + context.debugDescription + "\n\( context.codingPath)"
        } catch let DecodingError.valueNotFound(value, context) {
            errMsg = "Value '\(value)' not found:" + context.debugDescription + "\n\( context.codingPath)"

        } catch let DecodingError.typeMismatch(type, context)  {
            errMsg = "Type '\(type)' mismatch:" + context.debugDescription + "\n\( context.codingPath)"
        } catch {
            errMsg = "error: " + error.localizedDescription
        }
        if !errMsg.isEmpty {
            print("<<<<<<<<",errMsg,">>>>>>")
        }
    }
    
    func doFetchSubscribeVideo() {
        Task {
            await fetchSubscribedVideos()
        }
    }

    
    func fetchSubscribedVideos() async {
        guard let client = await self.controller.database else {
            return
        }
        
        var errMsg = ""
        // Get twitch videos
        do {
             let subscribedVideo = try await client
                .from(LJConfig.SupabaseViews.subscribeView)
            .select()
            .eq(column: "user_id", value: "\(context.account.peerId.id._internalGetInt64Value())")
            .execute()
            .decoded(to: [SubscribedVideo].self)
            
            //assign watch later data to array
            self.arrSubscribedVideos = subscribedVideo
            //get watch later object
            for index in 0..<arrSubscribedVideos.count where arrSubscribedVideos[index].videoType == 1 {
                if let blob = arrSubscribedVideos[index].blob, let data = blob.data(using: .utf8) {
                    do {
                        let video:YoutubeVideo = try JSONDecoder().decode(YoutubeVideo.self, from:data)
                        print("video:",video)
                        arrSubscribedVideos[index].youTubeTitle = video.title
                        arrSubscribedVideos[index].youTubeDescription = video.description
                        arrSubscribedVideos[index].youTubeThumbnail = video.thumbnails[0]?.url ?? ""
                        arrSubscribedVideos[index].youTubeViewCounts = video.viewCount
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            saveSubscribedVideoList(self.arrSubscribedVideos)
        } catch let DecodingError.dataCorrupted(context) {
            errMsg = "Decoding Error: " + context.debugDescription + "\n\( context.codingPath)"
        } catch let DecodingError.keyNotFound(key, context) {
            errMsg = "Key '\(key)' not found:" + context.debugDescription + "\n\( context.codingPath)"
        } catch let DecodingError.valueNotFound(value, context) {
            errMsg = "Value '\(value)' not found:" + context.debugDescription + "\n\( context.codingPath)"
        } catch let DecodingError.typeMismatch(type, context)  {
            errMsg = "Type '\(type)' mismatch:" + context.debugDescription + "\n\( context.codingPath)"
        } catch {
            errMsg = "error: " + error.localizedDescription
        }
        if !errMsg.isEmpty {
            print("<<<<<<<<",errMsg,">>>>>>")
        }
    }
}
extension WEVDiscoverRootNode {
    
    func fetchTelegramUserInfo() {
        let _ = (getUserPeer(engine: self.context.engine, peerId: self.context.account.peerId)
        |> deliverOnMainQueue).start(next: { [weak self] peer in
            guard let strongSelf = self else {
                return
            }
            
            if case let .user(peer) = peer {
                print(peer.lastName ?? "")
                strongSelf.doSaveUserData(peer: peer)
            }
        })
    }
    
    func doSaveUserData(peer: TelegramUser) {
        Task {
            await saveUserData(peer: peer)
        }
    }
    
    func saveUserData(peer: TelegramUser) async {
        //check client is not a nil
        guard let client = await self.controller.database else {
            return
        }
        do {
            
            let cuurentUser = try await client
               .from("wev_telegram_users")
           .select()
           .eq(column: "user_id", value: "\(peer.id.id._internalGetInt64Value())")
           .execute()
           .decoded(to: [WevUser].self)

            //if referralcode is there use existing otherwise create a new code
            let refralCode = cuurentUser.first?.referralcode ?? referalCode.generateRefferalCode()
            
            let _ = try await client.from("wev_telegram_users")
                .upsert(
                    values: WevUser(userId: peer.id.id._internalGetInt64Value(), firstname: peer.firstName, lastname: peer.lastName, username: peer.username, phone: peer.phone, referralcode: refralCode),
                    onConflict: "user_id",
                    returning: .representation,
                    ignoreDuplicates: false
                )
                .execute()
                .json()
        } catch {
            print(error.localizedDescription)
        }
    }
}
extension WEVDiscoverRootNode {
    func doGetYoutubeVideoById(videoId: String, type: Int) {
        Task {
            await getYoutubeVideoById(videoId: videoId, type: type)
        }
    }
    
    func getYoutubeVideoById(videoId: String, type: Int) async {
        do {
            let youtubeVideo = try await self.controller.database?
                .from("slim_video")
                .select()
                .eq(column: "id", value: videoId)
                .execute()
                .decoded(to: [SlimVideo].self).first
            
            if let ytVideo = youtubeVideo, let data = ytVideo.blob.data(using: .utf8) {
                do {
                    let video:YoutubeVideo = try JSONDecoder().decode(YoutubeVideo.self, from:data)
                    print("video:",video)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: { [weak self] in
                        guard let strongSelf = self else {
                            return
                        }
                        strongSelf.playClips(video: video)
                    })
                } catch {
                    DispatchQueue.main.async {
                        self.showTootlipPopUp(message: error.localizedDescription)
                    }                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    //self.showTootlipPopUp(message: "Video is deleted")
                    strongSelf.playUniversalLinkedVideos(videoId: videoId, type: type)
                })
            }
        } catch {
            DispatchQueue.main.async {
                self.showTootlipPopUp(message: error.localizedDescription)
            }
        }
    }
    
    func showTootlipPopUp(message: String) {
        let toolTipcontroller = UndoOverlayController(presentationData: self.presentationData, content: .info(title: nil, text: message), elevatedLayout: false, animateInAsReplacement: false, action: { action in
            if action == .info {
                print("Action pressed")
                return true
            }
            return false
        })
        self.controller?.present(toolTipcontroller, in: .window(.root), with: nil)
    }
    
    func playUniversalLinkedVideos(videoId: String, type:Int) {
    
        let websiteName = "YouTube"
        let url = "https://www.youtube.com/watch?v=" + videoId
        
        let size = CGSize(width:1280,height:720)
        let updatedContent: TelegramMediaWebpageContent = .Loaded(TelegramMediaWebpageLoadedContent(url: url, displayUrl: url, hash: 0, type: nil, websiteName: websiteName, title: nil, text: nil, embedUrl: url, embedType: "iframe", embedSize: PixelDimensions(size), duration: nil, author: nil, image: nil, file: nil, attributes: [], instantPage: nil))

        let webPage = TelegramMediaWebpage(webpageId: MediaId(namespace: Namespaces.Media.CloudWebpage, id: 0), content: updatedContent)
        
        //let messageAttribute = MessageAttribute
        //JP HACK
        // attributes = ishdidden / type = Url / reactions
        let message = Message(stableId: 1, stableVersion: 1, id: MessageId(peerId: PeerId(0), namespace: 0, id: 0), globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, threadId: nil, timestamp: 0, flags: [MessageFlags(rawValue: 64)], tags: [], globalTags: [], localTags: [], forwardInfo: nil, author: nil, text: url, attributes: [], media: [webPage], peers: SimpleDictionary(), associatedMessages: SimpleDictionary(), associatedMessageIds: [], associatedMedia: [:], associatedThreadInfo: nil)
        
        
        // Source is message?
        let source = GalleryControllerItemSource.standaloneMessage(message)
        let context = self.controller.accountContext()
        let galleryVC = GalleryController(context: context, source: source , invertItemOrder: false, streamSingleVideo: true, fromPlayingVideo: false, landscape: false, timecode: nil, playbackRate: 1, synchronousLoad: false, isShowLike: false, isVideoLiked: false, isShowSubcribe: false, isVideoSubscribed: false, isShowShare: false, replaceRootController: { controller, ready in
            print("👹  we're in replaceRootController....")
            if let baseNavigationController = self.navigationController {
                baseNavigationController.replaceTopController(controller, animated: false, ready: ready)
            }
        }, baseNavigationController: navigationController, actionInteraction: nil)
        galleryVC.temporaryDoNotWaitForReady = true
        galleryVC.temporaryDoNotWaitForReady = true
        galleryVC.useSimpleAnimation = true
        
        self.controller.present(galleryVC, in: .window(.root))
    }
}

public enum DiscoverSearchStatus: String, Codable {
    /// 正在搜索
    case searching
    /// 搜索完成
    case searchCompleted
    /// 非搜索
    case youtube
    
    case twitch
    
    case rumble
    
    case tiktok
    
    case filtered
}

extension WEVDiscoverRootNode {
    /// 搜索状态
    
    /*enum SelectedTab {
        //home screen Tab
        case youtube
        //home screen twitch
        case twitch
    }*/
}
//extension WEVDiscoverRootNode {
//    /// 搜索状态
//    public enum SearchStatus: String, Codable {
//        /// 正在搜索
//        case searching
//        /// 搜索完成
//        case searchCompleted
//        /// 非搜索
//        case youtube
//        
//        case twitch
//        
//        case rumble
//        
//        case tiktok
//                
//        case filtered
//    }
//    
//    /*enum SelectedTab {
//        //home screen Tab
//        case youtube
//        //home screen twitch
//        case twitch
//    }*/
//}
//MARK: - Data
extension WEVDiscoverRootNode: LJScrollViewRefreshDelegate {
    //MARK:- search live videos
    func searchLiveVideos(isHeadRefesh: Bool) {
        
        switch searchStatus {
        case .youtube, .twitch:
            DispatchQueue.main.async {
                self.collectionView?.lj.endRefreshing(isHeader: isHeadRefesh)
            }
            return
        default:
            break
        }
        
        let channelArray = self.searchStatus == .filtered ? selectedChannelArray : []
        let keyWord = (searchStatus == .youtube || searchStatus == .twitch) ? nil : searchWord
        let nextPageToken = isHeadRefesh ? nil : self.nextPageToken
        let searchOffset = (!isHeadRefesh && keyWord != nil) ? self.searchOffset : nil
        DispatchQueue.main.async {
            MBProgressHUD.showAdded(to: self.controller.view, animated: true)
        }
        LJNetManager.Video.discoverList(channelArray: channelArray,
                                        keyWord: keyWord,
                                        nextPageToken: nextPageToken,
                                        offset: searchOffset,
                                        latitude: currentLocation?.coordinate.latitude,
                                        longitude: currentLocation?.coordinate.longitude)
        {[weak self] (result) in
            guard let self = self else {return}
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.controller.view, animated: true)
                self.collectionView?.lj.endRefreshing(isHeader: isHeadRefesh)
            }
            if result.isSuccess,
               let data = result.successDicData,
               let list = data["liveVideoPojoList"] as? [Any],
               var array = [WEVVideoModel].deserialize(from: list) as? [WEVVideoModel],
               let nextPageToken = data["nextPageToken"] as? String {
                if isHeadRefesh {
                    self.showDataArray.removeAll()
                }
                array = array.filter { (item) -> Bool in
                    !self.showDataArray.contains(where: {$0.videoId == item.videoId})
                }
                self.nextPageToken = nextPageToken
                self.searchOffset = data["offset"] as? Int
                self.showDataArray.append(contentsOf: array)
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
                self.refreshEmptyView()
            }else {
                DispatchQueue.main.async {
                    MBProgressHUD.lj.showHint(result.message)
                }
                self.refreshEmptyView()
            }
        }
        
        // 下拉刷新且非搜索非筛选情况下才重新加载数据
        /*if isHeadRefesh && isShouldLoadBannerData {
            loadBannerData { success in
            }
        }*/
    }
    
    public func scrollViewLoadData(isHeadRefesh: Bool) {
        debugPrint("Pull to refresh")
        if isHeadRefesh {
            switch searchStatus {
            case .youtube:
                self.fetchYoutubeVideos { success in
                    DispatchQueue.main.async {
                        self.collectionView?.lj.endRefreshing(isHeader: isHeadRefesh)
                        self.collectionView?.reloadData()
                        self.refreshEmptyView()
                    }
                }
            case .twitch:
                self.fetchTwithVideo { success in
                    DispatchQueue.main.async {
                        self.collectionView?.lj.endRefreshing(isHeader: isHeadRefesh)
                        self.collectionView?.reloadData()
                        self.refreshEmptyView()
                    }
                }
            case .rumble:
                self.fetchRumbleVideo { success in
                    DispatchQueue.main.async {
                        self.collectionView?.lj.endRefreshing(isHeader: isHeadRefesh)
                        self.collectionView?.reloadData()
                        self.refreshEmptyView()
                    }
                }
            case .tiktok:
                self.fetchTiktokVideo { success in
                    DispatchQueue.main.async {
                        self.collectionView?.lj.endRefreshing(isHeader: isHeadRefesh)
                        self.collectionView?.reloadData()
                        self.refreshEmptyView()
                    }
                }
            default:
                DispatchQueue.main.async {
                    self.collectionView?.lj.endRefreshing(isHeader: isHeadRefesh)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.collectionView?.lj.endRefreshing(isHeader: isHeadRefesh)
            }
        }
    }
    
    /// 加载Banner数据
    private func loadBannerData(completion: @escaping (_ success: Bool) -> Void) {
        LJNetManager.Video.discoverBannerList {[weak self] (result) in
            guard let self = self else {return}
            if result.isSuccess,
               let data = result.successArrayData,
               let array = [WEVVideoModel].deserialize(from: data) as? [WEVVideoModel] {
                self.bannerDataArray = array
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
                completion(result.isSuccess)
            }else {
                DispatchQueue.main.async {
                    MBProgressHUD.lj.showHint(result.message)
                }
                completion(result.isSuccess)
            }
        }
    }
    
    /// 根据输入内容匹配直播名字
    private func searchLiveName(word: String) {
        LJNetManager.Video.searchName(liveName: word) {[weak self] (result) in
            guard let self = self else {return}
            if result.isSuccess,
               let data = result.successArrayData,
               let array = [WEVVideoModel.Anchor].deserialize(from: data) as? [WEVVideoModel.Anchor] {
                self.searchView.searchNameArray = array.compactMap{$0.liveName}
            }else {
                DispatchQueue.main.async {
                    MBProgressHUD.lj.showHint(result.message)
                }
            }
        }
    }
    
}

extension WEVDiscoverRootNode: RESegmentedControlDelegate {
    public func selectedSegmentIndex(_ segmentedControl: RESegmentedControl, selectedIndex: Int) {
        if let searchStatus = segmentedControl.segmentItems[selectedIndex].searchStatus, let status = DiscoverSearchStatus(rawValue: searchStatus) {
            self.searchStatus = status
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                self.refreshEmptyView()
            }
        }
    }
    
    public func segmentItemsIndexChanged(_ segmentedControl: RESegmentedControl, updatedItems: [SegmentModel]) {
        DiscoverRootItems.save(options: updatedItems)
    }
}

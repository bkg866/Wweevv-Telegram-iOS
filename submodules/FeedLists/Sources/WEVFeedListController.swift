import Foundation
import UIKit
import Display
import AsyncDisplayKit
import Postbox
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import PresentationDataUtils
import AccountContext
import SearchUI
import PostgREST
import AVFoundation

public class WEVFeedListController: ViewController {
    private let context: AccountContext
    
    private var controllerNode: WEVFeedListControllerNode {
        return self.displayNode as! WEVFeedListControllerNode
    }
    
    private var _ready = Promise<Bool>()
    override public var ready: Promise<Bool> {
        return self._ready
    }
    
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    private var editItem: UIBarButtonItem!
    private var doneItem: UIBarButtonItem!
    
    private var previousContentOffset: ListViewVisibleContentOffset?

    
    public init(context: AccountContext) {
        self.context = context
        
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.tabBarItemContextActionType = .always
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
        self.title = self.presentationData.strings.Feeds_Title
        self.tabBarItem.title = self.presentationData.strings.Feeds_TabTitle
        
        /*let icon: UIImage?
        if useSpecialTabBarIcons() { 
            icon = UIImage(bundleImageName: "Chat List/Tabs/Holiday/IconContacts")
        } else {
            icon = UIImage(bundleImageName: "Chat List/Tabs/IconContacts")
        }*/
        
        self.tabBarItem.image = UIImage(named:"tabbar_feed_tab")
        self.tabBarItem.selectedImage =  UIImage(named:"tabbar_feed_tab")

        /*self.tabBarItem.selectedImage = icon
        if !self.presentationData.reduceMotion {
            self.tabBarItem.animationName = "TabContacts"
        }*/
        
        self.editItem = UIBarButtonItem(title: self.presentationData.strings.Common_Done, style: .done, target: self, action: #selector(self.editPressed))
        self.doneItem = UIBarButtonItem(title: self.presentationData.strings.Common_Edit, style: .plain, target: self, action: #selector(self.editPressed))
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        self.presentationDataDisposable = (context.sharedContext.presentationData
                                           |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            if let strongSelf = self {
                let previousTheme = strongSelf.presentationData.theme
                let previousStrings = strongSelf.presentationData.strings
                
                strongSelf.presentationData = presentationData
                
                if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                    strongSelf.updateThemeAndStrings()
                }
            }
        })
        
        self.scrollToTopWithTabBar = { [weak self] in
            self?.controllerNode.scrollToTopWithTabBar()
        }

    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    private func updateThemeAndStrings() {
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData))
        self.title = self.presentationData.strings.Feeds_Title
        self.tabBarItem.title = self.presentationData.strings.Feeds_TabTitle
        /*if !self.presentationData.reduceMotion {
            self.tabBarItem.animationName = "TabContacts"
        } else {
            self.tabBarItem.animationName = nil
        }*/
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        self.controllerNode.updatePresentationData(self.presentationData)
        
        let editItem = UIBarButtonItem(title: self.presentationData.strings.Common_Done, style: .done, target: self, action: #selector(self.editPressed))
        let doneItem = UIBarButtonItem(title: self.presentationData.strings.Common_Edit, style: .plain, target: self, action: #selector(self.editPressed))
        if self.navigationItem.rightBarButtonItem === self.editItem {
            self.navigationItem.rightBarButtonItem = editItem
        } else if self.navigationItem.rightBarButtonItem === self.doneItem {
            self.navigationItem.rightBarButtonItem = doneItem
        }
        self.editItem = editItem
        self.doneItem = doneItem
    }
    
    
    override public func loadDisplayNode() {
        self.displayNode = WEVFeedListControllerNode(context: self.context, presentationData: self.presentationData, navigationBar: self.navigationBar!,controller: self, requestActivateSearch: { [weak self] in
            self?.activateSearch()
        }, requestDeactivateSearch: { [weak self] in
            self?.deactivateSearch()
        }, updateCanStartEditing: { [weak self] value in
            guard let strongSelf = self else {
                return
            }
            let item: UIBarButtonItem?
            if let value = value {
                item = value ? strongSelf.editItem : strongSelf.doneItem
            } else {
                item = nil
            }
            if strongSelf.navigationItem.rightBarButtonItem !== item {
                strongSelf.navigationItem.setRightBarButton(item, animated: true)
            }
        }, present: { [weak self] c, a in
            self?.present(c, in: .window(.root), with: a)
        }, push: { [weak self] c in
            self?.push(c)
        })
        
        self._ready.set(self.controllerNode._ready.get())
        self.navigationBar?.isHidden = true
        
        self.displayNodeDidLoad()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback)
            self.addPlayerNotifications()
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
        self.controllerNode.currentCell?.togglePlay(on: true, forceStop: false)
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removePlayerNotifations()
        self.controllerNode.currentCell?.togglePlay(on: false, forceStop: true)
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.cleanNavigationHeight, transition: transition)
    }
    
    @objc private func editPressed() {
        self.controllerNode.toggleEditing()
    }
    
    private func activateSearch() {
    }
    
    private func deactivateSearch() {
    }
    
    internal func addPlayerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    internal func removePlayerNotifations() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc internal func applicationWillEnterForeground(_ notification: Notification) {
        self.controllerNode.currentCell?.togglePlay(on: true, forceStop: nil)
    }
    
    @objc internal func applicationDidEnterBackground(_ notification: Notification) {
        self.controllerNode.currentCell?.togglePlay(on: false, forceStop: nil)
    }
    
}

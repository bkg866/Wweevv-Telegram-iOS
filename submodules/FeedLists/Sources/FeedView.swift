//
//  FeedView.swift
//  CrissCross
//
//  Created by Kyle Lee on 9/3/20.
//  Copyright © 2020 Kilo Loco. All rights reserved.
//

import Combine
import UIKit
import SnapKit
import WevConfig

final class FeedView: UIView {
    
    var focusPublisher = PassthroughSubject<Int, Never>()
    var visibleIndex = -1
        
    lazy var collectionView: UICollectionView = {
        
        let screen = UIScreen.main.bounds
        let bottomPadding: CGFloat = LJScreen.tabBarHeight

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let layoutGroupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(screen.width),
            heightDimension: .absolute(screen.height - bottomPadding)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: layoutGroupSize,
            subitems: [layoutItem]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        //let inset: CGFloat = 0
        section.contentInsets.top = .zero
        section.visibleItemsInvalidationHandler = { [weak self] (items, offset, environment) in
            
            let contentHeight = environment.container.contentSize.height
            let offset = offset.y + (contentHeight / 1.9)
            let focusIndex = Int(offset) / Int(contentHeight)
            print("---",offset,"---",contentHeight,"---",focusIndex,"---")
            if self?.visibleIndex != focusIndex {
                self?.visibleIndex = focusIndex
                self?.focusPublisher.send(focusIndex)
            }
        }
        
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .horizontal
        let layout = UICollectionViewCompositionalLayout(section: section, configuration: configuration)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        return collectionView
    }()
    
    let refreshControl = OffsetableRefreshControl()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupSelf()
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupSelf() {
        backgroundColor = .systemBackground
    }
    
    private func setupSubviews() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-LJScreen.tabBarHeight)
        }
        
        refreshControl.tintColor = UIColor.white
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: .valueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.refreshControl = refreshControl
        collectionView.alwaysBounceVertical = true
        collectionView.alwaysBounceHorizontal = false
        
    }
    
    func register<Cell: Reusable>(_ cells: Cell.Type...) {
        cells.forEach { self.collectionView.register($0, forCellWithReuseIdentifier: $0.reuseIdentifier) }
    }
    
    func bind(to manager: FeedCollectionViewManager) {
        manager.manage(collectionView)
    }
    
    func scrollToTop(animated: Bool = true) {
        if self.collectionView.numberOfSections > 0, self.collectionView.numberOfItems(inSection: 0) > 0 {
            self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: animated)
        }
    }
    
    func toggleRefreshControl(isShow: Bool) {
        DispatchQueue.main.async {
            if isShow {
                self.refreshControl.beginRefreshingWithAnimation()
            } else {
                self.refreshControl.endRefreshing()
                //reset visible index
                self.visibleIndex = -1
            }
        }
    }
    
    @objc func refreshControlAction(_ sender: UIRefreshControl) {
        //reset visible index
        self.visibleIndex = -1
        sender.endRefreshing()
    }
}

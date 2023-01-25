//
//  RESegmentedControl.swift
//  RESegmentedControl
//
//  Created by Sherzod Khashimov on 7/10/18.
//  Copyright © 2018 Sherzod Khashimov. All rights reserved.
//

import UIKit

public protocol RESegmentedControlDelegate {
    func selectedSegmentIndex(_ segmentedControl: RESegmentedControl, selectedIndex: Int)
    func segmentItemsIndexChanged(_ segmentedControl: RESegmentedControl, updatedItems: [SegmentModel])
}

extension RESegmentedControlDelegate {
    func segmentItemsIndexChanged(_ segmentedControl: RESegmentedControl, updatedItems: [SegmentModel]) { }
}

/// Segmeted Control
open class RESegmentedControl: UIControl {

    /// Collection view flow
    private lazy var collectionViewFlow: UICollectionViewFlowLayout = {
        let collectionViewFlow = UICollectionViewFlowLayout()
        collectionViewFlow.itemSize = CGSize(width: CGFloat.leastNonzeroMagnitude, height: CGFloat.leastNonzeroMagnitude)
        collectionViewFlow.sectionInset = .zero
        collectionViewFlow.scrollDirection = .horizontal
        collectionViewFlow.minimumInteritemSpacing = 0
        collectionViewFlow.minimumLineSpacing = 0
        collectionViewFlow.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return collectionViewFlow
    }()

    /// Collection view that displays a list of segment's text and image
    private lazy var collectionView: UICollectionView = {

        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewFlow)

        collectionView.isPagingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.bounces = true
        collectionView.clipsToBounds = false
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear

        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(SegmentCollectionViewCell.self, forCellWithReuseIdentifier: "\(SegmentCollectionViewCell.self)")

        return collectionView
    }()

    /// Collection view that displays a list of segment's backgrounds with separator
    private lazy var collectionViewBackground: UICollectionView = {

        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewFlow)

        collectionView.isPagingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.bounces = true
        collectionView.clipsToBounds = false
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear

        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(BackgroundCollectionViewCell.self, forCellWithReuseIdentifier: "\(BackgroundCollectionViewCell.self)")

        return collectionView
    }()

    /// Whether or not collection views should update its frame
    var canCollectionViewUpdateLayout: Bool = true
    
    public var canCollectionViewIndexChange: Bool = true {
        willSet {
            collectionView.dragDelegate = newValue ? self : nil
            collectionView.dropDelegate = newValue ? self : nil
            collectionView.dragInteractionEnabled = newValue
        }
    }
    
    /// Used to reload specific items in collections, should be set to nil manually after updates
    var reloadItems: [IndexPath]? = nil
    open var delegate: RESegmentedControlDelegate?

    /// Background view that overlay selected background segment
    private lazy var selectedBackgroundView: UIView = {
        let selectedBackgroundView = UIView()
        selectedBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        return selectedBackgroundView
    }()

    /// Preset that applied to style Segmented control and it's child views
    public var preset: SegmentedControlPresettable = MaterialPreset(backgroundColor: .white, tintColor: .white) {
        didSet {
            collectionView.clipsToBounds = preset.segmentStyle.clipsToBounds
            collectionViewBackground.clipsToBounds = preset.segmentStyle.clipsToBounds
            collectionView.layer.cornerRadius = preset.segmentStyle.cornerRadius
            collectionViewBackground.layer.cornerRadius = preset.segmentStyle.cornerRadius
            collectionView.layer.borderColor = preset.segmentStyle.borderColor
            collectionView.layer.borderWidth = preset.segmentStyle.borderWidth
            selectedBackgroundView.backgroundColor = preset.segmentSelectedItemStyle.backgroundColor
            selectedBackgroundView.layer.cornerRadius = preset.segmentSelectedItemStyle.cornerRadius
            selectedBackgroundView.layer.borderWidth = preset.segmentSelectedItemStyle.borderWidth
            selectedBackgroundView.layer.borderColor = preset.segmentSelectedItemStyle.borderColor
            if let shadowStyle = preset.segmentSelectedItemStyle.shadow {
                selectedBackgroundView.applyShadow(with: shadowStyle)
            }
            self.collectionView.reloadData()
            self.collectionViewBackground.reloadData()
        }
    }

    /// Segment items, models that will be used inside segments
    ///
    /// Should be added in configure method
    public var segmentItems: [SegmentModel] = [SegmentModel]()

    /// Selected segment index
    public var selectedSegmentIndex: Int = -1 {
        didSet {
            if oldValue != selectedSegmentIndex {
                canCollectionViewUpdateLayout = false
                updateLayouts()
                canCollectionViewUpdateLayout = true
                guard segmentItems.count != 0,
                    selectedSegmentIndex != -1,
                    selectedSegmentIndex < segmentItems.count else { return }
                DispatchQueue.main.async { [self] in
                    self.sendActions(for: .valueChanged)
                    self.delegate?.selectedSegmentIndex(self, selectedIndex: self.selectedSegmentIndex)
                }
            }
        }
    }

    /// Computed property for segment item size
    private var itemSize: CGSize {
        let collectionViewWidth = collectionView.bounds.size.width
        let itemCount = CGFloat(segmentItems.count)

        let segmentsSpacing = preset.segmentStyle.spacing * (itemCount - 1)

        let itemWidth = ((collectionViewWidth - segmentsSpacing) / itemCount).rounded()
        let itemSize = CGSize(width: itemWidth, height: collectionView.bounds.size.height)
        return itemSize
    }

    /// Initializes segmented control with a specified frame, segment item's models and styles.
    ///
    /// Used during code-layout implementation. Use `configure` method if you implement UI using storyboard.
    /// - Parameters:
    ///   - frame: Frame
    ///   - segmentItems: Segment item models
    ///   - preset: Style preset
    ///   - selectedIndex: selected index (optional)
    public init(frame: CGRect, segmentItems: [SegmentModel], preset: SegmentedControlPresettable = BootstapPreset(), selectedIndex: Int = 0) {
        super.init(frame: frame)
        configure(segmentItems: segmentItems, preset: preset, selectedIndex: selectedIndex)
    }

    /// Configures the segment items and styles.
    /// - Parameters:
    ///   - segmentItems: Segment item models
    ///   - preset: Style preset
    ///   - selectedIndex: Selected index (optional)
    public func configure(segmentItems: [SegmentModel], preset: SegmentedControlPresettable = BootstapPreset(), selectedIndex: Int = 0) {
        self.segmentItems = segmentItems
        self.preset = preset
        updateLayouts()

        if segmentItems.count > 0 {
            selectedSegmentIndex = selectedIndex
        } else {
            selectedSegmentIndex = -1
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addViews()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addViews()
    }

    /// Adds views during initialization.
    ///
    /// Should be used during initialization
    private func addViews() {
        self.addSubview(collectionViewBackground)
        collectionViewBackground.addSubview(selectedBackgroundView)
        self.addSubview(collectionView)
        addLayouts()
    }

    /// Adds layouts to the views.
    ///
    /// Should be used during initialization
    private func addLayouts() {

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionViewBackground.translatesAutoresizingMaskIntoConstraints = false

        switch preset.segmentStyle.size {
        case .maxHeight:
            collectionViewBackground.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            collectionViewBackground.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            collectionView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        case .fixed(let height):
            collectionViewBackground.heightAnchor.constraint(equalToConstant: height).isActive = true
            collectionViewBackground.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            collectionView.heightAnchor.constraint(equalToConstant: height).isActive = true
            collectionView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        }

        collectionViewBackground.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        collectionViewBackground.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true

        collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }

    open override func layoutSubviews() {
        
        super.layoutSubviews()

        let itemSize = self.itemSize

        if canCollectionViewUpdateLayout {
            updateCollectionViewSize(withItemSize: itemSize)
        }

        updateSelectedBackgroundViewFrame(withItemSize: itemSize)
    }

    /// Updates views layouts.
    ///
    /// Layout-Driven UI 😎
    func updateLayouts() {
        self.setNeedsLayout()
        let duration = !canCollectionViewUpdateLayout ? 0.5 : 0
        if #available(iOS 10.0, *) {
            let layoutAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1.3) {
                self.layoutIfNeeded()
            }
            layoutAnimator.startAnimation()
        } else {
            // Fallback on earlier versions
            UIView.animate(withDuration: duration) {
                self.layoutIfNeeded()
            }
        }
    }

    /// Updates collection view frame
    /// - Parameter itemSize: New segment item size
    private func updateCollectionViewSize(withItemSize itemSize: CGSize) {
        collectionViewFlow.minimumLineSpacing = preset.segmentStyle.spacing

        collectionViewFlow.itemSize = itemSize

        collectionView.collectionViewLayout = collectionViewFlow
        collectionViewBackground.collectionViewLayout = collectionViewFlow

        if let reloadOnlyItems = reloadItems {
            collectionView.reloadItems(at: reloadOnlyItems)
        } else {
            collectionView.reloadData()
            collectionViewBackground.reloadData()
        }
    }

    /// Updates selected background frame
    /// - Parameter itemSize: New segment item size
    private func updateSelectedBackgroundViewFrame(withItemSize itemSize: CGSize) {
        let offset = preset.segmentSelectedItemStyle.offset

        var backgroundSize = CGSize(width: itemSize.width, height: itemSize.height - 2*offset)
        var backgroundYPosition: CGFloat = 0 + offset

        switch preset.segmentSelectedItemStyle.size {
        case .height(let height, let position):
            backgroundSize = CGSize(width: itemSize.width - 2*offset, height: CGFloat(height) - 2*offset)
            switch position {
            case .bottom:
                backgroundYPosition = itemSize.height - CGFloat(height) + offset
            default:
                backgroundYPosition = 0 + offset
            }
        default:
            break
        }

        if selectedSegmentIndex == -1 {
            selectedBackgroundView.isHidden = true
            selectedBackgroundView.frame = CGRect(origin: CGPoint(x: offset, y: backgroundYPosition + offset), size: backgroundSize)
        } else {
            selectedBackgroundView.isHidden = false
            var selectedItemXPosition: CGFloat = CGFloat(selectedSegmentIndex) * (itemSize.width + preset.segmentStyle.spacing)

            switch selectedSegmentIndex {
            case 0:
                selectedItemXPosition += offset
                backgroundSize.width -= offset
            case segmentItems.count - 1:
                backgroundSize.width -= offset
            default:
                break
            }

            let selectedItemPosition = CGPoint(x: selectedItemXPosition, y: backgroundYPosition)
            selectedBackgroundView.frame = CGRect(origin: selectedItemPosition, size: backgroundSize)
        }
    }

}

// - MARK: UICollectionViewDataSource
extension RESegmentedControl: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return segmentItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard collectionView == self.collectionView else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(BackgroundCollectionViewCell.self)", for: indexPath) as? BackgroundCollectionViewCell
            cell?.configure(style: preset.segmentItemStyle, isSeparatorVisible: indexPath.row != 0)
            cell?.contentView.backgroundColor = self.preset.segmentItemStyle.backgroundColor
            return cell ?? UICollectionViewCell()
        }

        var cell: SegmentCollectionViewCell?

        let segmentItem = segmentItems[indexPath.row]

        cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(SegmentCollectionViewCell.self)", for: indexPath)
        as? SegmentCollectionViewCell

        cell?.configure(segmentItem, style: preset.segmentItemStyle)
        if selectedSegmentIndex >= 0,
            selectedSegmentIndex < segmentItems.count,
            indexPath.row == selectedSegmentIndex {
            cell?.isSelected = indexPath.row == selectedSegmentIndex
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        } else {
            cell?.isSelected = false
        }

        return cell ?? UICollectionViewCell()
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard collectionView == self.collectionView else { return }
        guard let _cell = cell as? SegmentCollectionViewCell else { return }
        _cell.loadImageIfNeeded()
    }
}

// - MARK: UICollectionViewDelegate
extension RESegmentedControl: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedSegmentIndex = indexPath.row
    }

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return collectionView == self.collectionView
    }
}

extension RESegmentedControl: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        var destinationIndex: IndexPath
        
        if let index = coordinator.destinationIndexPath {
            destinationIndex = index
        } else {
            let row = collectionView.numberOfItems(inSection: 0)
            destinationIndex = IndexPath(row: row - 1, section: 0)
        }
        
        if coordinator.proposal.operation == .move {
            self.reorderItems(coordinator: coordinator, destinationIndex: destinationIndex, collectionView: collectionView)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        let item = self.segmentItems[indexPath.row]
        let itemProvider = NSItemProvider(object: "\(indexPath)" as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        
        guard let cell = collectionView.cellForItem(at: indexPath) else { return [dragItem] }
        cell.backgroundColor = self.preset.segmentItemStyle.backgroundColor
        cell.contentView.backgroundColor = self.preset.segmentItemStyle.backgroundColor
        dragItem.previewProvider = {
            let dragPreviewParams = UIDragPreviewParameters()
            dragPreviewParams.backgroundColor = self.preset.segmentItemStyle.backgroundColor
            return UIDragPreview(view: cell.contentView, parameters: dragPreviewParams)
        }
        return [dragItem]
    }
    public func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        collectionView.reloadData()
    }
    
    public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }
    
    fileprivate func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndex: IndexPath, collectionView: UICollectionView) {
        if let item = coordinator.items.first,
           let sourceIndexPath = item.sourceIndexPath,
           let segmentItem = item.dragItem.localObject as? SegmentModel {
            if sourceIndexPath != destinationIndex {
                collectionView.performBatchUpdates({
                    
                    let selectedItem = self.segmentItems[selectedSegmentIndex]
                    
                    self.segmentItems.remove(at: sourceIndexPath.row)
                    self.segmentItems.insert(segmentItem, at: destinationIndex.item)
                    self.selectedSegmentIndex = (self.segmentItems.firstIndex { $0.searchStatus == selectedItem.searchStatus }) ?? self.selectedSegmentIndex
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndex])
                    collectionView.reloadItems(at: [sourceIndexPath, destinationIndex])
                }, completion: { _ in
                    self.clearBackgroundColor(sourceIndexPath: sourceIndexPath, destinationIndex: destinationIndex)
                    self.delegate?.segmentItemsIndexChanged(self, updatedItems: self.segmentItems)
                    collectionView.reloadItems(at: [sourceIndexPath, destinationIndex])
                })
            } else {
                self.clearBackgroundColor(sourceIndexPath: sourceIndexPath, destinationIndex: destinationIndex)
            }

            coordinator.drop(item.dragItem, toItemAt: destinationIndex)
        }
    }
    
    func clearBackgroundColor(sourceIndexPath: IndexPath, destinationIndex: IndexPath) {
        if let cell = collectionView.cellForItem(at: sourceIndexPath) {
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
        }
        if let cell = collectionView.cellForItem(at: destinationIndex) {
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
        }
    }
}

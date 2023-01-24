//
//  WEVEmptyHintView.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit
import TelegramPresentationData
import SnapKit

public struct Model {
    public var title: String
    public var image: String
    public var desc: String?
    public var descAttributedString: NSAttributedString?
    
    public init(title: String, image: String, desc: String? =  nil, descAttributedString: NSAttributedString? = nil) {
        self.title = title
        self.image = image
        self.desc = desc
        self.descAttributedString = descAttributedString
    }
}
public final class WEVEmptyHintView: UIView {
    
    public var presentationData: PresentationData? = nil {
        didSet {
            updateThemeColor()
        }
    }
    
    public func updateThemeColor() {
        guard let presentationData = self.presentationData else {
            return
        }
        self.backgroundColor = presentationData.theme.chatList.backgroundColor
        self.titleLabel.textColor = presentationData.theme.list.itemPrimaryTextColor
        self.descLabel.textColor = presentationData.theme.list.itemPrimaryTextColor
    }
    
    
    
    public var model: Model? = nil {
        didSet {
            updateView()
        }
    }
    
    public init(model: Model) {
        self.model = model
        super.init(frame: .zero)
        initView()
    }
    
    
    /*init() {
        super.init(frame: CGRect())
    }

    required init?(coder aDecoder: NSCoder) {
        preconditionFailure()
    }*/

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    //MARK: UI
    public func initView() {
        backgroundColor = .white
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview().offset(20)
        }
        
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.bottom.equalTo(titleLabel.snp.top).offset(-30)
            make.centerX.equalToSuperview()
        }
        
        addSubview(descLabel)
        descLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
        
        updateView()
    }
    
    public func updateView() {
        guard let model = model else { return }
        titleLabel.text = model.title
        imageView.image = UIImage.init(named: model.image)
        if let descAttributedString = model.descAttributedString {
            descLabel.attributedText = descAttributedString
        }else {
            descLabel.text = model.desc
        }
    }
    

    /// 图片
    public let imageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    /// 标题
    public let titleLabel: UILabel = {
        let view = UILabel.lj.configure(font: LJFont.medium(20))
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()

    /// 描述
    public let descLabel: UILabel = {
        let view = UILabel.lj.configure(font: LJFont.regular(16), textColor: LJColor.gray)
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()

}


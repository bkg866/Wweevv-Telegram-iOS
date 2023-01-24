//
//  LJExtension+String.swift
//  Wweevv
//
//  Created by panjinyong on 2021/1/15.
//

import Foundation
import CommonCrypto

extension String: LJExtensionCompatible {}

extension LJExtension where Base == String {
   
    /// 是否有效的email
    public var isValidEmail: Bool {
        get {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
            return NSPredicate.init(format: "SELF MATCHES %@", emailRegex).evaluate(with: base)
        }
    }
    
    
    /// 密码有效性（8~16位字母+数字）
    var passwordValidity: PasswordValidity {
        get {
            if base.count < 8 {
                return .invalid(.length)
            }else {
                return .valid
            }
        }
    }
    
    /// 密码有效性
    enum PasswordValidity: Equatable {
        
        /// 有效
        case valid
        
        /// 无效
        case invalid(PasswordError)
        
        /// 密码错误类型
        enum PasswordError {
            /// 长度不对（8--16位）
            ///
        case length
        /// 内容不符合（包含数字、字母）
        //case content
        }
    }
    
}

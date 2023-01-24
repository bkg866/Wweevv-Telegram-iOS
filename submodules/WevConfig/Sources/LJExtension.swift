//
//  LJExtension.swift
//  Wweevv
//
//  Created by panjinyong on 2020/12/22.
//

import Foundation

public struct LJExtension<Base> {
    let base: Base
    init(_ base: Base) {
        self.base = base
    }
}

public protocol LJExtensionCompatible {}

extension LJExtensionCompatible {
    public static var lj: LJExtension<Self>.Type {
        get { LJExtension<Self>.self }
        set {}
    }
    
    public var lj: LJExtension<Self> {
        get { LJExtension(self) }
        set {}
    }
    
}

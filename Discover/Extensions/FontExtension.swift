//
//  FontExtension.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI

extension Font {
    static func plusJakartaSans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .custom("Plus Jakarta Sans", size: size)
            .weight(weight)
    }
    
    static func plusJakartaSansBold(size: CGFloat) -> Font {
        return .custom("Plus Jakarta Sans Bold", size: size)
    }
    
    static func plusJakartaSansSemiBold(size: CGFloat) -> Font {
        return .custom("Plus Jakarta Sans SemiBold", size: size)
    }
    
    static func plusJakartaSansMedium(size: CGFloat) -> Font {
        return .custom("Plus Jakarta Sans Medium", size: size)
    }
}

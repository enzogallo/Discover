//
//  LocalizedString.swift
//  Discover
//
//  Created by Enzo Gallo on 06/12/2025.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    func localized(with argument: Int) -> String {
        return String(format: self.localized, argument)
    }
}



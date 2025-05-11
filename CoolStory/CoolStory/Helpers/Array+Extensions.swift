//
//  Array+Extensions.swift
//  CoolStory
//
//  Created by Radhouani Malek on 11/05/2025.
//

import Foundation

extension Array  where Element: Equatable{
    func nextItem(after: Element) -> Element? {
        if let index = self.firstIndex(of: after), index + 1 < self.count {
            return self[index + 1]
        }
        return nil
    }
    
    func previous(item: Element) -> Element? {
        if let index = self.firstIndex(of: item), index > 0 {
            return self[index - 1]
        }
        return nil
    }
}

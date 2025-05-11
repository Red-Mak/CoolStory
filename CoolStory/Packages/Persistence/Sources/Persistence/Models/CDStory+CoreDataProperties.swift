//
//  File.swift
//  Persistence
//
//  Created by Radhouani Malek on 11/05/2025.
//

import Foundation
import CoreData


extension CDStory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDStory> {
        return NSFetchRequest<CDStory>(entityName: "CDStory")
    }

    @NSManaged public var identifier: Int64
    @NSManaged public var likedAtLeastOnce: Bool

}

extension CDStory : Identifiable {

}

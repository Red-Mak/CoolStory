//
//  File.swift
//  Persistence
//
//  Created by Radhouani Malek on 11/05/2025.
//

import Foundation
import CoreData


extension CDUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUser> {
        return NSFetchRequest<CDUser>(entityName: "CDUser")
    }

    @NSManaged public var identifier: Int64
    @NSManaged public var storyAlreadySeen: Bool

}

extension CDUser : Identifiable {

}

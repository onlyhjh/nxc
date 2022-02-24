//
//  ContactEntity+CoreDataProperties.swift
//  test
//
//  Created by 부리부리황 on 2022/02/24.
//
//

import Foundation
import CoreData


extension ContactEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ContactEntity> {
        return NSFetchRequest<ContactEntity>(entityName: "ContactEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var firstname: String?
    @NSManaged public var lastname: String?
    @NSManaged public var phone: String?
    @NSManaged public var email: String?

}

extension ContactEntity : Identifiable {

}

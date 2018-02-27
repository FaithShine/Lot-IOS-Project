//
//  Profile+CoreDataProperties.swift
//  smartroom
//
//  Created by Bruno Luis Mendivez Vasquez on 12/11/2016.
//  Copyright © 2016 Bruno Luis Mendivez Vasquez. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Profile {

    @NSManaged var name: String?
    @NSManaged var doorTrigger: NSNumber?
    @NSManaged var offAt: String?
    @NSManaged var color: String?
    @NSManaged var onAmbientLevel: NSNumber?
    @NSManaged var maxBrightness: NSNumber?
    @NSManaged var timeToBrightness: NSNumber?
    @NSManaged var profilecollection: ProfileCollection?

}

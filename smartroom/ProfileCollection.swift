//
//  ProfileCollection.swift
//  smartroom
//
//  Created by Bruno Luis Mendivez Vasquez on 12/11/2016.
//  Copyright © 2016 Bruno Luis Mendivez Vasquez. All rights reserved.
//

import Foundation
import CoreData


class ProfileCollection: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    func addProfile(value: Profile)
    {
        let col = self.mutableSetValueForKey("profiles")
        col.addObject(value)
    }
}

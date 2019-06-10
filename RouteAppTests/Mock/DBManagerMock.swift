//
//  DBManagerMock.swift
//  RouteAppTests
//
//  Created by Mohit Kumar on 10/06/19.
//  Copyright © 2019 Mohit Kumar. All rights reserved.
//

import Foundation
@testable import RouteApp
import CoreData
import UIKit

enum DBActionType {
    case deliveryList
    case error
    
    func handleResponse(onSuccess: @escaping ResponseBlock) {
        switch self {
        case .deliveryList:
            onSuccess(getDeliveries(), nil)
        case .error:
            onSuccess(nil, NSError(domain: Constants.serverErrorDomain, code: Constants.serverErrorCode, userInfo: nil))
        }
    }
    
    fileprivate func getDeliveries() -> [DeliveryModel] {
        let data = JSONHelper.jsonFileToData(jsonName: "deliveryList")
        do {
            let decoder = JSONDecoder()
            let deliveries = try decoder.decode([DeliveryModel].self, from: data!)
            return deliveries
        } catch {
            
        }
        return []
    }
}

class DBManagerMock: NSObject, DBManagerAdapter {
    var managedObjectContext: NSManagedObjectContext?
    let deliveryEntity = "Delivery"
    let locationEntity = "Location"
    var dbActionType: DBActionType!
    
    init(dbActionType: DBActionType) {
        let mockManagedObjectModel = NSManagedObjectModel.mergedModel(from: nil)
        let mockStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mockManagedObjectModel!)
        let _ = try? mockStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.managedObjectContext!.persistentStoreCoordinator = mockStoreCoordinator
        self.dbActionType = dbActionType
    }
    
    func saveDeliveries(deliveries: [DeliveryModel]) -> Void {
        
        let deliveryEntity = NSEntityDescription.entity(forEntityName: self.deliveryEntity, in: managedObjectContext!)!
        let locationEntity = NSEntityDescription.entity(forEntityName: self.locationEntity, in: managedObjectContext!)!
        
        for delivery in deliveries {
            var cacheDeliveryModel: Delivery? = getDeliveryFromCache(deliveryID: delivery.id)
            if cacheDeliveryModel == nil {
                cacheDeliveryModel = NSManagedObject(entity: deliveryEntity, insertInto: managedObjectContext!) as? Delivery
                cacheDeliveryModel?.location = NSManagedObject(entity: locationEntity, insertInto: managedObjectContext!) as? Location
            }
            if let deliveryModel = cacheDeliveryModel {
                deliveryModel.id = Int32(delivery.id)
                deliveryModel.desc = delivery.description
                deliveryModel.imageUrl = delivery.imageUrl
                deliveryModel.location?.setValue(delivery.location?.lat, forKey: "lat")
                deliveryModel.location?.setValue(delivery.location?.lng, forKey: "long")
                deliveryModel.location?.setValue(delivery.location?.address, forKey: "address")
                
                do {
                    try managedObjectContext?.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    func getDeliveryFromCache(deliveryID: Int) -> Delivery? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: deliveryEntity)
        let predicate = NSPredicate(format: "id = %d", deliveryID)
        fetchRequest.predicate = predicate
        
        do {
            let records = try managedObjectContext!.fetch(fetchRequest) as! [Delivery]
            if records.count > 0 {
                return records[0]
            }
        } catch {
        }
        return nil
    }
    
    func getDeliveries(offset: Int, limit: Int, onSuccess: @escaping ResponseBlock) {
        dbActionType.handleResponse(onSuccess: onSuccess)
    }
    
    func cleanCache() {
        do {
            let records = try managedObjectContext!.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: deliveryEntity)) as! [NSManagedObject]
            for record in records {
                managedObjectContext?.delete(record)
            }
        } catch {
        }
        do {
            try managedObjectContext?.save()
        } catch let error as NSError {
            print("Could not delete. \(error), \(error.userInfo)")
        }
    }
    
    func allRecords() -> [Delivery] {
        do {
            let records = try managedObjectContext!.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: deliveryEntity)) as! [Delivery]
            return records
        } catch {
        }
        return []
    }
    
    func isCacheAvailable() -> Bool {
        return allRecords().count > 0
    }
}

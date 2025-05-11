import CoreData
import Combine

public class PersistenceManager: NSObject {
    @MainActor static let shared = PersistenceManager()
    
    private let container: NSPersistentContainer
    public var didUpdateUsers = CurrentValueSubject<Bool, Never>(false)
    public var storyUpdated = CurrentValueSubject<Bool, Never>(false)
    
    private var currentStoryId: Int?
    
    private lazy var usersFetchedResultsController:
    NSFetchedResultsController<CDUser> = {
        
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(CDUser.identifier),
                                    ascending: false)
        fetchRequest.sortDescriptors = [sort]
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.container.viewContext,
            sectionNameKeyPath:  nil,
            cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    private lazy var currentStoryFetchedResultsController:
    NSFetchedResultsController<CDStory> = {
        
        let fetchRequest: NSFetchRequest<CDStory> = CDStory.fetchRequest()

        let sort = NSSortDescriptor(key: #keyPath(CDStory.identifier),
                                    ascending: false)
        fetchRequest.sortDescriptors = [sort]
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.container.viewContext,
            sectionNameKeyPath:  nil,
            cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    private func likeState(for storyId: Int) -> Bool {
        do {
            let fetchRequest: NSFetchRequest<CDStory> = CDStory.fetchRequest()
            fetchRequest.fetchLimit = 1
            let predicate = NSPredicate(format: "%K = %i ", #keyPath(CDStory.identifier), storyId)
            fetchRequest.predicate = predicate
            let result = try self.container.viewContext.fetch(fetchRequest)
            return result.first?.likedAtLeastOnce ?? false
        } catch {
            return false
        }
    }

    public override init() {
        guard let modelURL = Bundle.module.url(forResource:"CoolStory", withExtension: "momd") else {
            fatalError("core data model not found")
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Cant create model")
        }
        
        container = NSPersistentContainer(name:"CoolStory",managedObjectModel:model)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        super.init()
        try? self.usersFetchedResultsController.performFetch()
    }
    
    public func batchUpdate(users: [[String: Any]]) {
        let backgroundContext = self.container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        backgroundContext.performAndWait {
            let insertRequest = NSBatchInsertRequest(entity: CDUser.entity(), objects: users)
            insertRequest.resultType = NSBatchInsertRequestResultType.objectIDs
            let result = try? backgroundContext.execute(insertRequest) as? NSBatchInsertResult
            
            if let objectIDs = result?.result as? [NSManagedObjectID], objectIDs.isEmpty == false {
                let save = [NSInsertedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: save, into: [self.container.viewContext])
            }
        }
    }
    
    public func alreadySeen(userId: Int) -> Bool {
        do {
            let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            fetchRequest.fetchLimit = 1
            let predicate = NSPredicate(format: "%K = %i ", #keyPath(CDUser.identifier), userId)
            fetchRequest.predicate = predicate
            let result = try self.container.viewContext.fetch(fetchRequest)
            return result.first?.storyAlreadySeen ?? false
        } catch {
            return false
        }
    }
    
    public func markAsSeen(userId: Int) {
        let backgroundContext = self.container.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.perform {
            do {
                let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
                fetchRequest.fetchLimit = 1
                let predicate = NSPredicate(format: "%K = %i ", #keyPath(CDUser.identifier), userId)
                fetchRequest.predicate = predicate
                let result = try backgroundContext.fetch(fetchRequest)
                if let user = result.first {
                    user.storyAlreadySeen = true
                } else {
                    let user = CDUser(context: backgroundContext)
                    user.identifier = Int64(userId)
                    user.storyAlreadySeen = true
                }
            } catch let error {
                print("error \(#function) \(error.localizedDescription)")
            }
            try? backgroundContext.save()
        }
        
        try? self.container.viewContext.save()
    }
    
    public func listenToUpdates(for storyId: Int) {
        self.currentStoryId = storyId
        let predicate = NSPredicate(format: "%K = %i ", #keyPath(CDStory.identifier), storyId)
        self.currentStoryFetchedResultsController.fetchRequest.predicate = predicate
        try? currentStoryFetchedResultsController.performFetch()
        
        // delegate not firing here, solutio:
        let liked = self.likeState(for: storyId)
        self.storyUpdated.send(liked)
    }
    
    public func triggerLiked(storyId: Int) {
        let backgroundContext = self.container.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.perform {
            do {
                let fetchRequest: NSFetchRequest<CDStory> = CDStory.fetchRequest()
                fetchRequest.fetchLimit = 1
                let predicate = NSPredicate(format: "%K = %i ", #keyPath(CDStory.identifier), storyId)
                fetchRequest.predicate = predicate
                let result = try backgroundContext.fetch(fetchRequest)
                if let story = result.first {
                    story.likedAtLeastOnce = !story.likedAtLeastOnce
                } else {
                    let story = CDStory(context: backgroundContext)
                    story.identifier = Int64(storyId)
                    story.likedAtLeastOnce = true
                }
            } catch let error {
                print("error \(#function) \(error.localizedDescription)")
            }
            try? backgroundContext.save()
        }
        
        try? self.container.viewContext.save()
    }
    
    public func eraseAllLocalData() {
        let backgroundContext = self.container.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        func erase(object: String) {
            do {
                let usersBatchDeleteRequest = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: object))
                usersBatchDeleteRequest.resultType = .resultTypeObjectIDs
                let usersResult = try backgroundContext.execute(usersBatchDeleteRequest) as! NSBatchDeleteResult
                let changes: [AnyHashable: Any] = [
                    NSDeletedObjectsKey: usersResult.result as! [NSManagedObjectID]
                ]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.container.viewContext])
                
            } catch let error {
                print("error \(#function) \(error.localizedDescription)")
            }
        }
        
        backgroundContext.perform {
            erase(object: "CDUser")
            erase(object: "CDStory")
            
            try? backgroundContext.save()
        }
        
        try? self.container.viewContext.save()
    }
}

extension PersistenceManager: NSFetchedResultsControllerDelegate {
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller === self.usersFetchedResultsController {
            self.didUpdateUsers.send(true)
        }
        
        if controller === self.currentStoryFetchedResultsController,
            let currentStoryId {
            let liked = self.likeState(for: currentStoryId)
            self.storyUpdated.send(liked)
        }
    }
}

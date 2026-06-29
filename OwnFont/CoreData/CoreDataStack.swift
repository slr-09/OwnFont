//
//  CoreDataStack.swift
//  OwnFont
//

import CoreData
import FirebaseCrashlytics

final class CoreDataStack {

    static let shared = CoreDataStack()
    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "OwnFont")
        loadPersistentStore(in: container)
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    private func loadPersistentStore(in container: NSPersistentContainer) {
        container.loadPersistentStores { [weak self] description, error in
            guard let self, let error else { return }
            recordPersistentStoreError(error, reason: "initial_load_failed")
            recoverPersistentStore(in: container, description: description, originalError: error)
        }
    }

    private func recoverPersistentStore(
        in container: NSPersistentContainer,
        description: NSPersistentStoreDescription,
        originalError: Error
    ) {
        guard let storeURL = description.url else {
            recordPersistentStoreError(originalError, reason: "missing_store_url")
            return
        }

        do {
            try container.persistentStoreCoordinator.destroyPersistentStore(
                at: storeURL,
                ofType: NSSQLiteStoreType,
                options: nil
            )
        } catch {
            recordPersistentStoreError(error, reason: "destroy_failed")
            return
        }

        container.loadPersistentStores { [weak self] _, retryError in
            guard let self, let retryError else { return }
            recordPersistentStoreError(retryError, reason: "retry_load_failed")
        }
    }

    private func recordPersistentStoreError(_ error: Error, reason: String) {
        let crashlytics = Crashlytics.crashlytics()
        crashlytics.setCustomValue(reason, forKey: "core_data_store_error_reason")
        crashlytics.record(error: error)
    }
}

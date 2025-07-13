//
// Created by Banghua Zhao on 02/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import OSLog
import SharingGRDB

private let logger = Logger(subsystem: "Events", category: "Database")

func appDatabase() throws -> any DatabaseWriter {
    @Dependency(\.context) var context

    let database: any DatabaseWriter

    var configuration = Configuration()
    configuration.foreignKeysEnabled = true
    configuration.prepareDatabase { db in
        #if DEBUG
            db.trace(options: .profile) {
                if context == .preview {
                    print($0.expandedDescription)
                } else {
                    logger.debug("\($0.expandedDescription)")
                }
            }
        #endif
    }

    switch context {
    case .live:
        let path = URL.documentsDirectory.appending(component: "db.sqlite").path()
        logger.info("open \(path)")
        database = try DatabasePool(path: path, configuration: configuration)
    case .preview, .test:
        database = try DatabaseQueue(configuration: configuration)
    }

    var migrator = DatabaseMigrator()
    #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
    #endif
    migrator.registerMigration("Create tables") { db in
        try #sql(
            """
            CREATE TABLE "countdowns" (
             "id" INTEGER PRIMARY KEY AUTOINCREMENT, 
             "title" TEXT NOT NULL DEFAULT '', 
             "date" TEXT NOT NULL DEFAULT '', 
             "categoryID" INTEGER REFERENCES "categories"("id") ON DELETE SET NULL,
             "backgroundColor" TEXT NOT NULL DEFAULT '', 
             "textColor" TEXT NOT NULL DEFAULT '', 
             "isFavorite" INTEGER NOT NULL DEFAULT 0, 
             "isArchived" INTEGER NOT NULL DEFAULT 0,
             "repeatType" TEXT NOT NULL DEFAULT 'none',
             "repeatTime" INTEGER NOT NULL DEFAULT 1,
             "backgroundImageName" TEXT,
             "compactTimeUnit" TEXT NOT NULL DEFAULT 'days',
             "layout" TEXT NOT NULL DEFAULT 'middle',
             "reminder" TEXT NOT NULL DEFAULT ''
            ) STRICT 
            """
        )
        .execute(db)

        try #sql(
            """
            CREATE TABLE "categories" ( 
             "id" INTEGER PRIMARY KEY AUTOINCREMENT, 
             "title" TEXT NOT NULL DEFAULT ''
            ) STRICT
            """
        )
        .execute(db)
    }
    
    migrator.registerMigration("Seed") { db in
        try db.seed {
            CategoryStore.seed
            CountdownStore.seedLive
        }
    }
    
    #if DEBUG
        migrator.registerMigration("Seed countdown") { db in
            try db.seed {
                CountdownStore.seedDebug
            }
        }
    #endif

    try migrator.migrate(database)

    return database
}

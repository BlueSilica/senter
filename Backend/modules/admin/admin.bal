import ballerina/sql;
import Backend.database;
import Backend.user;

// Database connection test function
public function testDatabaseConnection() returns json {
    boolean|error result = database:testConnection();
    
    if result is error {
        return {
            "status": "ERROR",
            "message": "Database connection failed",
            "error": result.message()
        };
    }
    
    return {
        "status": "SUCCESS",
        "message": "Database connection successful"
    };
}

// Initialize database tables function
public function initializeDatabaseTables() returns json|error {
    sql:Client dbClient = check database:initDatabase();
    
    // Create tables
    sql:ExecutionResult _ = check user:createUsersTable(dbClient);
    sql:ExecutionResult _ = check user:createSessionsTable(dbClient);
    
    check dbClient.close();
    
    return {
        "status": "SUCCESS",
        "message": "Database tables created successfully",
        "tables": {
            "users": "created",
            "sessions": "created"
        }
    };
}

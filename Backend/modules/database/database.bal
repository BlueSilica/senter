import ballerina/sql;
import ballerinax/postgresql;

// Database configuration type
public type DatabaseConfig record {
    string host;
    int port;
    string database;
    string user;
    string password;
};

// Initialize database connection
public function initDatabase() returns sql:Client|error {
    // Try different password options
    string[] passwords = ["postgres", "", "root", "admin"];
    
    foreach string pwd in passwords {
        DatabaseConfig dbConfig = {
            host: "localhost",
            port: 5432,
            database: "senter",
            user: "postgres",
            password: pwd
        };
        
        postgresql:Client|sql:Error dbClient = new (
            host = dbConfig.host,
            port = dbConfig.port,
            database = dbConfig.database,
            username = dbConfig.user,
            password = dbConfig.password
        );
        
        if dbClient is postgresql:Client {
            return dbClient;
        }
    }
    
    return error("Could not connect to database with any of the tried passwords. Please set a password for postgres user or configure trust authentication.");
}

// Test database connection
public function testConnection() returns boolean|error {
    sql:Client|error dbClientResult = initDatabase();
    if dbClientResult is error {
        return dbClientResult;
    }
    
    sql:Client dbClient = dbClientResult;
    
    // Simple query to test connection
    sql:ParameterizedQuery query = `SELECT 1 as test`;
    stream<record {}, sql:Error?> resultStream = dbClient->query(query);
    
    error? closeResult = resultStream.close();
    if closeResult is error {
        return closeResult;
    }
    
    error? dbCloseResult = dbClient.close();
    if dbCloseResult is error {
        return dbCloseResult;
    }
    
    return true;
}

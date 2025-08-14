import ballerina/sql;
import ballerinax/postgresql;
import ballerina/os;

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
    string portStr = os:getEnv("PORT");
    int|error portResult = int:fromString(portStr);
    if portResult is error {
        return error("Invalid port number: " + portStr);
    }
    
    DatabaseConfig dbConfig = {
        host: os:getEnv("HOST"),
        port: portResult,
        database: os:getEnv("DATABASE"),
        user: os:getEnv("USER"),
        password: os:getEnv("PASSWORD")
    };
    
    postgresql:Client|sql:Error dbClient = new (
        host = dbConfig.host,
        port = dbConfig.port,
        database = dbConfig.database,
        username = dbConfig.user,
        password = dbConfig.password
    );
    
    if dbClient is sql:Error {
        return dbClient;
    }
    
    return dbClient;
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
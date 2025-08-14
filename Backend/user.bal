port ballerina/sql;
import ballerina/crypto;
import ballerina/uuid;
import ballerina/time;

// User record type
public type User record {
    int id?;
    string username;
    string email;
    string password_hash;
    string created_at?;
    string updated_at?;
};

// User registration request
public type UserRegister record {
    string username;
    string email;
    string password;
};

// User login request
public type UserLogin record {
    string email;
    string password;
};

// User response (without password)
public type UserResponse record {
    int id;
    string username;
    string email;
    string created_at;
};

// Session record
public type Session record {
    string session_id;
    int user_id;
    string created_at;
    string expires_at;
};

// Hash password function
function hashPassword(string password) returns string {
    byte[] passwordBytes = password.toBytes();
    byte[] hashedBytes = crypto:hashSha256(passwordBytes);
    return hashedBytes.toBase64();
}

// Verify password function
function verifyPassword(string password, string hashedPassword) returns boolean {
    string inputHash = hashPassword(password);
    return inputHash == hashedPassword;
}

// Create users table
public function createUsersTable(sql:Client dbClient) returns sql:ExecutionResult|error {
    sql:ParameterizedQuery createTableQuery = `
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            email VARCHAR(100) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    `;
    return dbClient->execute(createTableQuery);
}

// Create sessions table
public function createSessionsTable(sql:Client dbClient) returns sql:ExecutionResult|error {
    sql:ParameterizedQuery createTableQuery = `
        CREATE TABLE IF NOT EXISTS sessions (
            session_id VARCHAR(255) PRIMARY KEY,
            user_id INT REFERENCES users(id) ON DELETE CASCADE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP NOT NULL
        )
    `;
    return dbClient->execute(createTableQuery);
}

// Register new user
public function registerUser(sql:Client dbClient, UserRegister userRegister) returns UserResponse|error {
    // Check if user already exists
    sql:ParameterizedQuery checkQuery = `SELECT id FROM users WHERE email = ${userRegister.email} OR username = ${userRegister.username}`;
    stream<record {}, sql:Error?> resultStream = dbClient->query(checkQuery);
    
    record {}? existingUser = check resultStream.next();
    check resultStream.close();
    
    if existingUser is record {} {
        return error("User with this email or username already exists");
    }
    
    // Hash password
    string hashedPassword = hashPassword(userRegister.password);
    
    // Insert new user
    sql:ParameterizedQuery insertQuery = `
        INSERT INTO users (username, email, password_hash) 
        VALUES (${userRegister.username}, ${userRegister.email}, ${hashedPassword})
    `;
    
    sql:ExecutionResult result = check dbClient->execute(insertQuery);
    
    // Get the inserted user
    if result.affectedRowCount > 0 {
        sql:ParameterizedQuery selectQuery = `SELECT id, username, email, created_at FROM users WHERE email = ${userRegister.email}`;
        stream<UserResponse, sql:Error?> selectResult = dbClient->query(selectQuery);
        record {|UserResponse value;|}? userResult = check selectResult.next();
        check selectResult.close();
        
        if userResult is record {|UserResponse value;|} {
            return userResult.value;
        }
    }
    
    return error("Failed to create user");
}

// Login user
public function loginUser(sql:Client dbClient, UserLogin userLogin) returns string|error {
    // Get user by email
    sql:ParameterizedQuery query = `SELECT id, username, email, password_hash FROM users WHERE email = ${userLogin.email}`;
    stream<record {int id; string username; string email; string password_hash;}, sql:Error?> resultStream = dbClient->query(query);
    
    record {|record {int id; string username; string email; string password_hash;} value;|}? result = check resultStream.next();
    check resultStream.close();
    
    if result is () {
        return error("Invalid email or password");
    }
    
    record {int id; string username; string email; string password_hash;} user = result.value;
    
    // Verify password
    if !verifyPassword(userLogin.password, user.password_hash) {
        return error("Invalid email or password");
    }
    
    // Create session
    string sessionId = uuid:createType4AsString();
    time:Utc currentTime = time:utcNow();
    time:Utc expiryTime = time:utcAddSeconds(currentTime, 86400); // 24 hours
    
    sql:ParameterizedQuery sessionQuery = `
        INSERT INTO sessions (session_id, user_id, expires_at) 
        VALUES (${sessionId}, ${user.id}, ${time:utcToString(expiryTime)})
    `;
    
    sql:ExecutionResult|error sessionResult = dbClient->execute(sessionQuery);
    if sessionResult is error {
        return error("Failed to create session");
    }
    
    return sessionId;
}

// Logout user (delete session)
public function logoutUser(sql:Client dbClient, string sessionId) returns boolean|error {
    sql:ParameterizedQuery deleteQuery = `DELETE FROM sessions WHERE session_id = ${sessionId}`;
    sql:ExecutionResult result = check dbClient->execute(deleteQuery);
    return result.affectedRowCount > 0;
}

// Validate session
public function validateSession(sql:Client dbClient, string sessionId) returns UserResponse|error {
    sql:ParameterizedQuery query = `
        SELECT u.id, u.username, u.email, u.created_at 
        FROM users u 
        JOIN sessions s ON u.id = s.user_id 
        WHERE s.session_id = ${sessionId} AND s.expires_at > CURRENT_TIMESTAMP
    `;
    
    stream<UserResponse, sql:Error?> resultStream = dbClient->query(query);
    record {|UserResponse value;|}? result = check resultStream.next();
    check resultStream.close();
    
    if result is record {|UserResponse value;|} {
        return result.value;
    }
    
    return error("Invalid or expired session");
}

// Get user by ID
public function getUserById(sql:Client dbClient, int userId) returns UserResponse|error {
    sql:ParameterizedQuery query = `SELECT id, username, email, created_at FROM users WHERE id = ${userId}`;
    stream<UserResponse, sql:Error?> resultStream = dbClient->query(query);
    
    record {|UserResponse value;|}? result = check resultStream.next();
    check resultStream.close();
    
    if result is record {|UserResponse value;|} {
        return result.value;
    }
    
    return error("User not found");
}

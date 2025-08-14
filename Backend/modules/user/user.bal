import ballerina/sql;
import ballerina/crypto;
import ballerina/uuid;

// User types
public type UserRegister record {
    string username;
    string email;
    string password;
};

public type UserLogin record {
    string username;
    string password;
};

public type UserResponse record {
    int id;
    string username;
    string email;
    string created_at;
};

public type Session record {
    string session_id;
    int user_id;
    string created_at;
};

// Create users table
public function createUsersTable(sql:Client dbClient) returns sql:ExecutionResult|error {
    sql:ParameterizedQuery createUsersQuery = `
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            email VARCHAR(100) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    `;
    
    return dbClient->execute(createUsersQuery);
}

// Create sessions table
public function createSessionsTable(sql:Client dbClient) returns sql:ExecutionResult|error {
    sql:ParameterizedQuery createSessionsQuery = `
        CREATE TABLE IF NOT EXISTS user_sessions (
            session_id VARCHAR(255) PRIMARY KEY,
            user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '24 hours')
        )
    `;
    
    return dbClient->execute(createSessionsQuery);
}

// Hash password
function hashPassword(string password) returns string|error {
    byte[] hashedBytes = crypto:hashSha256(password.toBytes());
    return hashedBytes.toBase16();
}

// Verify password
function verifyPassword(string password, string hashedPassword) returns boolean|error {
    string hashedInput = check hashPassword(password);
    return hashedInput == hashedPassword;
}

// Register user
public function registerUser(sql:Client dbClient, UserRegister userRegister) returns UserResponse|error {
    // Check if user already exists
    sql:ParameterizedQuery checkQuery = `SELECT id FROM users WHERE username = ${userRegister.username} OR email = ${userRegister.email}`;
    stream<record {}, sql:Error?> resultStream = dbClient->query(checkQuery);
    
    record {}|error? existingUser = resultStream.next();
    check resultStream.close();
    
    if existingUser is record {} {
        return error("User with this username or email already exists");
    }
    
    // Hash password
    string hashedPassword = check hashPassword(userRegister.password);
    
    // Insert new user
    sql:ParameterizedQuery insertQuery = `
        INSERT INTO users (username, email, password_hash) 
        VALUES (${userRegister.username}, ${userRegister.email}, ${hashedPassword})
        RETURNING id, username, email, created_at
    `;
    
    stream<UserResponse, sql:Error?> insertStream = dbClient->query(insertQuery);
    record {|UserResponse value;|}|error? result = insertStream.next();
    check insertStream.close();
    
    if result is error {
        return error("Failed to create user");
    }
    
    if result is () {
        return error("No user data returned");
    }
    
    return result.value;
}

// Login user
public function loginUser(sql:Client dbClient, UserLogin userLogin) returns string|error {
    // Get user by username
    sql:ParameterizedQuery userQuery = `
        SELECT id, username, email, password_hash, created_at 
        FROM users 
        WHERE username = ${userLogin.username}
    `;
    
    stream<record {}, sql:Error?> userStream = dbClient->query(userQuery);
    record {}|error? userResult = userStream.next();
    check userStream.close();
    
    if userResult is error {
        return error("Database error occurred");
    }
    
    if userResult is () {
        return error("Invalid username or password");
    }
    
    record {} user = userResult;
    string storedPassword = <string>user["password_hash"];
    
    // Verify password
    boolean passwordValid = check verifyPassword(userLogin.password, storedPassword);
    if !passwordValid {
        return error("Invalid username or password");
    }
    
    // Generate session ID
    string sessionId = uuid:createType1AsString();
    int userId = <int>user["id"];
    
    // Create session
    sql:ParameterizedQuery sessionQuery = `
        INSERT INTO user_sessions (session_id, user_id) 
        VALUES (${sessionId}, ${userId})
    `;
    
    sql:ExecutionResult _ = check dbClient->execute(sessionQuery);
    
    return sessionId;
}

// Validate session and get user
public function validateSession(sql:Client dbClient, string sessionId) returns UserResponse|error {
    sql:ParameterizedQuery sessionQuery = `
        SELECT u.id, u.username, u.email, u.created_at
        FROM users u
        INNER JOIN user_sessions s ON u.id = s.user_id
        WHERE s.session_id = ${sessionId} AND s.expires_at > CURRENT_TIMESTAMP
    `;
    
    stream<UserResponse, sql:Error?> sessionStream = dbClient->query(sessionQuery);
    record {|UserResponse value;|}|error? result = sessionStream.next();
    check sessionStream.close();
    
    if result is error {
        return error("Database error occurred");
    }
    
    if result is () {
        return error("Invalid or expired session");
    }
    
    return result.value;
}

// Logout user
public function logoutUser(sql:Client dbClient, string sessionId) returns boolean|error {
    sql:ParameterizedQuery logoutQuery = `
        DELETE FROM user_sessions 
        WHERE session_id = ${sessionId}
    `;
    
    sql:ExecutionResult result = check dbClient->execute(logoutQuery);
    
    if result.affectedRowCount > 0 {
        return true;
    }
    
    return error("Session not found");
}

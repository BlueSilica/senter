import ballerina/sql;
import Backend.database;
import Backend.user;

// User registration function
public function registerUser(user:UserRegister userRegister) returns json|error {
    sql:Client|error dbClient = database:initDatabase();
    if dbClient is error {
        return error("Database connection failed");
    }
    
    user:UserResponse|error result = user:registerUser(dbClient, userRegister);
    error? closeResult = dbClient.close();
    if closeResult is error {
        // Log the close error but don't fail the operation
    }
    
    if result is error {
        return error(result.message());
    }
    
    json response = {
        "status": "SUCCESS",
        "message": "User registered successfully",
        "user": {
            "id": result.id,
            "username": result.username,
            "email": result.email,
            "created_at": result.created_at
        }
    };
    return response;
}

// User login function
public function loginUser(user:UserLogin userLogin) returns json|error {
    sql:Client|error dbClient = database:initDatabase();
    if dbClient is error {
        return error("Database connection failed");
    }
    
    string|error sessionId = user:loginUser(dbClient, userLogin);
    error? closeResult = dbClient.close();
    if closeResult is error {
        // Log the close error but don't fail the operation
    }
    
    if sessionId is error {
        return error(sessionId.message());
    }
    
    return {
        "status": "SUCCESS",
        "message": "Login successful",
        "session_id": sessionId
    };
}

// User logout function
public function logoutUser(string sessionId) returns json|error {
    sql:Client|error dbClient = database:initDatabase();
    if dbClient is error {
        return error("Database connection failed");
    }
    
    boolean|error result = user:logoutUser(dbClient, sessionId);
    error? closeResult = dbClient.close();
    if closeResult is error {
        // Log the close error but don't fail the operation
    }
    
    if result is error {
        return error(result.message());
    }
    
    return {
        "status": "SUCCESS",
        "message": "Logout successful"
    };
}

// Get user profile function
public function getUserProfile(string sessionId) returns json|error {
    sql:Client|error dbClient = database:initDatabase();
    if dbClient is error {
        return error("Database connection failed");
    }
    
    user:UserResponse|error userResponse = user:validateSession(dbClient, sessionId);
    error? closeResult = dbClient.close();
    if closeResult is error {
        // Log the close error but don't fail the operation
    }
    
    if userResponse is error {
        return error(userResponse.message());
    }
    
    json response = {
        "status": "SUCCESS",
        "user": {
            "id": userResponse.id,
            "username": userResponse.username,
            "email": userResponse.email,
            "created_at": userResponse.created_at
        }
    };
    return response;
}

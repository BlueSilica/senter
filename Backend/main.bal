import ballerina/io;
import ballerina/http;
import Backend.auth;
import Backend.admin;
import Backend.user;

// Main HTTP service with all routes
service / on new http:Listener(8080) {
    
    // Health check endpoint
    resource function get health() returns json {
        return {
            "status": "UP",
            "message": "Backend service is running",
            "version": "1.0.0"
        };
    }
    
    // Auth routes
    resource function post auth/register(@http:Payload user:UserRegister userRegister) returns json|http:BadRequest {
        json|error result = auth:registerUser(userRegister);
        
        if result is error {
            return <http:BadRequest>{
                body: {
                    "status": "ERROR",
                    "message": result.message()
                }
            };
        }
        
        return result;
    }
    
    resource function post auth/login(@http:Payload user:UserLogin userLogin) returns json|http:BadRequest {
        json|error result = auth:loginUser(userLogin);
        
        if result is error {
            return <http:BadRequest>{
                body: {
                    "status": "ERROR",
                    "message": result.message()
                }
            };
        }
        
        return result;
    }
    
    resource function post auth/logout(@http:Header string? authorization) returns json|http:BadRequest {
        if authorization is () {
            return <http:BadRequest>{
                body: {
                    "status": "ERROR",
                    "message": "Authorization header required"
                }
            };
        }
        
        // Extract session ID from Authorization header (Bearer token)
        string sessionId = authorization.substring(7); // Remove "Bearer " prefix
        json|error result = auth:logoutUser(sessionId);
        
        if result is error {
            return <http:BadRequest>{
                body: {
                    "status": "ERROR",
                    "message": result.message()
                }
            };
        }
        
        return result;
    }
    
    resource function get auth/profile(@http:Header string? authorization) returns json|http:BadRequest|http:Unauthorized {
        if authorization is () {
            return <http:Unauthorized>{
                body: {
                    "status": "ERROR",
                    "message": "Authorization header required"
                }
            };
        }
        
        // Extract session ID from Authorization header (Bearer token)
        string sessionId = authorization.substring(7); // Remove "Bearer " prefix
        json|error result = auth:getUserProfile(sessionId);
        
        if result is error {
            return <http:Unauthorized>{
                body: {
                    "status": "ERROR",
                    "message": result.message()
                }
            };
        }
        
        return result;
    }
    
    // Admin routes
    resource function get admin/db/test() returns json {
        return admin:testDatabaseConnection();
    }
    
    resource function post admin/db/init() returns json|http:InternalServerError {
        json|error result = admin:initializeDatabaseTables();
        
        if result is error {
            return <http:InternalServerError>{
                body: {
                    "status": "ERROR",
                    "message": result.message()
                }
            };
        }
        
        return result;
    }
}

public function main() returns error? {
    io:println("🚀 Starting Ballerina Backend Server...");
    io:println("📡 Server running on http://localhost:8080");
    io:println("");
    io:println("📋 Available endpoints:");
    io:println("   ✅ Health check: GET http://localhost:8080/health");
    io:println("");
    io:println("🔐 Authentication endpoints:");
    io:println("   📝 Register: POST http://localhost:8080/auth/register");
    io:println("   🔑 Login: POST http://localhost:8080/auth/login");
    io:println("   🚪 Logout: POST http://localhost:8080/auth/logout");
    io:println("   👤 Profile: GET http://localhost:8080/auth/profile");
    io:println("");
    io:println("⚙️  Admin endpoints:");
    io:println("   🔍 DB test: GET http://localhost:8080/admin/db/test");
    io:println("   🏗️  Initialize DB: POST http://localhost:8080/admin/db/init");
    io:println("");
    io:println("💡 Remember to initialize database tables first!");
}

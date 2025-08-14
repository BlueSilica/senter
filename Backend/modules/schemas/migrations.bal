// Database table creation and migration scripts

import ballerina/sql;

// SQL scripts for table creation
public const string CREATE_USERS_TABLE = string `
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        first_name VARCHAR(50),
        last_name VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
`;

public const string CREATE_POSTS_TABLE = string `
    CREATE TABLE IF NOT EXISTS posts (
        id SERIAL PRIMARY KEY,
        title VARCHAR(200) NOT NULL,
        content TEXT,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
`;

// Function to run database migrations
public function runMigrations(sql:Client dbClient) returns error? {
    // Create users table
    sql:ParameterizedQuery createUsersQuery = `${CREATE_USERS_TABLE}`;
    sql:ExecutionResult|sql:Error result1 = dbClient->execute(createUsersQuery);
    if result1 is sql:Error {
        return error("Failed to create users table: " + result1.message());
    }
    
    // Create posts table
    sql:ParameterizedQuery createPostsQuery = `${CREATE_POSTS_TABLE}`;
    sql:ExecutionResult|sql:Error result2 = dbClient->execute(createPostsQuery);
    if result2 is sql:Error {
        return error("Failed to create posts table: " + result2.message());
    }
    
    return;
}

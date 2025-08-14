// User-related database schemas and types

// User table record type
public type User record {|
    int id?;
    string username;
    string email;
    string password_hash;
    string first_name?;
    string last_name?;
    string created_at?;
    string updated_at?;
|};

// User creation payload (without id and timestamps)
public type UserCreate record {|
    string username;
    string email;
    string password;
    string first_name?;
    string last_name?;
|};

// User update payload
public type UserUpdate record {|
    string username?;
    string email?;
    string first_name?;
    string last_name?;
|};

// User response (without password)
public type UserResponse record {|
    int id;
    string username;
    string email;
    string first_name?;
    string last_name?;
    string created_at?;
    string updated_at?;
|};

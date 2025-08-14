// Post-related database schemas and types

// Post table record type
public type Post record {|
    int id?;
    string title;
    string content?;
    int user_id;
    string created_at?;
    string updated_at?;
|};

// Post creation payload
public type PostCreate record {|
    string title;
    string content?;
    int user_id;
|};

// Post update payload
public type PostUpdate record {|
    string title?;
    string content?;
|};

// Post with user details (for joined queries)
public type PostWithUser record {|
    int id;
    string title;
    string content?;
    int user_id;
    string username;
    string user_email;
    string created_at?;
    string updated_at?;
|};

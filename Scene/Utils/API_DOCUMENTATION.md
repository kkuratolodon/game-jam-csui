# Game Backend API Documentation

This document provides comprehensive information about the Game Backend API endpoints, request/response formats, and authentication requirements.

## Base URL

- Local Development: `http://127.0.0.1:8000`
- Production Server: `http://54.255.152.114`

## Authentication

All API endpoints require a secret key for authentication. Include the following in all request bodies:

```json
{
  "secret": "game-secret-for-api-authentication"
}
```

## API Endpoints

### 1. Register User

Creates a new game user account with default starting values.

- **URL**: `/api/register/`
- **Method**: `POST`
- **Authentication**: Secret key required

**Request Body**:

```json
{
  "username": "player123",
  "display_name": "Awesome Player",
  "password": "securepassword",
  "confirm_password": "securepassword",
  "secret": "game-secret-for-api-authentication"
}
```

**Success Response** (201 Created):

```json
{
  "id": 1,
  "username": "player123",
  "display_name": "Awesome Player",
  "hp": 100,
  "money": 200,
  "last_completed_level": 0,
  "tutorial_complete": false,
  "archer_level": 1,
  "catapult_level": 1,
  "magic_level": 1,
  "guardian_level": 1,
  "created_at": "2025-04-09T10:00:00.000000Z",
  "updated_at": "2025-04-09T10:00:00.000000Z"
}
```

**Error Responses**:

- **400 Bad Request**: Invalid input or passwords don't match
- **403 Forbidden**: Invalid secret key

### 2. Get User Data

Retrieves user data using username and password.

- **URL**: `/api/user-data/`
- **Method**: `POST`
- **Authentication**: Secret key and user credentials required

**Request Body**:

```json
{
  "username": "player123",
  "password": "securepassword",
  "secret": "game-secret-for-api-authentication"
}
```

**Success Response** (200 OK):

```json
{
  "id": 1,
  "username": "player123",
  "display_name": "Awesome Player",
  "hp": 100,
  "money": 200,
  "last_completed_level": 0,
  "tutorial_complete": false,
  "archer_level": 1,
  "catapult_level": 1,
  "magic_level": 1,
  "guardian_level": 1,
  "created_at": "2025-04-09T10:00:00.000000Z",
  "updated_at": "2025-04-09T10:00:00.000000Z"
}
```

**Error Responses**:

- **400 Bad Request**: Missing username or password
- **401 Unauthorized**: Invalid credentials
- **403 Forbidden**: Invalid secret key

### 3. Update User Data

Updates user data including game progress and resources.

- **URL**: `/api/update-user/`
- **Method**: `PUT`
- **Authentication**: Secret key and user credentials required

**Request Body** (include only fields to update):

```json
{
  "username": "player123",
  "password": "securepassword",
  "secret": "game-secret-for-api-authentication",
  
  // Optional fields to update (include only what needs to be changed)
  "display_name": "New Display Name",
  "new_username": "newusername", // To change the username
  "hp": 150,
  "money": 500,
  "last_completed_level": 3,
  "tutorial_complete": true,
  "archer_level": 2,
  "catapult_level": 3,
  "magic_level": 2,
  "guardian_level": 2
}
```

**Success Response** (200 OK):

```json
{
  "id": 1,
  "username": "newusername", // If username was changed
  "display_name": "New Display Name",
  "hp": 150,
  "money": 500,
  "last_completed_level": 3,
  "tutorial_complete": true,
  "archer_level": 2,
  "catapult_level": 3,
  "magic_level": 2,
  "guardian_level": 2,
  "created_at": "2025-04-09T10:00:00.000000Z",
  "updated_at": "2025-04-09T11:30:00.000000Z"
}
```

**Error Responses**:

- **400 Bad Request**: Missing username or password, or invalid data
- **401 Unauthorized**: Invalid credentials
- **403 Forbidden**: Invalid secret key

## Data Models

### Game User

| Field               | Type      | Default    | Description                                |
|---------------------|-----------|------------|--------------------------------------------|
| username            | String    | (required) | Unique user identifier                     |
| display_name        | String    | "Player"   | Display name shown in the game             |
| hp                  | Integer   | 100        | Player health points                       |
| money               | Integer   | 200        | Player in-game currency                    |
| last_completed_level| Integer   | 0          | Highest level player has completed         |
| tutorial_complete   | Boolean   | false      | Whether player has completed the tutorial  |
| archer_level        | Integer   | 1          | Archer unit upgrade level                  |
| catapult_level      | Integer   | 1          | Catapult unit upgrade level                |
| magic_level         | Integer   | 1          | Magic unit upgrade level                   |
| guardian_level      | Integer   | 1          | Guardian unit upgrade level                |
| created_at          | DateTime  | (auto)     | Account creation timestamp                 |
| updated_at          | DateTime  | (auto)     | Last update timestamp                      |

## Integration with Game Client

### Godot Engine Integration Example

```gdscript
extends Node

const API_URL = "http://54.255.152.114"
const SECRET_KEY = "game-secret-for-api-authentication"

# Register a new user
func register_user(username, display_name, password, confirm_password):
    var http_request = HTTPRequest.new()
    add_child(http_request)
    
    var body = {
        "username": username,
        "display_name": display_name,
        "password": password,
        "confirm_password": confirm_password,
        "secret": SECRET_KEY
    }
    
    var json = JSON.stringify(body)
    var headers = ["Content-Type: application/json"]
    
    http_request.request(
        API_URL + "/api/register/",
        headers,
        HTTPClient.METHOD_POST,
        json
    )
    
    # Handle response in _on_http_request_completed

# Get user data
func get_user_data(username, password):
    var http_request = HTTPRequest.new()
    add_child(http_request)
    
    var body = {
        "username": username,
        "password": password,
        "secret": SECRET_KEY
    }
    
    var json = JSON.stringify(body)
    var headers = ["Content-Type: application/json"]
    
    http_request.request(
        API_URL + "/api/user-data/",
        headers,
        HTTPClient.METHOD_POST,
        json
    )
    
    # Handle response in _on_http_request_completed

# Update user data
func update_user_data(username, password, data_to_update):
    var http_request = HTTPRequest.new()
    add_child(http_request)
    
    var body = {
        "username": username,
        "password": password,
        "secret": SECRET_KEY
    }
    
    # Add fields to update
    for key in data_to_update:
        body[key] = data_to_update[key]
    
    var json = JSON.stringify(body)
    var headers = ["Content-Type: application/json"]
    
    http_request.request(
        API_URL + "/api/update-user/",
        headers,
        HTTPClient.METHOD_PUT,
        json
    )
    
    # Handle response in _on_http_request_completed

# Handle the HTTP response
func _on_http_request_completed(result, response_code, headers, body):
    var json = JSON.parse_string(body.get_string_from_utf8())
    
    if response_code == 200 or response_code == 201:
        # Success - handle the data
        print("Success: ", json)
    else:
        # Error - handle accordingly
        print("Error: ", json)
```

## Security Considerations

1. Always use HTTPS in production
2. Keep the secret key secure and don't expose it in client-side code
3. Consider implementing rate limiting on the API
4. Regularly rotate the secret key
5. Implement proper error handling in the client

## Troubleshooting

### Common Issues

1. **"Invalid secret key" error**: Ensure the correct secret key is included in all API requests
2. **"Invalid credentials" error**: Verify the username and password combination
3. **"Passwords don't match" error**: Ensure password and confirm_password are identical during registration
4. **Connection timeout**: Check if the server is running and the network connection is stable

## Deployment Notes

The API is currently deployed on AWS EC2 at IP address: 54.255.152.114

For any questions or issues, contact the development team.
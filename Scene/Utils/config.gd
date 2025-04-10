extends Node

const API_URL = "http://54.255.152.114"
const SECRET_KEY = "game-secret-for-api-authentication"
const USE_LOCAL_DEV = false # Set to true when testing with local server

var start_hp := 100
var start_money := 200
var archer_start_level = 1
var catapult_start_level = 1
var magic_start_level = 1
var guardian_start_level = 1

# User data from server
var user_data = null
var username = ""
var password = ""

var base_url
signal user_data_updated

func _ready():
    if USE_LOCAL_DEV:
        base_url = "http://127.0.0.1:8000"
    fetch_config()
    
func fetch_config():
    # Try to load cached user data if available
    var saved_username = get_saved_username()
    var saved_password = get_saved_password()
    
    if saved_username != "" and saved_password != "":
        get_user_data(saved_username, saved_password)
    
func get_base_url() -> String:
    return "http://127.0.0.1:8000" if USE_LOCAL_DEV else API_URL

func register_user(username, display_name, password, confirm_password):
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_register_completed)
    
    var body = {
        "username": username,
        "display_name": display_name,
        "password": password,
        "confirm_password": confirm_password,
        "secret": SECRET_KEY
    }
    
    var json = JSON.stringify(body)
    var headers = ["Content-Type: application/json"]
    
    var error = http_request.request(
        get_base_url() + "/api/register/",
        headers,
        HTTPClient.METHOD_POST,
        json
    )
    
    if error != OK:
        push_error("An error occurred in the HTTP request: " + str(error))
        return false
    
    return true

func get_user_data(username, password):
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_user_data_completed)
    
    var body = {
        "username": username,
        "password": password,
        "secret": SECRET_KEY
    }
    print(body)
    var json = JSON.stringify(body)
    var headers = ["Content-Type: application/json"]
    
    var error = http_request.request(
        get_base_url() + "/api/user-data/",
        headers,
        HTTPClient.METHOD_POST,
        json
    )
    print("konz")
    print(error)
    
    if error != OK:
        push_error("An error occurred in the HTTP request: " + str(error))
        return false
    save_credentials(username, password)
    return true

func update_user_data(data_to_update):
    if !username or !password:
        print("username or password not set")
        push_error("Username or password not set")
        return false
        
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_update_completed)
    
    var body = {
        "username": username,
        "password": password,
        "secret": SECRET_KEY
    }
    
    # Add fields to update
    for key in data_to_update:
        body[key] = data_to_update[key]
    print(body)
    var json = JSON.stringify(body)
    var headers = ["Content-Type: application/json"]
    
    var error = http_request.request(
        get_base_url() + "/api/update-user/",
        headers,
        HTTPClient.METHOD_PUT,
        json
    )
    
    if error != OK:
        print(error)
        push_error("An error occurred in the HTTP request: " + str(error))
        return false
    
    return true

func update_tutorial_completed(completed):
    print(completed)
    return update_user_data({"tutorial_complete": completed})
    
func update_level_completed(level):
    return update_user_data({"last_completed_level": level})

func update_tower_levels(archer_level, catapult_level, magic_level, guardian_level):
    return update_user_data({
        "archer_level": archer_level,
        "catapult_level": catapult_level,
        "magic_level": magic_level,
        "guardian_level": guardian_level
    })

func save_credentials(new_username, new_password):
    self.username = new_username
    self.password = new_password
    # Save to config file or encrypted storage in a real game
    var config = ConfigFile.new()
    config.set_value("user", "username", new_username)
    config.set_value("user", "password", new_password) # In a real game, encrypt this!
    config.save("user://credentials.cfg")

func get_saved_username() -> String:
    var config = ConfigFile.new()
    var err = config.load("user://credentials.cfg")
    if err != OK:
        return ""
    return config.get_value("user", "username", "")
    
func get_saved_password() -> String:
    var config = ConfigFile.new()
    var err = config.load("user://credentials.cfg")
    if err != OK:
        return ""
    return config.get_value("user", "password", "")

func clear_saved_credentials():
    var dir = DirAccess.open("user://")
    if dir and dir.file_exists("credentials.cfg"):
        dir.remove("credentials.cfg")
    username = ""
    password = ""

func _on_register_completed(result, response_code, headers, body):
    if response_code == 201:
        var json = JSON.parse_string(body.get_string_from_utf8())
        if json:
            user_data = json
            # Update local config values
            _update_local_config()
            print("Successfully registered new user")
            user_data_updated.emit()
    else:
        var error_text = body.get_string_from_utf8()
        push_error("Registration failed. Response code: " + str(response_code) + ", Error: " + error_text)

func _on_user_data_completed(result, response_code, headers, body):
    print("Response code: ", response_code)
    print("Response body: ", body.get_string_from_utf8())
    
    if response_code == 200:
        var json = JSON.parse_string(body.get_string_from_utf8())
        if json:
            print("Parsed JSON: ", json)
            user_data = json
            # Update local config values
            _update_local_config()
            print("User data loaded from API")
            user_data_updated.emit()
        
    elif response_code == 401:
        # Specific handling for authentication failure
        push_error("Authentication failed: Invalid username or password")
        user_data = null
        user_data_updated.emit()
    else:
        var error_text = body.get_string_from_utf8()
        push_error("Failed to get user data. Response code: " + str(response_code) + ", Error: " + error_text)
        user_data = null
        user_data_updated.emit()

func _on_update_completed(result, response_code, headers, body):
    if response_code == 200:
        var json = JSON.parse_string(body.get_string_from_utf8())
        if json:
            user_data = json
            # Update local config values
            _update_local_config()
            print("User data updated successfully")
            user_data_updated.emit()
    else:
        var error_text = body.get_string_from_utf8()
        push_error("Failed to update user data. Response code: " + str(response_code) + ", Error: " + error_text)

func _update_local_config():
    if user_data:
        start_hp = user_data.get("hp", start_hp)
        start_money = user_data.get("money", start_money)
        archer_start_level = user_data.get("archer_level", archer_start_level)
        catapult_start_level = user_data.get("catapult_level", catapult_start_level)
        magic_start_level = user_data.get("magic_level", magic_start_level)
        guardian_start_level = user_data.get("guardian_level", guardian_start_level)

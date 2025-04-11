extends Node

const API_URL = "http://54.255.152.114"
const SECRET_KEY = "game-secret-for-api-authentication"
const USE_LOCAL_DEV = false # Set to true when testing with local server

var start_hp_level := 1
var start_money_level := 1
var archer_start_level = 1
var catapult_start_level = 1
var magic_start_level = 1
var guardian_start_level = 1
var start_money = 200
var start_hp = 100
var money = 0

# Dictionaries mapping upgrade levels to actual values
const MONEY_LEVEL_VALUES = {
    1: 200,  # Level 1: 200 starting money
    2: 250,  # Level 2: 250 starting money
    3: 300,  # Level 3: 300 starting money
    4: 350,  # Level 4: 350 starting money
    5: 400   # Level 5: 400 starting money
}

const HP_LEVEL_VALUES = {
    1: 100,  # Level 1: 100 starting HP
    2: 120,  # Level 2: 120 starting HP
    3: 140,  # Level 3: 140 starting HP
    4: 160,  # Level 4: 160 starting HP
    5: 200   # Level 5: 200 starting HP
}

# User data from server
var user_data = null
var username = ""
var password = ""

var base_url
signal user_data_updated

# Add these variables for caching
var local_data_loaded = false
var last_fetch_time = 0
const CACHE_FILE_PATH = "user://user_data_cache.cfg"
const FETCH_COOLDOWN = 60 # 60 seconds between server fetches

func _ready():
    if USE_LOCAL_DEV:
        base_url = "http://127.0.0.1:8000"
    fetch_config()
    
# Helper function to get the actual money value based on level
func get_money_for_level(level):
    return MONEY_LEVEL_VALUES.get(level, MONEY_LEVEL_VALUES[1])
    
# Helper function to get the actual HP value based on level
func get_hp_for_level(level):
    return HP_LEVEL_VALUES.get(level, HP_LEVEL_VALUES[1])

# Function to update the start_money and start_hp based on their levels
func update_start_values():
    start_money = get_money_for_level(start_money_level)
    start_hp = get_hp_for_level(start_hp_level)

func fetch_config():
    # First try to load from local cache
    load_cached_user_data()
    
    # Try to load cached user data if available
    var saved_username = get_saved_username()
    var saved_password = get_saved_password()
    
    if saved_username != "" and saved_password != "":
        # Only fetch from server if cooldown period has passed
        var current_time = Time.get_unix_time_from_system()
        if current_time - last_fetch_time > FETCH_COOLDOWN:
            get_user_data(saved_username, saved_password)
            last_fetch_time = current_time

func load_cached_user_data():
    var config = ConfigFile.new()
    var err = config.load(CACHE_FILE_PATH)
    
    if err != OK:
        print("No cached user data found")
        return false
    
    # Load user data from cache
    var cached_data = config.get_value("cache", "user_data", null)
    if cached_data:
        print("Loaded user data from cache")
        user_data = cached_data
        _update_local_config()
        local_data_loaded = true
        user_data_updated.emit()
        return true
    
    return false

func save_cached_user_data():
    if user_data == null:
        return
    
    var config = ConfigFile.new()
    config.set_value("cache", "user_data", user_data)
    config.set_value("cache", "timestamp", Time.get_unix_time_from_system())
    var err = config.save(CACHE_FILE_PATH)
    
    if err != OK:
        push_error("Failed to save user data cache")
    else:
        print("User data cached successfully")

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
            # Save to local cache
            save_cached_user_data()
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
            # Save to local cache
            save_cached_user_data()
            print("User data updated successfully")
            user_data_updated.emit()
    else:
        var error_text = body.get_string_from_utf8()
        push_error("Failed to update user data. Response code: " + str(response_code) + ", Error: " + error_text)

func _update_local_config():
    if user_data:
        money = user_data.get("money", guardian_start_level)
        start_hp_level = user_data.get("start_hp", start_hp_level)
        start_money_level = user_data.get("start_money", start_money_level)
        archer_start_level = user_data.get("archer_level", archer_start_level)
        catapult_start_level = user_data.get("catapult_level", catapult_start_level)
        magic_start_level = user_data.get("magic_level", magic_start_level)
        guardian_start_level = user_data.get("guardian_level", guardian_start_level)
        # Update the actual values based on levels
        update_start_values()

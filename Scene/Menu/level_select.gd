extends Control

func _ready():
    # Check if we need to update tutorial completion
    if Engine.has_singleton("GlobalFlags"):
        var flags = Engine.get_singleton("GlobalFlags")
        if flags.has_method("get") and flags.get("tutorial_just_completed"):
            _update_tutorial_completion()
            flags.set("tutorial_just_completed", false)
    
    # Continue with normal initialization
    _initialize_level_select()

func _update_tutorial_completion():
    print("Level select detected tutorial was just completed")
    
    # Get the credentials from the current login
    var config = Config
    if config and config.user_data:
        # We should have valid credentials at this point because we just logged in
        if not config.username.is_empty() and not config.password.is_empty():
            print("Updating tutorial completion status with valid credentials")
            var success = config.update_tutorial_completed(true)
            if success:
                print("Tutorial completion status update sent successfully")
            else:
                print("Failed to send tutorial completion update request")
        else:
            print("ERROR: Missing credentials in Config singleton")
            print("Username empty: ", config.username.is_empty())
            print("Password empty: ", config.password.is_empty())
    else:
        print("ERROR: Config singleton or user_data not available")

func _initialize_level_select():
    # Your original level select initialization code here
    print("Level select initialized")

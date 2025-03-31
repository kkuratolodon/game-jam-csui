extends Node

var start_hp := 100
var start_money := 100

func _ready():
    fetch_config()
    
func fetch_config():
    pass
    # var http_request = HTTPRequest.new()
    # add_child(http_request)
    # http_request.request_completed.connect(self._on_request_completed)
    
    # # Replace with your API endpoint
    # var error = http_request.request("https://your-api.com/config")
    # if error != OK:
    #   push_error("An error occurred in the HTTP request.")

func _on_request_completed(result, response_code, headers, body):
    pass
    # if response_code == 200:
    #     var json = JSON.parse_string(body.get_string_from_utf8())
    #     if json:
    #         start_hp = json.get("start_hp", start_hp)
    #         start_money = json.get("start_money", start_money)
    #         print("Config loaded from API")
    # else:
    #     push_error("Failed to get config data. Response code: " + str(response_code))
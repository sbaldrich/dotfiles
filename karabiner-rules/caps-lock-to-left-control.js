{
    "description": "caps_lock → control/escape, escape → caps_lock",
    "manipulators": [
        {
            "from": {
                "key_code": "caps_lock",
                "modifiers": { "optional": ["any"] }
            },
            "to": [{ "key_code": "left_control" }],
            "to_if_alone": [{ "key_code": "escape" }],
            "type": "basic"
        },
        {
            "from": {
                "key_code": "escape",
                "modifiers": { "optional": ["any"] }
            },
            "to": [
                {
                    "hold_down_milliseconds": 200,
                    "key_code": "caps_lock"
                }
            ],
            "type": "basic"
        }
    ]
}
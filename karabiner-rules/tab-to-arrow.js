{
    "description": "Tab + h/j/k/l → arrow keys (tab alone sends tab)",
    "manipulators": [
        {
            "from": {
                "key_code": "tab",
                "modifiers": { "optional": ["any"] }
            },
            "to": [
                {
                    "set_variable": {
                        "name": "tab_nav_mode",
                        "value": 1
                    }
                }
            ],
            "to_after_key_up": [
                {
                    "set_variable": {
                        "name": "tab_nav_mode",
                        "value": 0
                    }
                }
            ],
            "to_if_alone": [{ "key_code": "tab" }],
            "type": "basic"
        },
        {
            "conditions": [
                {
                    "name": "tab_nav_mode",
                    "type": "variable_if",
                    "value": 1
                }
            ],
            "from": {
                "key_code": "h",
                "modifiers": { "optional": ["any"] }
            },
            "to": [{ "key_code": "left_arrow" }],
            "type": "basic"
        },
        {
            "conditions": [
                {
                    "name": "tab_nav_mode",
                    "type": "variable_if",
                    "value": 1
                }
            ],
            "from": {
                "key_code": "j",
                "modifiers": { "optional": ["any"] }
            },
            "to": [{ "key_code": "down_arrow" }],
            "type": "basic"
        },
        {
            "conditions": [
                {
                    "name": "tab_nav_mode",
                    "type": "variable_if",
                    "value": 1
                }
            ],
            "from": {
                "key_code": "k",
                "modifiers": { "optional": ["any"] }
            },
            "to": [{ "key_code": "up_arrow" }],
            "type": "basic"
        },
        {
            "conditions": [
                {
                    "name": "tab_nav_mode",
                    "type": "variable_if",
                    "value": 1
                }
            ],
            "from": {
                "key_code": "l",
                "modifiers": { "optional": ["any"] }
            },
            "to": [{ "key_code": "right_arrow" }],
            "type": "basic"
        }
    ]
}
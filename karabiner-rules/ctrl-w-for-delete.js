{
  "description": "Ctrl+H → Backspace, Ctrl+W → delete word (except terminals)",
  "manipulators": [
    {
      "type": "basic",
      "from": { "key_code": "h", "modifiers": { "mandatory": ["control"] } },
      "to": [{ "key_code": "delete_or_backspace" }]
    },
    {
      "type": "basic",
      "from": { "key_code": "w", "modifiers": { "mandatory": ["control"] } },
      "to": [{ "key_code": "delete_or_backspace", "modifiers": ["left_option"] }],
      "conditions": [
        {
          "type": "frontmost_application_unless",
          "bundle_identifiers": [
            "^com\\.apple\\.Terminal$",
            "^com\\.googlecode\\.iterm2$",
            "^net\\.kovidgoyal\\.kitty$",
            "^com\\.mitchellh\\.ghostty$",
            "^io\\.alacritty$",
            "^dev\\.warp\\.Warp-Stable$"
          ]
        }
      ]
    }
  ]
}
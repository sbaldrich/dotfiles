// JavaScript should be written in ECMAScript 5.1.

function main() {
  return {
    description: 'Exchange numbers and symbols (1234567890 and !@#$%^&*()), unless caps lock is on',
    description_notes: ['- Available since Karabiner-Elements 16.0.0.'],
    maintainers: ['tekezo'],
    manipulators: manipulators(),
  }
}

function manipulators() {
  const result = []
  const numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']

  numbers.forEach(function (key) {
    // While caps lock is on, leave the number row alone (digits without shift,
    // symbols with shift). Manipulators are matched in order, so this has to
    // come before the exchange below.
    result.push({
      type: 'basic',
      from: {
        key_code: key,
        modifiers: {
          mandatory: ['caps_lock'],
          optional: ['shift'],
        },
      },
      to: [
        {
          key_code: key,
        },
      ],
    })

    result.push({
      type: 'basic',
      from: {
        key_code: key,
      },
      to: [
        {
          key_code: key,
          modifiers: ['left_shift'],
        },
      ],
    })

    result.push({
      type: 'basic',
      from: {
        key_code: key,
        modifiers: {
          mandatory: ['shift'],
        },
      },
      to: [
        {
          key_code: key,
        },
      ],
    })
  })

  return result
}

main()
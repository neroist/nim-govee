# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import std/[
  unittest,
  random,
  colors,
  os
]

import govee

test "raises errors":
  expect GoveeAuthorizationError:
    discard initGovee("Invalid Api Key")
    discard initGovee("")

suite "Test Values":
  # Note: I use sleep here to give the device time to change.
  # Also, I might get rate limited 😅
  
  setup:
    {.fatal: "To run these tests, please put your Govee API key in and comment this line".}

    let 
      acc = initGovee("<your-govee-api-key-here>")
      dev = acc[0]

    randomize()

  test "color":
    let color = rgb(rand(255), rand(255), rand(255))

    acc.setColor(dev, color)
    sleep 2000

    check acc.getColor(dev) == color

  test "color temp":
    acc.setColorTemp(dev, 5640)
    sleep 2000
    check acc.getColorTemp(dev) == 5640

  test "brightness":
    let brightness = rand(1..100) / 100

    acc.setBrightness(dev, brightness)
    sleep 2000
    check acc.getBrightness(dev) == brightness

  test "power states":
    acc.turn(dev, off)
    sleep 2000

    check acc.getPowerState(dev) == false

  test "online-ness":
    check acc.isOnline(dev)
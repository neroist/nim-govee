## Govee device commands

import private/consts
import errors
import types

import std/[
  httpclient,
  colors,
  json,
  uri
]

# --- helpers---
{.push inline.}

func contructUri(base: Uri = StateUri; device: GoveeDevice): Uri =
  base ? {"device": device.address, "model": device.model}

func setClientHeaders(client: var HttpClient, govee: Govee) =
  client.headers = newHttpHeaders(
    {"Govee-API-Key": govee.apiKey, "Content-Type": "application/json"}
  )

{.pop.}

# --- Color ---
proc getColor*(govee: Govee; device: GoveeDevice): Color = 
  ## Get `device`'s color
  ## 
  ## .. warning:: This may return a blank color (#000000). This is because the API sometimes does not \
  ## provide the device's color.
  
  var client = newHttpClient()
  
  client.setClientHeaders(govee)

  let
    resp = client.get(contructUri(device=device))
    jresp = parseJson resp.body

  raiseErrors(resp)
  
  let jcolor = try: 
    jresp["data"]["properties"][3]["color"]
  except KeyError:
    %* {"r": 0, "g": 0, "b": 0}

  return rgb(jcolor["r"].getInt, jcolor["g"].getInt, jcolor["b"].getInt)

proc setColor*(govee: Govee; device: GoveeDevice; color: Color) = 
  ## Set `device`'s color to `color`

  var client = newHttpClient()
  client.setClientHeaders(govee)

  let
    ec = color.extractRGB

    body = %*{
      "device": device.address,
      "model": device.model,
      "cmd": {
        "name": "color",
        "value": {
          "r": ec.r,
          "g": ec.g,
          "b": ec.b
        }
      }
    }

  let
    resp = client.put(ControlUri, $body)

  raiseErrors(resp)


# --- Brightness ---
proc getBrightness*(govee: Govee; device: GoveeDevice): float =
  ## Returns `device`'s brightness as a percentage (e.g. 56% brightness is 0.56)
  ## 
  ## .. warning:: This may return 0, as the device may not support retriving \
  ## brightness

  var client = newHttpClient()
  client.setClientHeaders(govee)

  let
    resp = client.get(contructUri(device=device))
    jresp = parseJson resp.body

  raiseErrors(resp)

  try:
    jresp["data"]["properties"][2]["brightness"].getInt() / 100
  except KeyError:
    0.0

proc setBrightness*(govee: Govee; device: GoveeDevice; brightness: float) = 
  ## Sets `devices`'s brightness to `brightness`.
  ## 
  ## .. note:: `brightness` is a percentage (e.g. 73% brightness is 0.73)
  
  var client = newHttpClient()
  client.setClientHeaders(govee)

  let
    brightness = int(brightness.clamp(0.0, 1.0) * 100)

  let
    body = %* {
      "device": device.address,
      "model": device.model,
      "cmd": {
        "name": "brightness",
        "value": brightness
      }
    }

    resp = client.put(ControlUri, $body)

  raiseErrors(resp)


# --- Power State ---
proc getPowerState*(govee: Govee; device: GoveeDevice): bool =
  ## Returns the device's power state (i.e. whether the device is on or off)
  
  var client = newHttpClient()
  client.setClientHeaders(govee)

  let
    resp = client.get(contructUri(device=device))
    jresp = parseJson resp.body

  raiseErrors(resp)

  return jresp["data"]["properties"][1]["powerState"].str == "on"

proc setPowerState*(govee: Govee; device: GoveeDevice; state: bool) =
  ## Set `device`'s power state (i.e. whether the device is on or off) to `state`

  var client = newHttpClient()
  client.setClientHeaders govee

  let
    body = %* {
      "device": device.address,
      "model": device.model,
      "cmd": {
        "name": "turn",
        "value": if state: "on" else: "off"
      }
    }

    resp = client.put(ControlUri, $body)

  raiseErrors(resp)

proc turn*(govee: Govee; device: GoveeDevice; state: bool) = 
  ## Alias for `setPowerState`
  govee.setPowerState(device, state)
  
# --- Color Temp ---
proc getColorTemp*(govee: Govee; device: GoveeDevice): int = 
  ## Returns `device`'s color temperature in kelvin
  ## 
  ## .. warning:: This may return 0K. This is because the API sometimes does not \
  ## provide the device's color temperature.
  
  var client = newHttpClient()
  client.setClientHeaders(govee)

  let
    resp = client.get(contructUri(device=device))
    jresp = parseJson resp.body

  raiseErrors(resp)

  let temp = try:
    jresp["data"]["properties"][3]["colorTemInKelvin"].getInt
  except KeyError:
    0

  return temp

proc setColorTemp*(govee: Govee; device: GoveeDevice; temp: int) = 
  ## Set `device`'s color temperature to `temp` in kelvin

  var client = newHttpClient()
  client.setClientHeaders(govee)

  let
    body = %* {
      "device": device.address,
      "model": device.model,
      "cmd": {
        "name": "colorTem",
        "value": temp
      }
    }

    resp = client.put(ControlUri, $body)

  raiseErrors(resp)

# --- Others ---
proc isOnline*(govee: Govee; device: GoveeDevice): bool = 
  ## Returns whether or not the device is online or not
  ## 
  ## .. warning:: Sometimes this may return the wrong state. The Govee API docs state:
  ## 
  ##  "'online' is implemented through the cache. Sometimes it may
  ##  return wrong state. We suggest the third-party developers to ensure that
  ##  even if online returns 'false', the users are allowed to send control
  ##  commands, then even if there the cache is wrong, the users can still control
  ##  the device."

  var client = newHttpClient()
  client.setClientHeaders(govee)

  let
    resp = client.get(contructUri(device=device))
    jresp = parseJson resp.body

  raiseErrors(resp)

  return jresp["data"]["properties"][0]["online"].bval

proc getInfo*(govee: Govee; device: GoveeDevice): tuple[
  online, powerState: bool; 
  brightness, colorTemp: int;
  color: Color
] = 
  ## Get all device information as a tuple.
  ## 
  ## .. warning:: brightness, colorTemp, and color may be 0 or a blank color.
  var client = newHttpClient()
  client.setClientHeaders(govee)

  let
    resp = client.get(contructUri(device=device))
    properties = parseJson(resp.body)["data"]["properties"]

  raiseErrors(resp)

  result.online = properties[0]["online"].getStr == "true"
  result.powerState = properties[1]["powerState"].getStr == "on"

  result.brightness = try: 
    properties[2]["brightness"].getInt
  except KeyError: 
    0

  result.colorTemp = try:
    properties[3]["colorTemInKelvin"].getInt
  except KeyError:
    0

  result.color = try:
    let jcolor = properties[3]["color"]
    rgb(jcolor["r"].getInt, jcolor["g"].getInt, jcolor["b"].getInt)
  except KeyError:
    parseColor("#000000")

when isMainModule:
  let me = initGovee("86f2c216-e4f1-4a89-b2ec-678f604efae5")
  me.setBrightness(me[0], 100.0)


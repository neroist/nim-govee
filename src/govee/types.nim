## Implements Govee types
import errors
import private/consts

import std/[
  httpclient,
  json
]

type
  GoveeDevice* = ref object          ## This object represents Govee device

    address*: string                 ## The mac address of the device
    model*: string                   ## The device model 
    name*: string                    ## The name of the device
    controllable*: bool              ## Whether or not the device can be controlled through the API
    retrievable*: bool               ## Whether or not the device's state can be queried through the API
    supportedCommands*: seq[string]  ## The list of commands the device supports

  Govee* = object               ## This object represents a Govee account

    apiKey*: string             ## The account's API key
    lenDevices*: int            ## How many devices are in the account
    devices*: seq[GoveeDevice]  ## THe list of devices in the account
  

# ---- Operators ----
# GoveeDevice operators
func `==`*(device1, device2: GoveeDevice): bool = 
  ## Checks two GoveeDevice's equality.

  (device1.address == device2.address) and (device1.model == device2.model)

func `$`*(device: GoveeDevice): string =
  ## Converts `device` into a string. Returns `device`'s name. 
  device.name

# Govee operators
func `==`*(acc1, acc2: Govee): bool = 
  ## Checks two Govee objects' equality.

  acc1.apiKey == acc2.apiKey

func `[]`*(acc: Govee; idx: int): GoveeDevice = 
  ## Get a device by its index. Short for `acc.devices[idx]`
  ## 
  ## See also:
  ## * `getDevice func<getDevice,Govee,int>`_
  acc.devices[idx]

# ----- Contructors -----
proc newGoveeDevice(data: JsonNode): GoveeDevice = 
  ## Create a new GoveeDevice with the json data given. Only used internally
  
  # assume correct information was given
  new result # GoveeDevice is a reference object

  result.address = data["device"].str
  result.model = data["model"].str
  result.name = data["deviceName"].str
  result.controllable = data["controllable"].bval
  result.retrievable = data["retrievable"].bval
  
  for cmd in data["supportCmds"]:
    result.supportedCommands.add cmd.str

proc initGovee*(apiKey: string): Govee = 
  ## Initialize a new Govee account

  var 
    client = newHttpClient()
  
  client.headers = newHttpHeaders({"Govee-API-Key": apiKey})

  let 
    resp = client.get(DevicesURI)
    jresp = parseJson resp.body

  # check for errors, if there are any, raise them
  raiseErrors(resp)

  result.apiKey = apiKey

  for device in jresp["data"]["devices"]:
    result.devices.add newGoveeDevice(device)

  result.lenDevices = len result.devices

# ----- Methods -----
proc update*(govee: var Govee) = 
  ## Update a Govee account's information

  govee = initGovee(govee.apiKey)

proc contains*(govee: Govee, device: GoveeDevice): bool {.noSideEffect.} = 
  ## Impl for `in` and `notin` operators.
  ## Returns if `device` is in `govee`'s list of devices.
  device in govee.devices

iterator items*(govee: Govee): GoveeDevice {.noSideEffect.} = 
  for device in govee.devices:
    yield device

iterator pairs*(govee: Govee): tuple[a: int, b: GoveeDevice] {.noSideEffect.} = 
  for idx, device in govee.devices:
    yield (idx, device)

func getDevice*(govee: Govee; idx: int): GoveeDevice = 
  ## Get a device by its index. 
  ## 
  ## See also:
  ## * `[] func<#%5B%5D,Govee,int>`_

  govee.devices[idx]

export 
  GoveeError,
  GoveeAuthorizationError,
  GoveeInternalError,
  GoveeRateLimitedError,
  GoveeCommandNotSupportedError
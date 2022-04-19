# This does not actually compile.

## Govee API wrapper
## 
## :Author: Grace (https://github.com/nonimportant)
## :Version: 1.0.0
## 
## .. Tip:: See the Govee API docs for more info: \
## https://govee-public.s3.amazonaws.com/developer-docs/GoveeDeveloperAPIReference.pdf
## 
## This module allows you to use the Govee API with Nim programmatically, instead
## of using http client and implementing it yourself. This includes querying device 
## state, controlling devices, and getting device information.
## 
## .. Note:: When compiling use `-d:ssl` since this module depends on `std/httpclient`

##[
  # Getting device information
]##

runnableExamples "-d:ssl":

  let
    myacc = initGovee("YOUR-API-KEY-HERE")
    mydevice = myacc[0] # get the first device in the account

  echo mydevice.retrievable # Prints if the device state can be queried via the api
  echo mydevice.controllable # Prints if the device can be controlled via the api
  echo mydevice.address # Prints the device's mac address
  echo mydevice.model # Prints the device's model (e.g. "H6195")
  echo mydevice.name # Prints device name
  echo mydevice.supportedCommands # seq of the device's supported commands

##[
  # Querying device state

  This will fail if `mydevice.retrievable` is false
]##

runnableExamples "-d:ssl":
  from colors import `$`

  let
    myacc = initGovee("YOUR-API-KEY-HERE")
    mydevice = myacc[0]  

  echo myacc.getBrightness(mydevice) # Print device brightness
  echo myacc.getPowerState(mydevice) # Print device power state, if it is on or off
  echo myacc.getColorTemp(mydevice) # Print device color temperature. May print 0
  echo myacc.getColor(mydevice) # Print device color. May print an invalid color
  # for govee devices (#0000000, the darkest color a device can have is #0D0D0D)

##[
  # Controlling devices

  This will fail if `mydevice.controllable` is false
]##
runnableExamples "-d:ssl":
  import colors

  let
    myacc = initGovee("YOUR-API-KEY-HERE")
    mydevice = myacc[0]

  myacc.setColor(mydevice, parseColor("fuchsia")) # set color to the 'fuchsia' color
  myacc.setBrightness(mydevice, 0.85) # set brightness to 85%
  myacc.setColorTemp(mydevice, 2400) # set color temperature to 2400K
  myacc.setPowerState(mydevice, off) # set power state to off/false (a.k.a turning the device off)
  # off is an alias for false

  # Alternatively you can do:
  myacc.turn(mydevice, off)

## .. Note:: This wrapper is not asycronous, perhaps in a future version it will \
## offer an async version of the wrapper.
## 
## .. Note:: If you're trying to get device state *just* after modifying it, \
## You'll need to wait a bit (perhaps atleast 1.5 seconds) for the device \
## to actually change. Then, the device's state will update and the information \
## given by the API/wrapper will be correct.

  

import govee/[
  types,
  commands
]

export 
  types, 
  commands
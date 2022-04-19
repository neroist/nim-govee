from uri import parseUri, `/`

const
  DevicesUri* = parseUri "https://developer-api.govee.com/v1/devices/"  ## The base URI used to get device information.
  ControlUri* = DevicesURI / "control"  ## The URI used to control devices.
  StateUri* =   DevicesURI / "state"  ## The URI used to query device state.

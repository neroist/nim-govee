## Govee error & exception types

import std/[
  httpclient, 
  json
]

type
  GoveeError* = object of CatchableError ## \
  ## Base type for all Govee errors

  GoveeCommandNotSupportedError* = object of GoveeError ## \
  ## Raised when an unsupported/nonexistant command is called on a device

  GoveeAuthorizationError* = object of GoveeError ## \
  ## Raised when an API key cannot be/isn't validated

  GoveeRateLimitedError* = object of GoveeError ## \
  ## Raised when the account is rate limited

  GoveeInternalError* = object of GoveeError ## \
  ## Raised when a 500 error is returned  
  

proc getError(resp: Response): ref GoveeError = 
  ## Return the apropriate GoveeError based on the http code
  ## 
  ## Internal use only.

  case resp.code:
    of Http401, Http403:
      return newException(GoveeAuthorizationError, parseJson(resp.body)["message"].str)
      # Usually "Invalid API Key" or "Missing API Key"
    of Http429:
      return newException(GoveeRateLimitedError, "Rate limited.")
    of Http500:
      return newException(GoveeInternalError, "Govee internal service error.")
    elif resp.code.is4xx:
      var jresp = parseJson(resp.body)

      if jresp["message"].str == "Unsupported cmd":
        return newException(GoveeCommandNotSupportedError, "Command not supported")
      else:
        return newException(GoveeError, jresp["message"].str)
    else:
      return nil

template raiseErrors*(resp: Response) = 
  ## Raise a GoveeError if there is a error response code.
  ## 
  ## Internal use only.
  
  if getError(resp) != nil:
    raise getError(resp)
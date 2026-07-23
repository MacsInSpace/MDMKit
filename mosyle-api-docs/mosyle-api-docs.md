# Mosyle Manager API - scraped article bodies

Scraped from the paid-tenant API-docs overlay (`MDMApi` articles) on 2026-07-24
(tenant: an AU school district instance) using [`tools/extract-articles.js`](tools/extract-articles.js).
All tokens/emails in examples are Mosyle's own placeholders - verified secret-free before commit.
Raw structured data: [`mosyle-api-docs.json`](mosyle-api-docs.json).

## First Steps - How to make a Request using the API (id 32)

To use the Mosyle API you need to enable this feature in the API profile page (My School > API Integration > enable the profile).

Once enabled you will see your access token and make requests to the endpoint "https://managerapi.mosyle.com/v2", every request will have some required parameters as well as optional parameters. The Mosyle API supports the POST request method. All API responses are structured in JSON format.


If your current API integration is using Basic Authentication, please create a new API Token to use JWT Authentication as Basic Authentication has been deprecated.

JWT Authentication

First, make a request to the Mosyle API endpoint "/login" including the access token, email, and password in the body of the request.

Example request:




Example response:



The response will contain a Bearer Token as a JSON Web Token (JWT) in the header which will be needed for subsequent requests. The token will expire every 24 hours and will need to be renewed.

When accessing any other Mosyle API endpoints, include the string "Bearer" followed by the JWT in the request header. The access token will be included in the body of the request.

The following snippet will be used in all subsequent requests:





PowerShell
When making API requests using PowerShell, you'll need to first use the /login request to retrieve the Bearer Token and set it within the request headers. From there, you can call any additional endpoint to retrieve or update data.


An example request to the /login endpoint and using it to make a request to /listusers in PowerShell is below. Please be sure to update with your Access Token, and email/password for an Admin user who has API permissions.









For more examples with other languages and to test the API, click here to download the sample API file. (Compatible with Postman and Insomnia)

Attention: You must change the environment variables and provide your API Token Access, Email and Password when you open the sample archive on Postman or Insomnia.





Check the next articles to learn more about the services and their operations.

```
curl --include --location 'https://managerapi.mosyle.com/v2/login' \
--header 'Content-Type: application/json' \
--data-raw '{
    "accessToken": "Access_Token",
    "email": "User_Email",
    "password": "User_Password"
}'
```

```
HTTP/1.1 200 OK
Date: Mon, 21 Aug 2023 17:31:09 GMT
Server: Apache
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
Content-Security-Policy: frame-src 'self' 'unsafe-eval' 'unsafe-inline' *.mosyle.com frame-ancestors 'self' *.mosyle.com ;default-src 'self' 'unsafe-inline' 'unsafe-eval' *.googleapis.com  *.mosyle.com *.windows.net *.stripe.com *.apple-mapkit.com *.apple.com
Strict-Transport-Security: max-age=63072000; includeSubdomains;
Set-Cookie: PHPSESSID=8901c23c1234e5678b901d2a34a56cc7; path=/; domain=.mosyle.com; secure; HttpOnly
Expires: Thu, 19 Nov 1981 08:52:00 GMT
Cache-Control: no-store, no-cache, must-revalidate
Pragma: no-cache
Authorization: Bearer Bearer_Token
Content-Length: 59
Content-Type: application/json

{"UserID":"User_ID","email":"User_Email"}
```

```
curl --location 'https://managerapi.mosyle.com/v2' 

--header 'Content-Type: application/json' 
--header 'Authorization: Bearer {{Bearer_Token}}' 
--data '{
    "accessToken": "Access_Token"
}'
```

```
# ===== API Credentials =====
$accessToken = "Access_Token"
$email = "email@domain.tld"
$password = "Example_Password"

# Set Headers for all API Requestst
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")

# Set Body for /login request to retrieve Bearer Token
$body = @"
{
    "accessToken": "$accessToken",
    "email": "$email",
    "password": "$password"
}
"@
# Retrieve and Set Bearer Token
$response = Invoke-WebRequest 'https://managerapi.mosyle.com/v2/login' -Method 'POST' -Headers $headers -Body $body
$headers.Add("Authorization", $response.Headers["Authorization"])


# Set Body for List Users request
$body = @"
{
    "accessToken": "$accessToken",
    "options": {
        "specific_columns": [
            "id",
            "name"
        ]
    }
}
"@
# Retrieve list of users
$response = Invoke-RestMethod 'https://managerapi.mosyle.com/v2/listusers' -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json
```

## Devices Operations - List Devices (id 44)

You will hit the endpoint /listdevices and can send parameters to filter your request for the specific info you want to receive in your response.


Key	Type		Description
os	String	Required	Which Operational System will be listed, values can be ios, mac, tvos, or visionos
tags	Array of strings	Optional	

osversions	Array of strings	Optional
	

serial_numbers	Array of strings	Optional	Serial Numbers (filter by specific serial numbers)
page	Integer	Optional	Pagination start with 0
specific_columns	Array of strings	Optional	Use this option to retrieve specific attributes for each device. If this option is excluded, all device attributes will be returned.

Return only specific values:
deviceudid, total_disk, os, serial_number, device_name, device_model, idaccount, battery, osversion, date_info, carrier, roaming_enabled, isroaming, imei, meid, available_disk, wifi_mac_address, last_ip_beat, last_lan_ip, bluetooth_mac_address, is_supervised, date_app_info, date_last_beat, date_last_push, status, isActivationLockEnabled, isDeviceLocatorServiceEnabled, isDoNotDisturbInEffect, isCloudBackupEnabled, IsNetworkTethered, needosupdate, productkeyupdate, device_type, lostmode_status, is_muted, date_muted, activation_bypass, date_media_info, tags (will not include Mosyle-generated tags), iTunesStoreAccountHash, iTunesStoreAccountIsActive, date_profiles_info, ethernet_mac_address, model_name, LastCloudBackupDate, SystemIntegrityProtectionEnabled, BuildVersion, LocalHostName, HostName, OSUpdateSettings, ActiveManagedUsers, CurrentConsoleManagedUser, date_printers, AutoSetupAdminAccounts, appleTVid, asset_tag, ManagementStatus, OSUpdateStatus, AvailableOSUpdates, appleTVid, enrollment_type, userid, useremail, username, usertype, SharedCartName, device_model_name, date_kinfo, location, latitude & longitude & altitude (only available for devices in lost mode), DeviceAttestationStatus, CustomDeviceAttributes, last_ssid

If no specific columns are requested, all Service Subscription data for cellular devices will be returned in the response for both Slot 1 and Slot 2. If you prefer to only receive specific data for Slot 1 and/or Slot 2, specify the keys below:

Slot 1: 'imeiOne', 'meidOne', 'CarrierSettingsVersionOne', 'CurrentCarrierNetworkOne', 'CurrentMCCOne', 'CurrentMNCOne', 'ICCIDOne', 'IsDataPreferredOne', 'IsRoamingOne', 'IsVoicePreferredOne', 'LabelOne', 'LabelIDOne', 'PhoneNumberOne', 'EIDOne'

Slot 2: 'imeiTwo', 'meidTwo', 'CarrierSettingsVersionTwo', 'CurrentCarrierNetworkTwo', 'CurrentMCCTwo', 'CurrentMNCTwo', 'ICCIDTwo', 'IsDataPreferredTwo', 'IsRoamingTwo', 'IsVoicePreferredTwo', 'LabelTwo', 'LabelIDTwo', 'PhoneNumberTwo', 'EIDTwo'

Example request:









Success Response:

```
curl --location 'https://managerapi.mosyle.com/v2/listdevices' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "options": {
        "os": "ios"
    }
}'
```

```
{
  "status": "OK",
  "response": {
    "devices": [
      {
        "deviceudid": "001DFCEB-B160-5F2C-B435-2D4D9F4570E0",
        "total_disk": "256.0000000000",
        "os": "ios"
        ... others attributes and other devices
      }
    ],
    "rows": '1328',
    "page_size": 100,
    "page": 1
  }
}
```

## Devices Operations - Lock Devices (id 62)

To lock a device you will pass the value lock_device through the key operation and send the device UDID through the key parameter devices and the lock pin code through the key parameter pincode. You can send the message to display on the lock screen of the device through the key parameter lockmessage.


Key	Type	Required	Description
devices	Array[string]	Required*	Devices UDID
pincode	Integer	Optional
	Six-character PIN code (macOS only)
phonenumber	String	Optional	The phone number to display on the Lock Screen of the device
lockmessage	String	Optional	The message to display on the Lock Screen of the device

* The pincode key value is available in macOS 10.8 and later. If no new pincode is provided, the last configured pincode will be used. It's important to note that this setting has no effect on iOS devices.




Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "lock_device",
9
            "devices": ["00001023-001234567890A01B","1000a0bc0000000d123456e00fg99hi0jk12345e"],
10
            "pincode": "123456",
11
            "lockmessage": "Your message!"
12
        }
13
    ]
14
}'






Successful Response:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      status: "COMMAND_SENT",
6
      info: "Command sent successfully."
7
    }
8
  ]
9
}


If a device is not found, the devices_notfound node will bring its udid:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      devices_notfound: ['UDID2'],
6
      status: "COMMAND_SENT",
7
      info: "Command sent successfully."
8
    }
9
  ]
10
}


Without 'devices' key:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      status: "MISSING_DATA",
6
      info: "Missing key: devices"
7
    }
8
  ]
9
}


The 'devices' key is empty:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      status: "INVALID_DATA",
6
      info: "The device key is empty. Please, check and try again"
7
​
8
    }
9
  ]
10
}


The 'pincode' key is not an six-character integer:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      status: "INVALID_DATA",
6
      info: "The pincode key must be a six-character integer"
7
    }
8
  ]
9
}


No devices found:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      devices_notfound: ['UDID1', 'UDID2'],
6
      status: "ERROR",
7
      info: "The device selected is not valid. Please, check the device and try again"
8
    }
9
  ]
10
}

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "lock_device",
            "devices": ["00001023-001234567890A01B","1000a0bc0000000d123456e00fg99hi0jk12345e"],
            "pincode": "123456",
            "lockmessage": "Your message!"
        }
    ]
}'
```

```
{
  status: "OK",
  response: [
    {
      status: "COMMAND_SENT",
      info: "Command sent successfully."
    }
  ]
}
```

```
{
  status: "OK",
  response: [
    {
      devices_notfound: ['UDID2'],
      status: "COMMAND_SENT",
      info: "Command sent successfully."
    }
  ]
}
```

```
{
  status: "OK",
  response: [
    {
      status: "MISSING_DATA",
      info: "Missing key: devices"
    }
  ]
}
```

```
{
  status: "OK",
  response: [
    {
      status: "INVALID_DATA",
      info: "The device key is empty. Please, check and try again"

    }
  ]
}
```

```
{
  status: "OK",
  response: [
    {
      status: "INVALID_DATA",
      info: "The pincode key must be a six-character integer"
    }
  ]
}
```

```
{
  status: "OK",
  response: [
    {
      devices_notfound: ['UDID1', 'UDID2'],
      status: "ERROR",
      info: "The device selected is not valid. Please, check the device and try again"
    }
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "lock_device",
```

```
"devices": ["00001023-001234567890A01B","1000a0bc0000000d123456e00fg99hi0jk12345e"],
```

```
"pincode": "123456",
```

```
"lockmessage": "Your message!"
```

```
}
```

```
]
```

```
}'
```

```
status: "OK",
```

```
response: [
```

```
status: "COMMAND_SENT",
```

```
info: "Command sent successfully."
```

```
devices_notfound: ['UDID2'],
```

```
status: "MISSING_DATA",
```

```
info: "Missing key: devices"
```

```
status: "INVALID_DATA",
```

```
info: "The device key is empty. Please, check and try again"
```

```
​
```

```
info: "The pincode key must be a six-character integer"
```

```
devices_notfound: ['UDID1', 'UDID2'],
```

```
status: "ERROR",
```

```
info: "The device selected is not valid. Please, check the device and try again"
```

## Devices Operations - Lost Mode (only iOS) (id 56)

You will hit the endpoint /lostmode and send parameters to enable/disable lost mode and additional functions.
Key	Type		Description
operation	String	Required	enable
disable
play_sound
request_location
devices	Array of strings	Required *	Array of Unique Device Identifier (Device UDID)
groups	Array of strings	Optional	Array of Device Group ID
message	String	Required	Message to be shown on the screen
phone_number	String	Optional	 The phone number will be shown on the screen along with the message. 	
footnote	String	Optional	Footnote text will be shown on the screen along with the message.
* If any Device Group ID has been passed, it is not mandatory to inform the Unique Device Identifier.


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/lostmode' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "elements": [{
7
        "operation": "enable",
8
        "groups": ["210"],
9
        "message": "I'm Lost :(",
10
        "phone_number": "Call to (XXX) XXX-XXXX",
11
        "footnote": "Footnote Text!"
12
    }]
13
}'




Success Response:


1
{ 
2
    "status":"OK",
3
    "response":[ 
4
        { 
5
        "status":"COMMAND_SENT",
6
        "info":"Command sent successfully."
7
        }
8
    ]
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/lostmode' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
	"elements": [{
		"operation": "enable",
		"groups": ["210"],
		"message": "I'm Lost :(",
		"phone_number": "Call to (XXX) XXX-XXXX",
		"footnote": "Footnote Text!"
	}]
}'
```

```
{ 
    "status":"OK",
    "response":[ 
        { 
        "status":"COMMAND_SENT",
        "info":"Command sent successfully."
        }
    ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/lostmode' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [{
```

```
"operation": "enable",
```

```
"groups": ["210"],
```

```
"message": "I'm Lost :(",
```

```
"phone_number": "Call to (XXX) XXX-XXXX",
```

```
"footnote": "Footnote Text!"
```

```
}]
```

```
}'
```

```
{
```

```
"status":"OK",
```

```
"response":[
```

```
"status":"COMMAND_SENT",
```

```
"info":"Command sent successfully."
```

```
}
```

```
]
```

## Devices Operations - Unassign Devices (id 60)

To unassign a device you will pass the value change_to_limbo through the endpoint bulkops and send the Unique Device Identifier through the key parameter devices or/and Device Groups ID through the key parameter groups. You can also send both commands at the same time.
Key	Type		Description
operation	String	Required	change_to_limbo
devices	Array	Required *
	An array of Unique Device Identifier (UDID).
groups	Array	Optional	An array of Device Group IDs - Sends the command to all devices in the group
* If any Device Group ID has been passed, it is not mandatory to inform the Unique Device Identifier.


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "change_to_limbo",
9
            "groups": [
10
                "210"
11
            ]
12
        }
13
    ]
14
}'




Success Response:


1
{ 
2
    "status":"OK",
3
    "response":[ 
4
        { 
5
        "status":"COMMAND_SENT",
6
        "info":"Command sent successfully."
7
        }
8
    ]
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "change_to_limbo",
            "groups": [
                "210"
            ]
        }
    ]
}'
```

```
{ 
    "status":"OK",
    "response":[ 
        { 
        "status":"COMMAND_SENT",
        "info":"Command sent successfully."
        }
    ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "change_to_limbo",
```

```
"groups": [
```

```
"210"
```

```
]
```

```
}
```

```
}'
```

```
"status":"OK",
```

```
"response":[
```

```
"status":"COMMAND_SENT",
```

```
"info":"Command sent successfully."
```

## Devices Operations - Update Device Attributes (id 43)

Key	Type		Description
serialnumber	String	Required	Serial number of the device that will be updated.
asset_tag	String	Optional	To update the device asset tag.
tags	String	Optional	To update the device tags. Multiple tags should be comma-separated.
name	String	Optional	To update the device name.
lock	String	Optional	To update the device lock message.




By hitting the endpoint /devices and sending those parameters like on the 


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/devices' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "serialnumber": "XXXXXXXXXXXX",
9
            "tags": "New Tag"
10
        }
11
    ]
12
}'




Success Response:
1
{
2
  "status": "OK",
3
  "devices": [
4
    "AAAAAAAAAAAA"
5
  ]
6
}

```
curl --location 'https://managerapi.mosyle.com/v2/devices' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "serialnumber": "XXXXXXXXXXXX",
            "tags": "New Tag"
        }
    ]
}'
```

```
{
  "status": "OK",
  "devices": [
    "AAAAAAAAAAAA"
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/devices' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"serialnumber": "XXXXXXXXXXXX",
```

```
"tags": "New Tag"
```

```
}
```

```
]
```

```
}'
```

```
"status": "OK",
```

```
"devices": [
```

```
"AAAAAAAAAAAA"
```

## Devices Operations - Bulk Operations - Wipe Devices (id 47)

To wipe a device you will pass the value bulkops through the endpoint and send the Unique Device Identifier through the key parameter devices or/and Device Groups ID through the key parameter groups. You can also send both commands at the same time.
Key	Type		Description
operation	String	Required	wipe_devices
devices	Array	Required *
	An array of Unique Device Identifier (UDID).
groups	Array	Optional	An array of Device Group IDs - Sends the command to all devices in the group
options	Object (key => value)	Optional	pin_code (6 digits) [macOS only]
PreserveDataPlan (bool) [iOS only]
DisallowProximitySetup (bool) [iOS only]
RevokeVPPLicenses (bool) [iOS & tvOS only]

EnableReturnToService (bool) [iOS & tvOS only] - When enabled, this service will use the default WiFi which can be set in the WiFi Authentication profile.
ShouldRetryEnrollment (bool) [iOS/iPadOS 27+ only] - When enabled, the device retries Return to Service enrollment if the initial enrollment fails after erasure. Requires "EnableReturnToService" to be true.
* If any Device Group ID has been passed, it is not mandatory to inform the Unique Device Identifier.


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "wipe_devices",
9
            "devices": [
10
                "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
11
            ],
12
            "options": {
13
                "RevokeVPPLicenses": "false"
14
            }
15
        }
16
    ]
17
}'





Success Response:


1
{ 
2
 "status":"OK",
3
 "response":[ 
4
 { 
5
 "status":"COMMAND_SENT",
6
 "info":"Command sent successfully."
7
 }
8
 ]
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "wipe_devices",
            "devices": [
                "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
            ],
            "options": {
                "RevokeVPPLicenses": "false"
            }
        }
    ]
}'
```

```
{ 
 "status":"OK",
 "response":[ 
 { 
 "status":"COMMAND_SENT",
 "info":"Command sent successfully."
 }
 ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "wipe_devices",
```

```
"devices": [
```

```
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
```

```
],
```

```
"options": {
```

```
"RevokeVPPLicenses": "false"
```

```
}
```

```
]
```

```
}'
```

```
"status":"OK",
```

```
"response":[
```

```
"status":"COMMAND_SENT",
```

```
"info":"Command sent successfully."
```

## Devices Operations - Bulk Operations - Restart Devices (id 48)

To restart a device you will pass the value bulkops through the endpoint and send the Unique Device Identifier through the key parameter devices or/and Device Groups ID through the key parameter groups. You can also send both commands at the same time.
Key	Type		Description
operation	String	Required	restart_devices
devices	Array	Required *
	An array of Unique Device Identifier (UDID).
groups	Array	Optional	An array of Device Group IDs - Sends the command to all devices in the group
* If any Device Group ID has been passed, it is not mandatory to inform the Unique Device Identifier.


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "restart_devices",
9
            "groups": [
10
                "210"
11
            ]
12
        }
13
    ]
14
}'




Success Response:
1
{ 
2
 "status":"OK",
3
 "response":[ 
4
 { 
5
 "status":"COMMAND_SENT",
6
 "info":"Command sent successfully."
7
 }
8
 ]
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "restart_devices",
            "groups": [
                "210"
            ]
        }
    ]
}'
```

```
{ 
 "status":"OK",
 "response":[ 
 { 
 "status":"COMMAND_SENT",
 "info":"Command sent successfully."
 }
 ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "restart_devices",
```

```
"groups": [
```

```
"210"
```

```
]
```

```
}
```

```
}'
```

```
"status":"OK",
```

```
"response":[
```

```
"status":"COMMAND_SENT",
```

```
"info":"Command sent successfully."
```

## Devices Operations - Bulk Operations - Shutdown Devices (id 49)

To shutdown a device you will pass the value bulkops through the endpoint and send the Unique Device Identifier through the key parameter devices or/and Device Groups ID through the key parameter groups. You can also send both commands at the same time.
Key	Type		Description
operation	String	Required	shutdown_devices
devices	Array	Required *
	An array of Unique Device Identifier (UDID).
groups	Array	Optional	An array of Device Group IDs - Sends the command to all devices in the group
* If any Device Group ID has been passed, it is not mandatory to inform the Unique Device Identifier.


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "shutdown_devices",
9
            "groups": [
10
                "210"
11
            ]
12
        }
13
    ]
14
}'




Success Response:


1
{ 
2
    "status":"OK",
3
    "response":[ 
4
        { 
5
        "status":"COMMAND_SENT",
6
        "info":"Command sent successfully."
7
        }
8
    ]
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "shutdown_devices",
            "groups": [
                "210"
            ]
        }
    ]
}'
```

```
{ 
    "status":"OK",
    "response":[ 
        { 
        "status":"COMMAND_SENT",
        "info":"Command sent successfully."
        }
    ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "shutdown_devices",
```

```
"groups": [
```

```
"210"
```

```
]
```

```
}
```

```
}'
```

```
"status":"OK",
```

```
"response":[
```

```
"status":"COMMAND_SENT",
```

```
"info":"Command sent successfully."
```

## Devices Operations - Bulk Operations - Clear Commands (id 52)

To clear commands you will pass the value bulkops through the endpoint and send the Unique Device Identifier through the key parameter devices or/and Device Groups ID through the key parameter groups. You can also send both commands at the same time.
Key	Type		Description
operation	String	Required	clear_commands (pending + failed)
clear_pending_commands
clear_failed_commands

devices	Array	Required *
	An array of Unique Device Identifier (UDID).
groups	Array	Optional	An array of Device Group IDs - Sends the command to all devices in the group
* If any Device Group ID has been passed, it is not mandatory to inform the Unique Device Identifier.


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "clear_commands",
9
            "groups": [
10
                "210"
11
            ]
12
        }
13
    ]
14
}'




Success Response:


1
{ 
2
   "status":"OK",
3
  "response":[ 
4
       { 
5
         "status":"COMMAND_CLEARED",
6
         "info":"Command cleared successfully."
7
       }
8
   ]
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "clear_commands",
            "groups": [
                "210"
            ]
        }
    ]
}'
```

```
{ 
   "status":"OK",
  "response":[ 
       { 
         "status":"COMMAND_CLEARED",
         "info":"Command cleared successfully."
       }
   ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "clear_commands",
```

```
"groups": [
```

```
"210"
```

```
]
```

```
}
```

```
}'
```

```
"status":"OK",
```

```
"response":[
```

```
"status":"COMMAND_CLEARED",
```

```
"info":"Command cleared successfully."
```

## Devices Operations - Bulk Operations - Activation Lock (id 73)

When you access the Mosyle API endpoint /bulkops passing the value enable_activationlock through the parameter operation you will enable MDM initiated Activation Lock on all listed devices.

To disable MDM initiated Activation Lock, access the Mosyle API endpoint /bulkops passing the value disable_activationlock through the parameter operation.

Available options:


Key	Type	Required	Description
operation	String	Required	enable_activationlock
disable_activationlock

devices	Array [string]	Required
	Array of Unique Device Identifier (Device UDID)
lost_message	String	Optional
	The message to display on the screen of the device




Example Request to Enable Activation Lock:

1
curl --location 'https://managerapi.mosyle.com/v1/bulkops' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
        "elements": [
7
        {
8
            "operation": "enable_activationlock",
9
            "devices": [
10
                "ABCDEF12-34567890ABCDEF12",
11
        "ABCDEF12-34567890ABCDEF34"
12
        ],
13
            "lost_message": "Enter your Lost Message"        
14
   }
15
        ]
16
}'



Example Request to Disable Activation Lock:

1
curl --location 'https://managerapi.mosyle.com/v1/bulkops' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer Bearer_Token' \
4
--data '{
5
    "accessToken": "Access_Token",
6
        "elements": [
7
        {
8
            "operation": "disable_activationlock",
9
            "devices": [
10
                "ABCDEF12-34567890ABCDEF12",
11
        "ABCDEF12-34567890ABCDEF34"
12
        ]
13
   }
14
        ]
15
}'

```
curl --location 'https://managerapi.mosyle.com/v1/bulkops' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
	"accessToken": "Access_Token",
    	"elements": [
        {
            "operation": "enable_activationlock",
            "devices": [
                "ABCDEF12-34567890ABCDEF12",
		"ABCDEF12-34567890ABCDEF34"
		],
            "lost_message": "Enter your Lost Message"        
   }
    	]
}'
```

```
curl --location 'https://managerapi.mosyle.com/v1/bulkops' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer Bearer_Token' \
--data '{
	"accessToken": "Access_Token",
    	"elements": [
        {
            "operation": "disable_activationlock",
            "devices": [
                "ABCDEF12-34567890ABCDEF12",
		"ABCDEF12-34567890ABCDEF34"
		]
   }
    	]
}'
```

```
curl --location 'https://managerapi.mosyle.com/v1/bulkops' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "enable_activationlock",
```

```
"devices": [
```

```
"ABCDEF12-34567890ABCDEF12",
```

```
"ABCDEF12-34567890ABCDEF34"
```

```
],
```

```
"lost_message": "Enter your Lost Message"
```

```
}
```

```
]
```

```
}'
```

```
--header 'Authorization: Bearer Bearer_Token' \
```

```
"operation": "disable_activationlock",
```

## Devices Operations - Bulk Operations - Move Devices to Accounts (District Only) (id 75)

To move devices from the District Level to a specific account you will pass the value move_device_account through the key operation and send the Device UDID through the key parameter devices and/or the Device Group ID through the key parameter groups. You can send both commands at the same time.


Key	Type	Required	Description
operation	String	Required	move_device_account
devices	Array	Required
	An array of Unique Device Identifiers (UDID)
AccountID	Integer	Required	Account ID where the device should be moved
groups	Array	Optional	An array of Device Group IDs


NOTE: There is a limit of 200 elements per request.


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "move_device_account",
9
            "devices": ["00001023-001234567890A01B","1000a0bc0000000d123456e00fg99hi0jk12345e"],
10
            "AccountID": "123",
11
            "groups": ["27"]
12
        }
13
    ]
14
}'



Successful Response:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      status: "COMMAND_SENT",
6
      info: "Command sent successfully."
7
    }
8
  ]
9
}


If the account is not found:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      status: "ACCOUNT_NOTFOUND",
6
      info: "No account found."
7
    }
8
  ]
9
}


Without 'AccountID' key:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      status: "MISSING_DATA",
6
      info: "Missing key: AccountID"
7
    }
8
  ]
9
}


If the request is made from an account that is not a District Account:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      status: "NOT_ALLOWED",
6
      info: "This operation is available only for District Level"
7
​
8
    }
9
  ]
10
}

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "move_device_account",
            "devices": ["00001023-001234567890A01B","1000a0bc0000000d123456e00fg99hi0jk12345e"],
            "AccountID": "123",
            "groups": ["27"]
        }
    ]
}'
```

```
{
  status: "OK",
  response: [
    {
      status: "COMMAND_SENT",
      info: "Command sent successfully."
    }
  ]
}
```

```
{
  status: "OK",
  response: [
    {
      status: "ACCOUNT_NOTFOUND",
      info: "No account found."
    }
  ]
}
```

```
{
  status: "OK",
  response: [
    {
      status: "MISSING_DATA",
      info: "Missing key: AccountID"
    }
  ]
}
```

```
{
  status: "OK",
  response: [
    {
      status: "NOT_ALLOWED",
      info: "This operation is available only for District Level"

    }
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "move_device_account",
```

```
"devices": ["00001023-001234567890A01B","1000a0bc0000000d123456e00fg99hi0jk12345e"],
```

```
"AccountID": "123",
```

```
"groups": ["27"]
```

```
}
```

```
]
```

```
}'
```

```
status: "OK",
```

```
response: [
```

```
status: "COMMAND_SENT",
```

```
info: "Command sent successfully."
```

```
status: "ACCOUNT_NOTFOUND",
```

```
info: "No account found."
```

```
status: "MISSING_DATA",
```

```
info: "Missing key: AccountID"
```

```
status: "NOT_ALLOWED",
```

```
info: "This operation is available only for District Level"
```

```
​
```

## Devices Operations - Bulk Operations - Change/Update Limbo Location (id 76)

To change or update the location of devices in Limbo you will pass the value update_limbo_location through the key operation and send the Device UDID through the key parameter devices and/or the Device Group ID through the key parameter groups. You can send both commands at the same time.


Key	Type	Required	Description
operation	String	Required	update_limbo_location
devices	Array	Required
	An array of Unique Device Identifiers (UDID)
location	String	Required	The name of the location to assign the devices.
groups	Array	Optional	An array of Device Group IDs - update the location of all devices in the group


NOTE: To update or change the location of limbo devices, the setting "Limbo devices belong to all locations" must be disabled under My School > Preferences > Other Settings > General Preferences.


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "update_limbo_location",
9
            "devices": ["00001023-001234567890A01B","1000a0bc0000000d123456e00fg99hi0jk12345e"],
10
            "location": "Mosyle School",
11
            "groups": ["27"]
12
        }
13
    ]
14
}'



Successful Response:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      status: "COMMAND_SENT",
6
      info: "Command sent successfully to all Limbo devices."
7
    }
8
  ]
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "update_limbo_location",
            "devices": ["00001023-001234567890A01B","1000a0bc0000000d123456e00fg99hi0jk12345e"],
            "location": "Mosyle School",
            "groups": ["27"]
        }
    ]
}'
```

```
{
  status: "OK",
  response: [
    {
      status: "COMMAND_SENT",
      info: "Command sent successfully to all Limbo devices."
    }
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/bulkops' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "update_limbo_location",
```

```
"devices": ["00001023-001234567890A01B","1000a0bc0000000d123456e00fg99hi0jk12345e"],
```

```
"location": "Mosyle School",
```

```
"groups": ["27"]
```

```
}
```

```
]
```

```
}'
```

```
status: "OK",
```

```
response: [
```

```
status: "COMMAND_SENT",
```

```
info: "Command sent successfully to all Limbo devices."
```

## Users Operations - List Users (id 36)

Key	Type		Description
page	integer	Optional	The API does not send the entire list of users in one request, it needs to use pagination (default: 1).
specific_columns	Array of strings	Optional	This option should be used to receive just the necessary attributes for each user. Possible values: id, name, email, grades, managedappleid, serial_number, type, locations, account, assigned_devices
types	Array of string	Optional	Filter users by type. Possible values: STUDENT, TEACHER, LOCATION_LEADER, STAFF, ADMIN, ACCOUNT_ADMIN, DISTRICT_ADMIN.
identifiers	Array of integers	Optional	Filter users by User ID
idusers	Array of integers	Optional	Filter users by Unique Internal Mosyle ID


You will hit the endpoint /listusers and can send parameters to filter your request for the specific info you want to receive in your response.



Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/listusers' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "options": {
7
        "specific_columns": [
8
            "type"
9
        ]
10
    }
11
}'





Success Response:


1
{
2
  "status": "OK",
3
  "response": {
4
    "users": [
5
      {
6
        "id": "dc093492-d2bf-4c0a-9a8e-5aadc541e250",
7
        "type": "STUDENT"
8
      }
9
    ]
10
  }
11
}

```
curl --location 'https://managerapi.mosyle.com/v2/listusers' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "options": {
        "specific_columns": [
            "type"
        ]
    }
}'
```

```
{
  "status": "OK",
  "response": {
    "users": [
      {
        "id": "dc093492-d2bf-4c0a-9a8e-5aadc541e250",
        "type": "STUDENT"
      }
    ]
  }
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/listusers' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"options": {
```

```
"specific_columns": [
```

```
"type"
```

```
]
```

```
}
```

```
}'
```

```
{
```

```
"status": "OK",
```

```
"response": {
```

```
"users": [
```

```
"id": "dc093492-d2bf-4c0a-9a8e-5aadc541e250",
```

```
"type": "STUDENT"
```

## Users Operations - Create Users (id 34)

To create a user you will pass the value save through the parameter operation.

Key	Type		Description
id	String max: 255 chars	Required	This is the User ID. This MUST be unique inside the School Database and will be used for other services.
operation	string	Required	save
name	String max: 100 chars	Required	User Name
type	string	Required	Possible values:
S: Student
T: Teacher
STAFF: Staff

email	String max: 255 chars	Required (Optional for students and staff)	User E-mail address
managed_appleid	String max: 255 chars	Optional	Managed Apple ID created in ASM
locations	Array	Required for Students, Teachers, and Staff	Each array position should contain 2 keys: name, grade_level. The key 'grade_level' is required only for students (for other user types this key can be omitted). Location Name and Grade Level have a limit of 50 characters each.
welcome_email	Integer	Required Values: 1 (one); 0 (zero)	When the value is 1, Mosyle Manager will send an email with the instructions to login. This option will only work when the email field is not blank.
idaccount	integer	Required if District account	School account ID where the user should be added.


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/users' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "save",
9
            "id": "example.student",
10
            "name": "Example Student",
11
            "type": "S",
12
            "email": "example.student@mosyle.com",
13
            "locations": [
14
                {
15
                    "name": "Cityview Day School",
16
                    "grade_level": "Kindergarten"
17
                }
18
            ],
19
            "welcome_email": 0
20
        }
21
    ]
22
}'




Success Response:

1
{
2
  'status': 'OK',
3
  'elements': [
4
    {
5
      'id': 'user.staff.1',
6
      'status': 'OK'
7
    }
8
  ]
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/users' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "save",
            "id": "example.student",
            "name": "Example Student",
            "type": "S",
            "email": "example.student@mosyle.com",
            "locations": [
                {
                    "name": "Cityview Day School",
                    "grade_level": "Kindergarten"
                }
            ],
            "welcome_email": 0
        }
    ]
}'
```

```
{
  'status': 'OK',
  'elements': [
    {
      'id': 'user.staff.1',
      'status': 'OK'
    }
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/users' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "save",
```

```
"id": "example.student",
```

```
"name": "Example Student",
```

```
"type": "S",
```

```
"email": "example.student@mosyle.com",
```

```
"locations": [
```

```
"name": "Cityview Day School",
```

```
"grade_level": "Kindergarten"
```

```
}
```

```
],
```

```
"welcome_email": 0
```

```
]
```

```
}'
```

```
'status': 'OK',
```

```
'elements': [
```

```
'id': 'user.staff.1',
```

```
'status': 'OK'
```

## Users Operations - Update Users (id 74)

To update a user you will pass the value update through the parameter operation.

Key	Type		Description
id	String max: 255 chars	Required	This is the User ID. This MUST be unique inside the School Database and will be used for other services.
operation	string	Required	update
name	String max: 100 chars	Optional	User Name
type	string	Optional	Possible values:
S: Student
T: Teacher
STAFF: Staff

email	String max: 255 chars	Optional	User E-mail address
managed_appleid	String max: 255 chars	Optional	Managed Apple ID created in ASM
locations	Array	Optional	Each array position should contain 2 keys: name, grade_level. The key 'grade_level' is required only for students (for other user types this key can be omitted). Location Name and Grade Level have a limit of 50 characters each.
idaccount	integer	Required if District account	School account ID where the user should be updated


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/users' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "update",
9
            "id": "example.student",
10
            "name": "Example Student",
11
            "type": "S",
12
            "email": "example.student@mosyle.com",
13
            "locations": [
14
                {
15
                    "name": "Cityview Day School",
16
                    "grade_level": "Kindergarten"
17
                }
18
            ]
19
        }
20
    ]
21
}'




Success Response:

1
{
2
  'status': 'OK',
3
  'elements': [
4
    {
5
      'id': 'example.student',
6
      'status': 'OK'
7
    }
8
  ]
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/users' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "update",
            "id": "example.student",
            "name": "Example Student",
            "type": "S",
            "email": "example.student@mosyle.com",
            "locations": [
                {
                    "name": "Cityview Day School",
                    "grade_level": "Kindergarten"
                }
            ]
        }
    ]
}'
```

```
{
  'status': 'OK',
  'elements': [
    {
      'id': 'example.student',
      'status': 'OK'
    }
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/users' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "update",
```

```
"id": "example.student",
```

```
"name": "Example Student",
```

```
"type": "S",
```

```
"email": "example.student@mosyle.com",
```

```
"locations": [
```

```
"name": "Cityview Day School",
```

```
"grade_level": "Kindergarten"
```

```
}
```

```
]
```

```
}'
```

```
'status': 'OK',
```

```
'elements': [
```

```
'id': 'example.student',
```

```
'status': 'OK'
```

## Users Operations - Delete User (id 45)

Key	Type		Description
id	String max: 255 chars	Required	This is the User ID. This MUST be unique inside the School Database and will be used in other services.
operation	string	Required	delete


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/users' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "delete",
9
            "id": "new.user.1"
10
        }
11
    ]
12
}'




Success Response:

1
{
2
  "status": "OK",
3
  "elements": [
4
    {
5
      "id": "user.staff.1",
6
      "status": "OK"
7
    }
8
  ]
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/users' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "delete",
            "id": "new.user.1"
        }
    ]
}'
```

```
{
  "status": "OK",
  "elements": [
    {
      "id": "user.staff.1",
      "status": "OK"
    }
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/users' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "delete",
```

```
"id": "new.user.1"
```

```
}
```

```
]
```

```
}'
```

```
"status": "OK",
```

```
"id": "user.staff.1",
```

```
"status": "OK"
```

## Users Operations - Assign Devices (id 46)

Key	Type		Description
id	String max: 255 chars	Required	This is the User ID. This MUST be unique inside the School Database and will be used for other services.
operation	string	Required	assign_device
serial_number	string	Required	Assign a specifc device to the user.




Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/users' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "assign_device",
9
            "id": "new.user.1",
10
            "serial_number": "AAAAAAAAAAAA"
11
        }
12
    ]
13
}'




Success Response:

1
{
2
  "status": "OK",
3
  "elements": [
4
    {
5
      "id": "user.staff.1",
6
      "status": "OK"
7
    }
8
  ]
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/users' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "assign_device",
            "id": "new.user.1",
            "serial_number": "AAAAAAAAAAAA"
        }
    ]
}'
```

```
{
  "status": "OK",
  "elements": [
    {
      "id": "user.staff.1",
      "status": "OK"
    }
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/users' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "assign_device",
```

```
"id": "new.user.1",
```

```
"serial_number": "AAAAAAAAAAAA"
```

```
}
```

```
]
```

```
}'
```

```
"status": "OK",
```

```
"id": "user.staff.1",
```

```
"status": "OK"
```

## Classes - Save and Delete Classes (id 37)

Key	Type		Description
id	String (max: 100)	Required	Class ID in the Education Institution Database.
operation	String	Required	save: Save or update the class in the system.
delete: Delete the class
course_name	String max: 50 chars	Required	Course Name
class_name	String max: 50 chars	Required	Class Name
location	String max: 50 chars	Required	Location name. If the Location does not exist, one will be created with this name.
idteacher	String	Required	Teacher ID, same ID value entered in the User Web Service.
students	Array	Optional	Array of student IDs. The Student must be the same modality of the class. Class 1:1 just contain students 1:1.
room	String max: 50 chars	Optional	Room where the class is offered.
coordinators	Array	Optional	Array of Instructor User IDs. The User ID can not belong to a student.
platform	String	Optional	The absence of this value will default to the "ios" platform. This value can be ios or mac.


You will hit the endpoint /classes and pass the value save or delete through the parameter operation.

Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/classes' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "save",
9
            "id": "class.id",
10
            "course_name": "Test API",
11
            "class_name": "Class Test",
12
            "location": "Mosyle Training",
13
            "idteacher": "teacher.api"
14
        }
15
    ]
16
}'




Success Response:
1
{
2
  "status": "OK",
3
  "uuid": "123456789"
4
}

```
curl --location 'https://managerapi.mosyle.com/v2/classes' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "save",
            "id": "class.id",
            "course_name": "Test API",
            "class_name": "Class Test",
            "location": "Mosyle Training",
            "idteacher": "teacher.api"
        }
    ]
}'
```

```
{
  "status": "OK",
  "uuid": "123456789"
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/classes' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "save",
```

```
"id": "class.id",
```

```
"course_name": "Test API",
```

```
"class_name": "Class Test",
```

```
"location": "Mosyle Training",
```

```
"idteacher": "teacher.api"
```

```
}
```

```
]
```

```
}'
```

```
"status": "OK",
```

```
"uuid": "123456789"
```

## Classes - List Classes (id 57)

Key	Type		Description
page	integer	Optional	The API will not send the entire list of classes in one request, rather it uses pagination (default: 1).
specific_columns	Array of strings	Optional	This option should be used to receive just the necessary attributes for each class. Possible values: id, class_name, course_name, location, teacher, students, coordinators, account.


You will hit the endpoint /listclasses and can send the parameter options as an array to filter your search

Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/listclasses' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "options":        {
7
          "specific_columns": ["class_name","teacher","location"]
8
} 
9
}'



Success Response:



1
{
2
  "status": "OK",
3
  "response": {
4
    "classes": [
5
      {
6
        "id": "dc093492-d2bf-4c0a-9a8e-5aadc541e250",
7
        "idclass": "123",
8
        "name": "Class I",
9
        "teacher": "john.smith",
10
        "locations": [
11
          "Townsville"
12
        ]
13
      }
14
  }
15
}

```
curl --location 'https://managerapi.mosyle.com/v2/listclasses' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "options":        {
          "specific_columns": ["class_name","teacher","location"]
} 
}'
```

```
{
  "status": "OK",
  "response": {
    "classes": [
      {
        "id": "dc093492-d2bf-4c0a-9a8e-5aadc541e250",
        "idclass": "123",
        "name": "Class I",
        "teacher": "john.smith",
        "locations": [
          "Townsville"
        ]
      }
  }
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/listclasses' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"options":        {
```

```
"specific_columns": ["class_name","teacher","location"]
```

```
}
```

```
}'
```

```
{
```

```
"status": "OK",
```

```
"response": {
```

```
"classes": [
```

```
"id": "dc093492-d2bf-4c0a-9a8e-5aadc541e250",
```

```
"idclass": "123",
```

```
"name": "Class I",
```

```
"teacher": "john.smith",
```

```
"locations": [
```

```
"Townsville"
```

```
]
```

## Accounts (District Only) - Get Accounts (id 38)

For district accounts, hit the endpoint /accounts to get a list of all accounts.


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/accounts' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token"
6
}'




Success Response:
1
{
2
  "status": "OK",
3
  "accounts": [
4
    {
5
      "idaccount": "1",
6
      "name": "Account 1",
7
      "address": "Street 1",
8
      "date_created": "1556195183"
9
    },
10
    {
11
      "idaccount": "2",
12
      "name": "Account 2",
13
      "address": "Street 2",
14
      "date_created": "1556195196"
15
    }
16
  ]
17
}

```
curl --location 'https://managerapi.mosyle.com/v2/accounts' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token"
}'
```

```
{
  "status": "OK",
  "accounts": [
    {
      "idaccount": "1",
      "name": "Account 1",
      "address": "Street 1",
      "date_created": "1556195183"
    },
    {
      "idaccount": "2",
      "name": "Account 2",
      "address": "Street 2",
      "date_created": "1556195196"
    }
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/accounts' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token"
```

```
}'
```

```
{
```

```
"status": "OK",
```

```
"accounts": [
```

```
"idaccount": "1",
```

```
"name": "Account 1",
```

```
"address": "Street 1",
```

```
"date_created": "1556195183"
```

```
},
```

```
"idaccount": "2",
```

```
"name": "Account 2",
```

```
"address": "Street 2",
```

```
"date_created": "1556195196"
```

```
}
```

```
]
```

## Accounts (District Only) - Create new Account (id 40)

Key	Type		Description
operation	String	Required	The value of this operation must be 'request'.
school_name	String	Required	The name of the new account.
school_address	String	Required	The address info of the new account.
leader_name	String max: 100 chars	Optional	The name of the account leader.
leader_email	String max: 255 chars	Optional
	The email of the account leader.
leader_id	String max: 255 chars	Optional	The id of the account leader.

uuid	String max: 255 chars	Optional
	


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/accounts' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "request",
9
            "school_name": "New School",
10
            "school_address": "New School Street"
11
        }
12
    ]
13
}'





Success Response:


1
{
2
  "status": "OK",
3
  "uuid": "123123"
4
}

```
curl --location 'https://managerapi.mosyle.com/v2/accounts' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "request",
            "school_name": "New School",
            "school_address": "New School Street"
        }
    ]
}'
```

```
{
  "status": "OK",
  "uuid": "123123"
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/accounts' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "request",
```

```
"school_name": "New School",
```

```
"school_address": "New School Street"
```

```
}
```

```
]
```

```
}'
```

```
"status": "OK",
```

```
"uuid": "123123"
```

## Cisco ISE - Cisco ISE - Add and remove Devices (id 41)

Key	Type		Description
action	String	Required	Values can be add or remove, in order to add or remove the mac address and serial number from the Cisco ISE list.
wifimac	String	Required	
serialnumber	String	Required	
model	String	Optional	Device model, Limit 50 characters.


You will hit the endpoint /ciscoise and pass the value add or remove through the parameter action.


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/ciscoise' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "action": "add",
9
            "wifimac": "XX:XX:XX:XX:XX:XX",
10
            "serialnumber": "XXXXXXXXXXXX"
11
        }
12
    ]
13
}'

```
curl --location 'https://managerapi.mosyle.com/v2/ciscoise' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "action": "add",
            "wifimac": "XX:XX:XX:XX:XX:XX",
            "serialnumber": "XXXXXXXXXXXX"
        }
    ]
}'
```

```
curl --location 'https://managerapi.mosyle.com/v2/ciscoise' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"action": "add",
```

```
"wifimac": "XX:XX:XX:XX:XX:XX",
```

```
"serialnumber": "XXXXXXXXXXXX"
```

```
}
```

```
]
```

```
}'
```

## Cisco ISE - Cisco ISE - Get Device (id 42)

In this operation you just need to hit the endpoint /getciscoise and can send the parameter paging, check out the example below


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/getciscoise' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token"
6
}'

```
curl --location 'https://managerapi.mosyle.com/v2/getciscoise' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token"
}'
```

```
curl --location 'https://managerapi.mosyle.com/v2/getciscoise' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token"
```

```
}'
```

## Dynamic Device Groups Operations - List Dynamic Device Groups (id 55)

You will hit the endpoint /listdevicegroups and can send parameters to filter your request for the specific info you want to receive in your response or receive all info about dynamic device groups.



Available options:


Key	Type	Required	Description
os	enum ('ios', 'mac', 'tvOS', 'visionos')	Required	Operational system
page	integer	Optional	Pagination starting with 0
is_security_group	integer (0 or 1)	Optional
	0: (Default) Lists only non-security device groups 1: Lists only security device groups (macOS Device Scout, Detection & Removal, and Automated Zero Trust)




Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/listdevicegroups' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "options": {
7
        "os": "mac"
8
    }
9
}'




Example Response: 
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      groups: [
6
        {
7
          id: "210",
8
          name: "My Device Group",
9
          device_numbers: "3",
10
        }
11
      ],
12
      rows: 1
13
      page_size: 50
14
      page: 1
15
    }
16
  ]
17
}


Without 'os' key:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      status: "MISSING_DATA",
6
      info: "Missing key: os"
7
    }
8
  ]
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/listdevicegroups' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "options": {
        "os": "mac"
    }
}'
```

```
{
  status: "OK",
  response: [
    {
      groups: [
        {
          id: "210",
          name: "My Device Group",
          device_numbers: "3",
        }
      ],
      rows: 1
      page_size: 50
      page: 1
    }
  ]
}
```

```
{
  status: "OK",
  response: [
    {
      status: "MISSING_DATA",
      info: "Missing key: os"
    }
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/listdevicegroups' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"options": {
```

```
"os": "mac"
```

```
}
```

```
}'
```

```
{
```

```
status: "OK",
```

```
response: [
```

```
groups: [
```

```
id: "210",
```

```
name: "My Device Group",
```

```
device_numbers: "3",
```

```
],
```

```
rows: 1
```

```
page_size: 50
```

```
page: 1
```

```
]
```

```
status: "MISSING_DATA",
```

```
info: "Missing key: os"
```

## Dynamic Device Groups Operations - List Devices (id 58)

You will hit the endpoint /listdevicesbygroup and can send group ID to filter your request for the specific dynamic device group you want to receive in your response.



Available options:


Key	Type	Required	Description
iddevicegroup	string	Required	Dynamic Device Group ID (you can obtain this data using the "List Dynamic Device Groups" operation)
is_security_group	integer (0 or 1)	Optional	0: (Default) Lists only non-security device groups
1: Lists only security device groups
security_compliance_status	enum ('compliant' or 'noncompliant')	Optional	'compliant': Default. Lists only device UDIDs that are compliant with macOS Device Scout rules
'noncompliant': Lists only device UDIDs that are not compliant with macOS Device Scout rules




Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/listdevicesbygroup' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "options": {
7
        "iddevicegroup": "123"
8
    }
9
}'




Successful Response: 
1
{
2
  status: "OK",
3
  response: {
4
      "group_name": "Class 101",
5
      "udids": [
6
        "1CD85FCF-04EA-5540-9E73-94FB4D36A392",
7
        "22473995-BE4A-0CE0-FA60-26827D981212",
8
        "E4ED28D6-6C5D-5B5C-93FB-AESAD12321J3"
9
      ]
10
  }
11
}

```
curl --location 'https://managerapi.mosyle.com/v2/listdevicesbygroup' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "options": {
        "iddevicegroup": "123"
    }
}'
```

```
{
  status: "OK",
  response: {
      "group_name": "Class 101",
      "udids": [
        "1CD85FCF-04EA-5540-9E73-94FB4D36A392",
        "22473995-BE4A-0CE0-FA60-26827D981212",
        "E4ED28D6-6C5D-5B5C-93FB-AESAD12321J3"
      ]
  }
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/listdevicesbygroup' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"options": {
```

```
"iddevicegroup": "123"
```

```
}
```

```
}'
```

```
{
```

```
status: "OK",
```

```
response: {
```

```
"group_name": "Class 101",
```

```
"udids": [
```

```
"1CD85FCF-04EA-5540-9E73-94FB4D36A392",
```

```
"22473995-BE4A-0CE0-FA60-26827D981212",
```

```
"E4ED28D6-6C5D-5B5C-93FB-AESAD12321J3"
```

```
]
```

## Dynamic Device Groups Operations - Add / Remove Device from Dynamic Device Group (id 64)

When you access the Mosyle API endpoint /devicegroups passing the value update_devices through the parameter operation you can add or remove specific device UDIDs from a device group. This action requires the key parameter idgroup to filter which Dynamic Device Group you want to add or remove the devices.




Available options:

Key	Type	Required	Description
operation	string	Required	update_devices
idgroup	integer	Required	Device Group ID
add	[string]	Optional *	List of the Device UDIDs to add to the specific device group
remove	[string]	Optional *	List of the Device UDIDs to remove from the specific device group

* At least one must be included




Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/devicegroups' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "operation": "update_devices",
7
    "idgroup": "154",
8
    "add": ["AAAAAAAA-1234-4321-A1B2-AAAAAAAAAAAA"]
9
}'




Success Response:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      status: "OK",
6
      info: "110",
7
  ]
8
}

```
curl --location 'https://managerapi.mosyle.com/v2/devicegroups' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "operation": "update_devices",
    "idgroup": "154",
    "add": ["AAAAAAAA-1234-4321-A1B2-AAAAAAAAAAAA"]
}'
```

```
{
  status: "OK",
  response: [
    {
      status: "OK",
      info: "110",
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/devicegroups' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"operation": "update_devices",
```

```
"idgroup": "154",
```

```
"add": ["AAAAAAAA-1234-4321-A1B2-AAAAAAAAAAAA"]
```

```
}'
```

```
{
```

```
status: "OK",
```

```
response: [
```

```
info: "110",
```

```
]
```

```
}
```

## Dynamic Device Groups Operations - List Devices in Device Groups (id 65)

You will hit the endpoint /listdevicegroupsdevices and can send parameters to filter your request for the specific info you want to receive in your response about device groups.



Available options:



Key

	

Type

	

Required

	

Description




os

	

enum ('ios', 'mac', 'tvos')

	

Required

	

Operational system




page

	

integer

	

Optional

	

Pagination starting with 1




page_size

	

integer

	

Optional

	

Default is 50


is_security_group	integer (0 or 1)	Optional	0: (Default) Lists only non-security groups 1: Lists only security device groups (macOS Device Scout, Detection & Removal, and Automated Zero Trust)
security_compliance_status	enum ('compliant' or 'noncompliant')	Optional	'compliant': (Default) Lists only device UDIDs that are compliant with the Device Scout rules 'noncompliant': Lists only device UDIDs that are not compliant with the Device Scout rules






Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/listdevicegroupsdevices' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "options": {
7
        "os": "mac"
8
    }
9
}'




Response:
1
{
2
  status: 'OK',
3
  response: [
4
    {
5
      groups: [
6
        {
7
          id: '210',
8
          name: 'My Device Group',
9
          device_numbers: '1',
10
deviceudids: ["02345030-000A34203A83B02F"],
11
​
12
        }
13
      ],
14
      rows: 1
15
      page_size: 50
16
      page: 1
17
    }
18
  ]
19
}


Without 'os' key:
1
{
2
  status: 'OK',
3
  response: [
4
    {
5
      status: 'MISSING_DATA',
6
      info: 'Missing key: os'
7
    }
8
  ]
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/listdevicegroupsdevices' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "options": {
        "os": "mac"
    }
}'
```

```
{
  status: 'OK',
  response: [
    {
      groups: [
        {
          id: '210',
          name: 'My Device Group',
          device_numbers: '1',
deviceudids: ["02345030-000A34203A83B02F"],

        }
      ],
      rows: 1
      page_size: 50
      page: 1
    }
  ]
}
```

```
{
  status: 'OK',
  response: [
    {
      status: 'MISSING_DATA',
      info: 'Missing key: os'
    }
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/listdevicegroupsdevices' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"options": {
```

```
"os": "mac"
```

```
}
```

```
}'
```

```
{
```

```
status: 'OK',
```

```
response: [
```

```
groups: [
```

```
id: '210',
```

```
name: 'My Device Group',
```

```
device_numbers: '1',
```

```
deviceudids: ["02345030-000A34203A83B02F"],
```

```
​
```

```
],
```

```
rows: 1
```

```
page_size: 50
```

```
page: 1
```

```
]
```

```
status: 'MISSING_DATA',
```

```
info: 'Missing key: os'
```

## Dynamic Device Groups Operations - Specific iOS/iPadOS Rules (id 79)

You will hit the endpoint /iossecuritycontrolscompliance and can send the rule name to filter your request for devices associated with the specific rule name you want to receive in your response.



Available options:



Key

	

Type

	

Required

	

Description




rule_name

	

string

	

Required

	

Name of the rule




security_compliance_status


	

string ('compliant' or 'noncompliant')


	

Required


	

'compliant': (Default) Lists only device UDIDs that are compliant with the iOS/iPadOS Device Scout rule


'noncompliant': Lists only device UDIDs that are not compliant with the iOS/iPadOS Device Scout rule




page


	

integer

	

Optional

	

Pagination starts with 0



page_size
	integer	Optional	Default is 50




Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/iossecuritycontrolscompliance' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "options": {
7
        "rule_name": "Rule1",
8
        "security_compliance_status": "compliant"
9
    }
10
}'




Response:
1
{
2
  {  response: {
3
​
4
        "status": "success",
5
        "rule_name": "NoJailbreak",
6
        "compliance_status": 1,
7
        "page_size": 50,
8
        "page": 1,
9
        "total_rows": "1",
10
        'devices': [
11
            {
12
                "UDID": "1CD85FCF-04EA-5540-9E73-94FB4D36A392",
13
                "ComplianceStatus": "1"
14
            }
15
​
16
​
17
      ]
18
  }
19
}

```
curl --location 'https://managerapi.mosyle.com/v2/iossecuritycontrolscompliance' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "options": {
        "rule_name": "Rule1",
        "security_compliance_status": "compliant"
    }
}'
```

```
{
  {  response: {

        "status": "success",
        "rule_name": "NoJailbreak",
        "compliance_status": 1,
        "page_size": 50,
        "page": 1,
        "total_rows": "1",
      	'devices': [
            {
                "UDID": "1CD85FCF-04EA-5540-9E73-94FB4D36A392",
                "ComplianceStatus": "1"
            }


      ]
  }
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/iossecuritycontrolscompliance' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"options": {
```

```
"rule_name": "Rule1",
```

```
"security_compliance_status": "compliant"
```

```
}
```

```
}'
```

```
{
```

```
{  response: {
```

```
​
```

```
"status": "success",
```

```
"rule_name": "NoJailbreak",
```

```
"compliance_status": 1,
```

```
"page_size": 50,
```

```
"page": 1,
```

```
"total_rows": "1",
```

```
'devices': [
```

```
"UDID": "1CD85FCF-04EA-5540-9E73-94FB4D36A392",
```

```
"ComplianceStatus": "1"
```

```
]
```

## Action Logs - List (id 61)

Key	Type		Description
page	Integer	Optional	The API does not send the entire list of logs in one request. Pagination should be used to get more data if the response has more pages (default: 1).
filter_options	Array of strings	Optional	Values that can be used to filter the Action Logs: start_date (timestamp), end_date (timestamp), idusers (array of users id).




Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/adminlogs' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "filter_options":        {
7
          "start_date": "1696561838",
8
          "end_date": "1696821038"
9
} 
10
}'




Success Response: 
1
{
2
  "status": "OK",
3
  "response": [
4
    {
5
      "logs": [
6
        {
7
          "action": "Save Profile",
8
          "details": {
9
            "Profile Type": "Install App",
10
            "Operating System": "macOS",
11
          },
12
          "username": "Catalog",
13
          "action_date": "2021-03-01",
14
          "ip": "127.0.0.1"
15
        }
16
      ],
17
      "rows": "1",
18
      "page_size": 50,
19
      "page": 1
20
    }
21
  ]
22
}

```
curl --location 'https://managerapi.mosyle.com/v2/adminlogs' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "filter_options":        {
          "start_date": "1696561838",
          "end_date": "1696821038"
} 
}'
```

```
{
  "status": "OK",
  "response": [
    {
      "logs": [
        {
          "action": "Save Profile",
          "details": {
            "Profile Type": "Install App",
            "Operating System": "macOS",
          },
          "username": "Catalog",
          "action_date": "2021-03-01",
          "ip": "127.0.0.1"
        }
      ],
      "rows": "1",
      "page_size": 50,
      "page": 1
    }
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/adminlogs' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"filter_options":        {
```

```
"start_date": "1696561838",
```

```
"end_date": "1696821038"
```

```
}
```

```
}'
```

```
{
```

```
"status": "OK",
```

```
"response": [
```

```
"logs": [
```

```
"action": "Save Profile",
```

```
"details": {
```

```
"Profile Type": "Install App",
```

```
"Operating System": "macOS",
```

```
},
```

```
"username": "Catalog",
```

```
"action_date": "2021-03-01",
```

```
"ip": "127.0.0.1"
```

```
],
```

```
"rows": "1",
```

```
"page_size": 50,
```

```
"page": 1
```

```
]
```

## Mosyle Logs Stream - Mosyle Logs Stream (id 66)

To use the Mosyle Logs Stream API, you first need to configure the options under My School > Integrations > Mosyle Logs Stream. When configuring the integration method, choose “Mosyle Logs Stream API”.

Obtain Access Token
Once Mosyle Logs Stream API is configured, you will see your access token and the option to configure the Access Method as well as select the Log Streams of interest.

You’ll make requests to the endpoint "https://schoolapilogs.mosyle.com/v1”. The Mosyle API supports the POST request method. All API responses are structured in JSON format.




Request Bearer Token
To start, make a request to the Mosyle API endpoint "/login" including the email and password in the body of the request and the access token in the header.

Example request:


1
curl --include --location 'https://schoolapilogs.mosyle.com/v1/login' \
2
--header 'accessToken: Access_Token' \
3
--header 'Content-Type: application/json' \
4
--data-raw '{
5
    "email" : "User_Email",
6
    "password" : "User_Password"
7
}'


Example response:

1
HTTP/1.1 200 OK
2
Date: Mon, 21 Aug 2023 17:31:09 GMT
3
Server: Apache
4
X-Frame-Options: SAMEORIGIN
5
X-XSS-Protection: 1; mode=block
6
X-Content-Type-Options: nosniff
7
Content-Security-Policy: frame-src 'self' 'unsafe-eval' 'unsafe-inline' *.mosyle.com frame-ancestors 'self' *.mosyle.com ;default-src 'self' 'unsafe-inline' 'unsafe-eval' *.googleapis.com  *.mosyle.com *.windows.net *.stripe.com *.apple-mapkit.com *.apple.com
8
Strict-Transport-Security: max-age=63072000; includeSubdomains;
9
Set-Cookie: PHPSESSID=8901c23c1234e5678b901d2a34a56cc7; path=/; domain=.mosyle.com; secure; HttpOnly
10
Expires: Thu, 19 Nov 1981 08:52:00 GMT
11
Cache-Control: no-store, no-cache, must-revalidate
12
Pragma: no-cache
13
Authorization: Bearer Bearer_Token
14
Content-Length: 59
15
Content-Type: application/json
16
​
17
{"UserID":"User_ID","email":"User_Email"}


The response will contain a Bearer Token as a JSON Web Token (JWT) in the header which will be needed for subsequent requests. The token will expire every 24 hours and will need to be renewed.

When accessing any other Mosyle Logs Stream API endpoints, include the string "Bearer" followed by the JWT in the request header along with the access token.




*Note: If you are using PowerShell, you will need to utilize 'Invoke-WebRequest' to view the Bearer token to then parse or copy/paste it as necessary. 


The following snippet will be used in all subsequent requests:


1
curl --location 'https://schoolapilogs.mosyle.com/v1' \
2
--header 'Content-Type: application/json' \
3
--header 'accessToken: Access_Token' \
4
--header 'Authorization: Bearer Bearer_Token' \




Request Logs Stream

When you access the Mosyle Logs Stream API endpoint /logsstream, all selected logs will be listed.

You can pass an additional parameter to filter your search or change the result.




Available options:
Key	Type	Required	Description
LogType	String [array]	Required
	Array containing the types of logs you want to retrieve (among those selected previously in Mosyle Logs Stream Form). Available options: zero_trust, action_logs, compliance, av, and dns.
page	Integer	Optional	Default 1
50 results per page


Example request:

1
curl --location 'https://schoolapilogs.mosyle.com/v1/logsstream' \
2
--header 'Content-Type: application/json' \
3
--header 'accessToken: Access_Token' \
4
--header 'Authorization: Bearer Bearer_Token' \
5
--data '{
6
    "LogType": [
7
            "zero_trust",
8
            "action_logs",
9
            "compliance",
10
            "av",
11
            "dns"
12
            ]
13
}'



Example Response:

1
{
2
  "status": "OK",
3
  "response": {
4
    "av": {
5
      "Logs": [
6
        
7
      ],
8
      "Page": 1,
9
      "ItensPerPage": 5000,
10
      "TotalLogs": 0,
11
      "TotalPages": 1
12
    },
13
    "zero_trust": {
14
      "Events": {
15
        "TotalLogs": 1,
16
        "TotalPages": 1,
17
        "Page": 1,
18
        "ItensPerPage": 2500,
19
        "Logs": [
20
          {
21
            "Device": "MacBook Air",
22
            "Application": "com.google.Chrome.UpdaterPrivilegedHelper",
23
            "FileName": "com.google.Chrome.UpdaterPrivilegedHelper",
24
            "Action": "Trusted",
25
            "Source": "Manual",
26
            "Timestamp": "1710264696",
27
            "Identifier": "com.google.Chrome.UpdaterPrivilegedHelper",
28
            "Hash": "4e28088b...",
29
            "SigningID": "com.google.Chrome.UpdaterPrivilegedHelper",
30
            "Path": "/Applications/Google Chrome.app/Contents/Library/LaunchServices/com.google.Chrome.UpdaterPrivilegedHelper",
31
            "FileType": "Binary"
32
          }
33
        ]
34
      }
35
    },
36
    "dns": [
37
      
38
    ],
39
    "compliance": {
40
      "macOS": {
41
        "Page": 1,
42
        "ItensPerPage": 2500,
43
        "TotalLogs": 0,
44
        "TotalPages": 0,
45
        "Logs": [
46
          
47
        ]
48
      },
49
      "iOS": {
50
        "Page": 1,
51
        "ItensPerPage": 2500,
52
        "TotalLogs": 1,
53
        "TotalPages": 1,
54
        "Logs": [
55
          {
56
            "Status": "Lost Compliance",
57
            "RuleName": "Cookies are allowed from visited websites only",
58
            "Timestamp": "01:00 PM - 03/12/2024",
59
            "DeviceName": "iPad 100",
60
            "SerialNumber": "123456CD78",
61
            "E-mail": "test@mail.com"
62
          }
63
        ]
64
      }
65
    },
66
    "action_logs": {
67
      "Page": 1,
68
      "ItensPerPage": 5000,
69
      "TotalLogs": 2,
70
      "TotalPages": 1,
71
      "Logs": [
72
        {
73
          "UserName": "Jane Smith",
74
          "Action": "Save Device Group",
75
          "ActionDate": "1710267184",
76
          "Content": "Name: ##DEVICE GROUP VS\n",
77
          "IP": "::1",
78
          "E-mail": "jane.smith@mail.com"
79
        },
80
        {
81
          "UserName": "John Doe",
82
          "Action": "Save Mosyle Logs Stream Profile",
83
          "ActionDate": "1710267152",
84
          "Content": "Profile Name: #1 - John Doe\nProfile Type: Mosyle Logs Stream\n",
85
          "IP": "192.168.65.1",
86
          "E-mail": "john.doe@mosyle.com"
87
        }
88
      ]
89
    }
90
  }
91
}

```
curl --include --location 'https://schoolapilogs.mosyle.com/v1/login' \
--header 'accessToken: Access_Token' \
--header 'Content-Type: application/json' \
--data-raw '{
    "email" : "User_Email",
    "password" : "User_Password"
}'
```

```
HTTP/1.1 200 OK
Date: Mon, 21 Aug 2023 17:31:09 GMT
Server: Apache
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
Content-Security-Policy: frame-src 'self' 'unsafe-eval' 'unsafe-inline' *.mosyle.com frame-ancestors 'self' *.mosyle.com ;default-src 'self' 'unsafe-inline' 'unsafe-eval' *.googleapis.com  *.mosyle.com *.windows.net *.stripe.com *.apple-mapkit.com *.apple.com
Strict-Transport-Security: max-age=63072000; includeSubdomains;
Set-Cookie: PHPSESSID=8901c23c1234e5678b901d2a34a56cc7; path=/; domain=.mosyle.com; secure; HttpOnly
Expires: Thu, 19 Nov 1981 08:52:00 GMT
Cache-Control: no-store, no-cache, must-revalidate
Pragma: no-cache
Authorization: Bearer Bearer_Token
Content-Length: 59
Content-Type: application/json

{"UserID":"User_ID","email":"User_Email"}
```

```
curl --location 'https://schoolapilogs.mosyle.com/v1' \
--header 'Content-Type: application/json' \
--header 'accessToken: Access_Token' \
--header 'Authorization: Bearer Bearer_Token' \
```

```
curl --location 'https://schoolapilogs.mosyle.com/v1/logsstream' \
--header 'Content-Type: application/json' \
--header 'accessToken: Access_Token' \
--header 'Authorization: Bearer Bearer_Token' \
--data '{
	"LogType": [
            "zero_trust",
            "action_logs",
            "compliance",
            "av",
            "dns"
            ]
}'
```

```
{
  "status": "OK",
  "response": {
    "av": {
      "Logs": [
        
      ],
      "Page": 1,
      "ItensPerPage": 5000,
      "TotalLogs": 0,
      "TotalPages": 1
    },
    "zero_trust": {
      "Events": {
        "TotalLogs": 1,
        "TotalPages": 1,
        "Page": 1,
        "ItensPerPage": 2500,
        "Logs": [
          {
            "Device": "MacBook Air",
            "Application": "com.google.Chrome.UpdaterPrivilegedHelper",
            "FileName": "com.google.Chrome.UpdaterPrivilegedHelper",
            "Action": "Trusted",
            "Source": "Manual",
            "Timestamp": "1710264696",
            "Identifier": "com.google.Chrome.UpdaterPrivilegedHelper",
            "Hash": "4e28088b...",
            "SigningID": "com.google.Chrome.UpdaterPrivilegedHelper",
            "Path": "/Applications/Google Chrome.app/Contents/Library/LaunchServices/com.google.Chrome.UpdaterPrivilegedHelper",
            "FileType": "Binary"
          }
        ]
      }
    },
    "dns": [
      
    ],
    "compliance": {
      "macOS": {
        "Page": 1,
        "ItensPerPage": 2500,
        "TotalLogs": 0,
        "TotalPages": 0,
        "Logs": [
          
        ]
      },
      "iOS": {
        "Page": 1,
        "ItensPerPage": 2500,
        "TotalLogs": 1,
        "TotalPages": 1,
        "Logs": [
          {
            "Status": "Lost Compliance",
            "RuleName": "Cookies are allowed from visited websites only",
            "Timestamp": "01:00 PM - 03/12/2024",
            "DeviceName": "iPad 100",
            "SerialNumber": "123456CD78",
            "E-mail": "test@mail.com"
          }
        ]
      }
    },
    "action_logs": {
      "Page": 1,
      "ItensPerPage": 5000,
      "TotalLogs": 2,
      "TotalPages": 1,
      "Logs": [
        {
          "UserName": "Jane Smith",
          "Action": "Save Device Group",
          "ActionDate": "1710267184",
          "Content": "Name: ##DEVICE GROUP VS\n",
          "IP": "::1",
          "E-mail": "jane.smith@mail.com"
        },
        {
          "UserName": "John Doe",
          "Action": "Save Mosyle Logs Stream Profile",
          "ActionDate": "1710267152",
          "Content": "Profile Name: #1 - John Doe\nProfile Type: Mosyle Logs Stream\n",
          "IP": "192.168.65.1",
          "E-mail": "john.doe@mosyle.com"
        }
      ]
    }
  }
}
```

```
curl --include --location 'https://schoolapilogs.mosyle.com/v1/login' \
```

```
--header 'accessToken: Access_Token' \
```

```
--header 'Content-Type: application/json' \
```

```
--data-raw '{
```

```
"email" : "User_Email",
```

```
"password" : "User_Password"
```

```
}'
```

```
HTTP/1.1 200 OK
```

```
Date: Mon, 21 Aug 2023 17:31:09 GMT
```

```
Server: Apache
```

```
X-Frame-Options: SAMEORIGIN
```

```
X-XSS-Protection: 1; mode=block
```

```
X-Content-Type-Options: nosniff
```

```
Content-Security-Policy: frame-src 'self' 'unsafe-eval' 'unsafe-inline' *.mosyle.com frame-ancestors 'self' *.mosyle.com ;default-src 'self' 'unsafe-inline' 'unsafe-eval' *.googleapis.com  *.mosyle.com *.windows.net *.stripe.com *.apple-mapkit.com *.apple.com
```

```
Strict-Transport-Security: max-age=63072000; includeSubdomains;
```

```
Set-Cookie: PHPSESSID=8901c23c1234e5678b901d2a34a56cc7; path=/; domain=.mosyle.com; secure; HttpOnly
```

```
Expires: Thu, 19 Nov 1981 08:52:00 GMT
```

```
Cache-Control: no-store, no-cache, must-revalidate
```

```
Pragma: no-cache
```

```
Authorization: Bearer Bearer_Token
```

```
Content-Length: 59
```

```
Content-Type: application/json
```

```
​
```

```
{"UserID":"User_ID","email":"User_Email"}
```

```
curl --location 'https://schoolapilogs.mosyle.com/v1' \
```

```
--header 'Authorization: Bearer Bearer_Token' \
```

```
curl --location 'https://schoolapilogs.mosyle.com/v1/logsstream' \
```

```
--data '{
```

```
"LogType": [
```

```
"zero_trust",
```

```
"action_logs",
```

```
"compliance",
```

```
"av",
```

```
"dns"
```

```
]
```

```
{
```

```
"status": "OK",
```

```
"response": {
```

```
"av": {
```

```
"Logs": [
```

```
],
```

```
"Page": 1,
```

```
"ItensPerPage": 5000,
```

```
"TotalLogs": 0,
```

```
"TotalPages": 1
```

```
},
```

```
"zero_trust": {
```

```
"Events": {
```

```
"TotalLogs": 1,
```

```
"TotalPages": 1,
```

```
"ItensPerPage": 2500,
```

```
"Device": "MacBook Air",
```

```
"Application": "com.google.Chrome.UpdaterPrivilegedHelper",
```

```
"FileName": "com.google.Chrome.UpdaterPrivilegedHelper",
```

```
"Action": "Trusted",
```

```
"Source": "Manual",
```

```
"Timestamp": "1710264696",
```

```
"Identifier": "com.google.Chrome.UpdaterPrivilegedHelper",
```

```
"Hash": "4e28088b...",
```

```
"SigningID": "com.google.Chrome.UpdaterPrivilegedHelper",
```

```
"Path": "/Applications/Google Chrome.app/Contents/Library/LaunchServices/com.google.Chrome.UpdaterPrivilegedHelper",
```

```
"FileType": "Binary"
```

```
}
```

```
"dns": [
```

```
"compliance": {
```

```
"macOS": {
```

```
"TotalPages": 0,
```

```
"iOS": {
```

```
"Status": "Lost Compliance",
```

```
"RuleName": "Cookies are allowed from visited websites only",
```

```
"Timestamp": "01:00 PM - 03/12/2024",
```

```
"DeviceName": "iPad 100",
```

```
"SerialNumber": "123456CD78",
```

```
"E-mail": "test@mail.com"
```

```
"action_logs": {
```

```
"TotalLogs": 2,
```

```
"UserName": "Jane Smith",
```

```
"Action": "Save Device Group",
```

```
"ActionDate": "1710267184",
```

```
"Content": "Name: ##DEVICE GROUP VS\n",
```

```
"IP": "::1",
```

```
"E-mail": "jane.smith@mail.com"
```

```
"UserName": "John Doe",
```

```
"Action": "Save Mosyle Logs Stream Profile",
```

```
"ActionDate": "1710267152",
```

```
"Content": "Profile Name: #1 - John Doe\nProfile Type: Mosyle Logs Stream\n",
```

```
"IP": "192.168.65.1",
```

```
"E-mail": "john.doe@mosyle.com"
```

## Custom Device Attributes - List Custom Device Attributes (id 67)

To list the Custom Device Attributes you will access the Mosyle API endpoint /customdeviceattribute and pass the value list_custom_device_attributes through the parameter operation.




Key	Type	
	Description
operation	String	Required	list_custom_device_attributes
os	String	Required
	OS of the devices with the Custom Device Attribute [ios, tvos, mac, visionos]




Example request:

1
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "list_custom_device_attributes",
9
            "os": "mac"
10
        }
11
    ]
12
}'




Example response:

1
{
2
  "status": "OK",
3
  "response": [
4
    {
5
      "status": "OK",
6
      "info": [
7
        {
8
          "Name": "Custom Device Attribute",
9
          "UniqueID": "custom_cda",
10
          "Value": "1234value",
11
          "LastUpdate": "1710266724",
12
          "Source": "API",
13
          "OS": "mac",
14
          "IsDeleted": "0"
15
        }
16
      ]
17
    }
18
  ]
19
}

```
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "list_custom_device_attributes",
            "os": "mac"
        }
    ]
}'
```

```
{
  "status": "OK",
  "response": [
    {
      "status": "OK",
      "info": [
        {
          "Name": "Custom Device Attribute",
          "UniqueID": "custom_cda",
          "Value": "1234value",
          "LastUpdate": "1710266724",
          "Source": "API",
          "OS": "mac",
          "IsDeleted": "0"
        }
      ]
    }
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "list_custom_device_attributes",
```

```
"os": "mac"
```

```
}
```

```
]
```

```
}'
```

```
"status": "OK",
```

```
"response": [
```

```
"info": [
```

```
"Name": "Custom Device Attribute",
```

```
"UniqueID": "custom_cda",
```

```
"Value": "1234value",
```

```
"LastUpdate": "1710266724",
```

```
"Source": "API",
```

```
"OS": "mac",
```

```
"IsDeleted": "0"
```

## Custom Device Attributes - Create Custom Device Attributes (id 68)

To create Custom Device Attributes you will access the Mosyle API endpoint /customdeviceattribute and pass the value create_custom_device_attributes through the parameter operation.





Key	Type		Description
operation	String	Required
	create_custom_device_attributes
os	String	Required
	OS of the devices with the Custom Device Attribute [ios, tvos, mac, visionos]
unique_id	String	Required	Unique ID of the Custom Device Attribute
name	String	Required	Name of the Custom Device Attribute
value	String	Required	Designated Value of the Custom Device Attribute
devices	String [array]	Required	List of device UDIDs to be assigned the Custom Device Attribute


Example Request:

1
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "create_custom_device_attributes",
9
            "os": "mac",
10
            "unique_id": "custom_cda",
11
            "name": "Custom Device Attribute",
12
            "value": "1234Value",
13
            "devices": [
14
                "A000DA0A-F0EF-000C-0C0B-0BA000C00000"
15
            ]
16
        }
17
    ]
18
}'




Example Response:

{
"status": "OK",
"response": [
{
"status": "OK",
"info": "Custom Device Attribute saved successfully"
}
]
}

```
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "create_custom_device_attributes",
            "os": "mac",
            "unique_id": "custom_cda",
            "name": "Custom Device Attribute",
            "value": "1234Value",
            "devices": [
                "A000DA0A-F0EF-000C-0C0B-0BA000C00000"
            ]
        }
    ]
}'
```

```
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "create_custom_device_attributes",
```

```
"os": "mac",
```

```
"unique_id": "custom_cda",
```

```
"name": "Custom Device Attribute",
```

```
"value": "1234Value",
```

```
"devices": [
```

```
"A000DA0A-F0EF-000C-0C0B-0BA000C00000"
```

```
]
```

```
}
```

```
}'
```

## Custom Device Attributes - Assign Custom Device Attributes (id 69)

To assign Custom Device Attributes to devices you will access the Mosyle API endpoint /customdeviceattribute and pass the value assign_custom_device_attributes through the parameter operation.



Key	Type		Description
operation	String	Required
	assign_custom_device_attributes
os	String	Required
	OS of the devices with the Custom Device Attribute [ios, tvos, mac, visionos]
unique_id	String	Required	Unique ID of the Custom Device Attribute
value	String	Required	Value of the Custom Device Attribute to be assigned
devices	String [array]	Required	List of device UDIDs to be assigned the Custom Device Attribute


Example Request:

1
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "assign_custom_device_attributes",
9
            "os": "mac",
10
            "unique_id": "custom_cda",
11
            "value": "Custom Attribute",
12
            "devices": [
13
                "A000DA0A-F0EF-000C-0C0B-0BA000C00000"
14
            ]
15
        }
16
    ]
17
}'



Example Response:
1
{
2
  "status": "OK",
3
  "response": {
4
  {
5
      "status": "OK",
6
      "info": "Custom Device Attribute assigned successfully"
7
    }
8
  }
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "assign_custom_device_attributes",
            "os": "mac",
            "unique_id": "custom_cda",
            "value": "Custom Attribute",
            "devices": [
                "A000DA0A-F0EF-000C-0C0B-0BA000C00000"
            ]
        }
    ]
}'
```

```
{
  "status": "OK",
  "response": {
  {
      "status": "OK",
      "info": "Custom Device Attribute assigned successfully"
    }
  }
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "assign_custom_device_attributes",
```

```
"os": "mac",
```

```
"unique_id": "custom_cda",
```

```
"value": "Custom Attribute",
```

```
"devices": [
```

```
"A000DA0A-F0EF-000C-0C0B-0BA000C00000"
```

```
]
```

```
}
```

```
}'
```

```
"status": "OK",
```

```
"response": {
```

```
"info": "Custom Device Attribute assigned successfully"
```

## Custom Device Attributes - Update Custom Device Attributes (id 70)

To update Custom Device Attributes you will access the Mosyle API endpoint /customdeviceattribute and pass the value update_custom_device_attributes through the parameter operation.



To update the value of a Custom Device Attribute, the old_unique_id and unique_id will remain the same. Just pass the updated value on the request.


Key	Type		Description
operation	String	Required
	update_custom_device_attributes
os	String	Required
	OS of the devices with the Custom Device Attribute [ios, tvos, mac, visionos]
old_unique_id	String	Required	Original Unique ID of the Custom Device Attribute that will be updated
unique_id	String	Required	Unique ID of the updated Custom Device Attribute
name	String	Required	Name of the Custom Device Attribute
value	String	Required	Designated Value of the Custom Device Attribute


Example Request:

1
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "update_custom_device_attributes",
9
            "os": "mac",
10
            "old_unique_id": "custom_cda",
11
            "unique_id": "new_custom_cda",
12
            "name": "Custom Device Attribute",
13
            "value": "1234Value"
14
        }
15
    ]
16
}'




Example Response:

1
{
2
  "status": "OK",
3
  "response": {
4
  {
5
      "status": "OK",
6
      "info": "Custom Device Attribute saved successfully"
7
    }
8
  }
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "update_custom_device_attributes",
            "os": "mac",
            "old_unique_id": "custom_cda",
            "unique_id": "new_custom_cda",
            "name": "Custom Device Attribute",
            "value": "1234Value"
        }
    ]
}'
```

```
{
  "status": "OK",
  "response": {
  {
      "status": "OK",
      "info": "Custom Device Attribute saved successfully"
    }
  }
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "update_custom_device_attributes",
```

```
"os": "mac",
```

```
"old_unique_id": "custom_cda",
```

```
"unique_id": "new_custom_cda",
```

```
"name": "Custom Device Attribute",
```

```
"value": "1234Value"
```

```
}
```

```
]
```

```
}'
```

```
"status": "OK",
```

```
"response": {
```

```
"info": "Custom Device Attribute saved successfully"
```

## Custom Device Attributes - Remove Custom Device Attributes (id 71)

To remove the assignment of Custom Device Attributes from devices you will access the Mosyle API endpoint /customdeviceattribute and pass the value remove_custom_device_attributes through the parameter operation.





Key	Type		Description
operation	String	Required
	remove_custom_device_attributes
os	String	Required
	OS of the devices with the Custom Device Attribute [ios, tvos, mac, visionos]
unique_id	String	Required	Unique ID of the Custom Device Attribute
devices	String [array]	Required	List of device UDIDs to be removed/unassigned from the Custom Device Attribute


Example Request:

1
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "remove_custom_device_attributes",
9
            "os": "mac",
10
            "unique_id": "custom_cda",
11
            "devices": [
12
                "A000DA0A-F0EF-000C-0C0B-0BA000C00000"
13
            ]
14
        }
15
    ]
16
}'




Example Response:

1
{
2
  "status": "OK",
3
  "response": {
4
  {
5
      "status": "OK",
6
      "info": "Custom Device Attribute removed successfully"
7
    }
8
  }
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "remove_custom_device_attributes",
            "os": "mac",
            "unique_id": "custom_cda",
            "devices": [
                "A000DA0A-F0EF-000C-0C0B-0BA000C00000"
            ]
        }
    ]
}'
```

```
{
  "status": "OK",
  "response": {
  {
      "status": "OK",
      "info": "Custom Device Attribute removed successfully"
    }
  }
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "remove_custom_device_attributes",
```

```
"os": "mac",
```

```
"unique_id": "custom_cda",
```

```
"devices": [
```

```
"A000DA0A-F0EF-000C-0C0B-0BA000C00000"
```

```
]
```

```
}
```

```
}'
```

```
"status": "OK",
```

```
"response": {
```

```
"info": "Custom Device Attribute removed successfully"
```

## Custom Device Attributes - Delete Custom Device Attributes (id 72)

To delete a Custom Device Attribute you will access the Mosyle API endpoint /customdeviceattribute and pass the value delete_custom_device_attribute through the parameter operation.





Key	Type		Description
operation	String	Required
	delete_custom_device_attribute
os	String	Required
	OS of the devices with the Custom Device Attribute [ios, tvos, mac, visionos]
unique_id	String	Required	Unique ID of the Custom Device Attribute


Example Request:

1
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "elements": [
7
        {
8
            "operation": "delete_custom_device_attribute",
9
            "os": "mac",
10
            "unique_id": "new_custom_cda"
11
        }
12
    ]
13
}'






Example Response:

1
{
2
  "status": "OK",
3
  "response": {
4
  {
5
      "status": "OK",
6
      "info": "Custom Device Attribute deleted successfully"
7
    }
8
  }
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "elements": [
        {
            "operation": "delete_custom_device_attribute",
            "os": "mac",
            "unique_id": "new_custom_cda"
        }
    ]
}'
```

```
{
  "status": "OK",
  "response": {
  {
      "status": "OK",
      "info": "Custom Device Attribute deleted successfully"
    }
  }
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/customdeviceattribute' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"elements": [
```

```
{
```

```
"operation": "delete_custom_device_attribute",
```

```
"os": "mac",
```

```
"unique_id": "new_custom_cda"
```

```
}
```

```
]
```

```
}'
```

```
"status": "OK",
```

```
"response": {
```

```
"info": "Custom Device Attribute deleted successfully"
```

## Shared Device Group Operations - List Shared Device Groups (id 77)

You will hit the endpoint /listshareddevicegroups and can send parameters to filter your request for the specific info you want to receive in your response or receive all info about shared device groups.



Available options:

Key	Type	Required	Description
os	enum ('ios', 'mac', 'visionos')	Required	Operational system
specific_columns	Array of strings	Optional	Fields that will be returned
Allowed values: idshareddevicegroup, name, idaccount, number_of_devices, assigned_devices
idshareddevicegroup	integer	Optional	Selected group ID
idaccount	integer	Optional	Selected account ID
page	integer	Required	Pagination starting with 1


Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/listshareddevicegroups' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data '{
5
    "accessToken": "Access_Token",
6
    "options": {
7
        "os": "ios",
8
        "page": "1",
9
        "specific_columns": [
10
            "idshareddevicegroup",
11
            "name"
12
        ]
13
    }
14
}'




Example Response:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      groups: [
6
        {
7
          idshareddevicegroup: "210",
8
          name: "Shared Group"
9
        }
10
      ],
11
      rows: 1
12
      page_size: 50
13
      page: 1
14
    }
15
  ]
16
}


Without 'os' key:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      status: "MISSING_DATA",
6
      info: "Missing key: os"
7
    }
8
  ]
9
}

```
curl --location 'https://managerapi.mosyle.com/v2/listshareddevicegroups' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data '{
    "accessToken": "Access_Token",
    "options": {
        "os": "ios",
        "page": "1",
        "specific_columns": [
            "idshareddevicegroup",
            "name"
        ]
    }
}'
```

```
{
  status: "OK",
  response: [
    {
      groups: [
        {
          idshareddevicegroup: "210",
          name: "Shared Group"
        }
      ],
      rows: 1
      page_size: 50
      page: 1
    }
  ]
}
```

```
{
  status: "OK",
  response: [
    {
      status: "MISSING_DATA",
      info: "Missing key: os"
    }
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/listshareddevicegroups' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data '{
```

```
"accessToken": "Access_Token",
```

```
"options": {
```

```
"os": "ios",
```

```
"page": "1",
```

```
"specific_columns": [
```

```
"idshareddevicegroup",
```

```
"name"
```

```
]
```

```
}
```

```
}'
```

```
{
```

```
status: "OK",
```

```
response: [
```

```
groups: [
```

```
idshareddevicegroup: "210",
```

```
name: "Shared Group"
```

```
],
```

```
rows: 1
```

```
page_size: 50
```

```
page: 1
```

```
status: "MISSING_DATA",
```

```
info: "Missing key: os"
```

## Shared Device Group Operations - Add / Remove Device from Shared Device Group (id 78)

When you access the Mosyle API endpoint /shareddevicegroups passing the value assign_device through the parameter operation you can add or remove specific device UDIDs from a shared device group. This action requires the key parameter idshareddevicegroup to filter which Shared Device Group you want to add or remove the devices.




Available options:

Key	Type	Required	Description
operation	string	Required	assign_device
idshareddevicegroup	integer	Required	Shared Device Group ID
add	Array of strings	Optional*	List of the Device UDIDs to add to the specific shared device group
remove	Array of strings	Optional*	List of the Device UDIDs to remove from the specific shared device group

* At least one must be included




Example request:


1
curl --location 'https://managerapi.mosyle.com/v2/shareddevicegroups' \
2
--header 'Content-Type: application/json' \
3
--header 'Authorization: Bearer {{Bearer_Token}}' \
4
--data-raw '{
5
    "accessToken": "Access_Token",
6
    "operation": "assign_device",
7
    "idshareddevicegroup": "154",
8
    "add": ["AAAAAAAA-1234-4321-A1B2-AAAAAAAAAAAA"]
9
}'




Success Response:
1
{
2
  status: "OK",
3
  response: [
4
    {
5
      status: "OK",
6
      info: "110",
7
  ]
8
}

```
curl --location 'https://managerapi.mosyle.com/v2/shareddevicegroups' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{Bearer_Token}}' \
--data-raw '{
    "accessToken": "Access_Token",
    "operation": "assign_device",
    "idshareddevicegroup": "154",
    "add": ["AAAAAAAA-1234-4321-A1B2-AAAAAAAAAAAA"]
}'
```

```
{
  status: "OK",
  response: [
    {
      status: "OK",
      info: "110",
  ]
}
```

```
curl --location 'https://managerapi.mosyle.com/v2/shareddevicegroups' \
```

```
--header 'Content-Type: application/json' \
```

```
--header 'Authorization: Bearer {{Bearer_Token}}' \
```

```
--data-raw '{
```

```
"accessToken": "Access_Token",
```

```
"operation": "assign_device",
```

```
"idshareddevicegroup": "154",
```

```
"add": ["AAAAAAAA-1234-4321-A1B2-AAAAAAAAAAAA"]
```

```
}'
```

```
{
```

```
status: "OK",
```

```
response: [
```

```
info: "110",
```

```
]
```

```
}
```

# Mosyle Manager API - operation map

Index of the paid API's documented surface, regenerated 2026-07-24 from a live paid
tenant (the original 2026-07-18 scrape was lost in a folder move; recovered method and
history: stmc-manager `apis/mosyle-paid-api-recovery-notes.md`).

Full article bodies: [mosyle-api-docs.md](mosyle-api-docs.md) / [mosyle-api-docs.json](mosyle-api-docs.json).

**Free-tier schools (no API token): do not use this map against `managerapi.mosyle.com`.**
Use [MosyleFreeKit](../MosyleFreeKit/) instead (browser-session UI bus).

**Notably absent (settled 2026-07-23, do not re-hunt):** there is NO update-info /
blank-push / refresh bulk operation in the paid API - paid MDM auto-sends Device
Information hourly and full Update Info daily; "Send Update Info" is a web-UI button only.

| id | Article | Endpoint(s) | Operation(s) |
|---|---|---|---|
| 32 | First Steps - How to make a Request using the API | `v2/listusers`, `v2/login` | - |
| 44 | Devices Operations - List Devices | `v2/listdevices` | - |
| 62 | Devices Operations - Lock Devices | `v2/bulkops` | `lock_device` |
| 56 | Devices Operations - Lost Mode (only iOS) | `v2/lostmode` | `enable` |
| 60 | Devices Operations - Unassign Devices | `v2/bulkops` | `change_to_limbo` |
| 43 | Devices Operations - Update Device Attributes | `v2/devices` | - |
| 47 | Devices Operations - Bulk Operations - Wipe Devices | `v2/bulkops` | `wipe_devices` |
| 48 | Devices Operations - Bulk Operations - Restart Devices | `v2/bulkops` | `restart_devices` |
| 49 | Devices Operations - Bulk Operations - Shutdown Devices | `v2/bulkops` | `shutdown_devices` |
| 52 | Devices Operations - Bulk Operations - Clear Commands | `v2/bulkops` | `clear_commands` |
| 73 | Devices Operations - Bulk Operations - Activation Lock | `v1/bulkops` | `disable_activationlock`, `enable_activationlock` |
| 75 | Devices Operations - Bulk Operations - Move Devices to Accounts (District Only) | `v2/bulkops` | `move_device_account` |
| 76 | Devices Operations - Bulk Operations - Change/Update Limbo Location | `v2/bulkops` | `update_limbo_location` |
| 36 | Users Operations - List Users | `v2/listusers` | - |
| 34 | Users Operations - Create Users | `v2/users` | `save` |
| 74 | Users Operations - Update Users | `v2/users` | `update` |
| 45 | Users Operations - Delete User | `v2/users` | `delete` |
| 46 | Users Operations - Assign Devices | `v2/users` | `assign_device` |
| 37 | Classes - Save and Delete Classes | `v2/classes` | `save` |
| 57 | Classes - List Classes | `v2/listclasses` | - |
| 38 | Accounts (District Only) - Get Accounts | `v2/accounts` | - |
| 40 | Accounts (District Only) - Create new Account | `v2/accounts` | `request` |
| 41 | Cisco ISE - Cisco ISE - Add and remove Devices | `v2/ciscoise` | - |
| 42 | Cisco ISE - Cisco ISE - Get Device | `v2/getciscoise` | - |
| 55 | Dynamic Device Groups Operations - List Dynamic Device Groups | `v2/listdevicegroups` | - |
| 58 | Dynamic Device Groups Operations - List Devices | `v2/listdevicesbygroup` | - |
| 64 | Dynamic Device Groups Operations - Add / Remove Device from Dynamic Device Group | `v2/devicegroups` | `update_devices` |
| 65 | Dynamic Device Groups Operations - List Devices in Device Groups | `v2/listdevicegroupsdevices` | - |
| 79 | Dynamic Device Groups Operations - Specific iOS/iPadOS Rules | `v2/iossecuritycontrolscompliance` | - |
| 61 | Action Logs - List | `v2/adminlogs` | - |
| 66 | Mosyle Logs Stream - Mosyle Logs Stream | - | - |
| 67 | Custom Device Attributes - List Custom Device Attributes | `v2/customdeviceattribute` | `list_custom_device_attributes` |
| 68 | Custom Device Attributes - Create Custom Device Attributes | `v2/customdeviceattribute` | `create_custom_device_attributes` |
| 69 | Custom Device Attributes - Assign Custom Device Attributes | `v2/customdeviceattribute` | `assign_custom_device_attributes` |
| 70 | Custom Device Attributes - Update Custom Device Attributes | `v2/customdeviceattribute` | `update_custom_device_attributes` |
| 71 | Custom Device Attributes - Remove Custom Device Attributes | `v2/customdeviceattribute` | `remove_custom_device_attributes` |
| 72 | Custom Device Attributes - Delete Custom Device Attributes | `v2/customdeviceattribute` | `delete_custom_device_attribute` |
| 77 | Shared Device Group Operations - List Shared Device Groups | `v2/listshareddevicegroups` | - |
| 78 | Shared Device Group Operations - Add / Remove Device from Shared Device Group | `v2/shareddevicegroups` | `assign_device` |

# MosyleKit

A modern, cross-platform PowerShell 7 module for the [Mosyle Manager](https://mosyle.com/) API.

- **JWT auth, handled.** `Connect-Mosyle` logs in with your access token + an admin email/password, reads the bearer token from the login response header, and renews it automatically before the 24-hour expiry.
- **The whole API from one cmdlet.** Every Mosyle operation is a `POST /v2/<endpoint>` with `accessToken` in the body — so `Invoke-MosyleApi -Endpoint <name>` reaches all of it today, with token renewal, retry/backoff, and Mosyle's in-body `status: ERROR` responses surfaced as real errors.
- **Typed cmdlets** for the common reads, with more to come as payloads are confirmed against the API docs.
- **Strict-mode clean**, PowerShell 7.4+, CI on macOS/Linux/Windows.

## Quick start

```powershell
# Access token: My School > API Integration (paid feature). Email/password: an admin with API permissions.
Connect-Mosyle -AccessToken (Get-Secret MosyleToken) -Credential (Get-Credential)

Get-MosyleUser -Column id, name, email
Get-MosyleDevice -Os ios
```

### The whole API via the generic cmdlet

```powershell
Invoke-MosyleApi -Endpoint listusers -Body @{ options = @{ specific_columns = @('id','name') } }
Invoke-MosyleApi -Endpoint listdynamicgroups
Invoke-MosyleApi -Endpoint listclasses
# Write operations prompt (ShouldProcess); -WhatIf to preview:
Invoke-MosyleApi -Endpoint wipe -Body @{ devices = @($udid) } -WhatIf
```

## Cmdlets (v0.1)

| Area | Cmdlets |
|---|---|
| Session | `Connect-Mosyle`, `Disconnect-Mosyle`, `Get-MosyleSession` |
| Whole API | `Invoke-MosyleApi` |
| Typed reads | `Get-MosyleUser`, `Get-MosyleDevice` |

## Status &amp; roadmap

This is an early scaffold. The **session/auth core and the generic `Invoke-MosyleApi` are complete
and correct** — that generic cmdlet already covers every documented operation (list/create/update
devices, users, classes, dynamic & shared device groups, custom attributes, action logs, Cisco ISE,
district accounts). The typed cmdlets so far cover the operations whose exact request/response
shapes are confirmed (`listusers` from Mosyle's own PowerShell example; `listdevices` follows the
same options pattern).

Planned, pending payload confirmation from the API docs:
- Typed device operations: lock, lost mode, unassign, update attributes, bulk wipe/restart/shutdown/clear-commands/activation-lock
- Typed user CRUD (create/update/delete, assign devices) and class save/delete
- Dynamic & shared device groups, custom device attributes, action logs
- Shared request/retry core with the other JamfKit modules at build time

The operation map extracted from the Mosyle docs lives at
[`../../mosyle-api-docs/MOSYLE-API-MAP.md`](../../mosyle-api-docs/MOSYLE-API-MAP.md) (outside the
module tree). If you have a doc article's request/response body, paste it and the matching typed
cmdlet can be finalized.

## Development

```powershell
./build.ps1            # analyze + test + package
```

Same conventions as the other modules: one function per file, single mocked HTTP seam, no network in tests.

## License

[MIT](../LICENSE)

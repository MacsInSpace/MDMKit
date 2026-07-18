# Changelog

All notable changes to MosyleKit are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[SemVer](https://semver.org/).

## [Unreleased]

## [0.3.0-alpha] - 2026-07-19

### Added
- `Remove-MosyleUser` (/users delete) and `Set-MosyleDeviceOwner`
  (/users assign_device) — batched when piped.
- `Invoke-MosyleLostMode` (/lostmode): Enable/Disable/PlaySound/RequestLocation
  with message, phone number and footnote.
- Extended `Invoke-MosyleDeviceCommand`: Unassign (change_to_limbo) and
  ClearCommands / ClearPendingCommands / ClearFailedCommands, with the
  COMMAND_CLEARED status treated as success.
- Classes: `Get-MosyleClass`, `New-MosyleClass`, `Remove-MosyleClass`.
- Dynamic device groups: `Get-MosyleDeviceGroup`, `Get-MosyleDeviceGroupDevice`,
  `Set-MosyleDeviceGroupMember` (top-level `update_devices` payload).
- Custom device attributes: `Get-/New-/Set-/Remove-MosyleCustomAttribute`.
- `Get-MosyleActionLog` (/adminlogs, `filter_options`).

### Changed
- `Select-MosyleResult` now unwraps nested `response` objects/arrays as well as
  top-level keys — so list endpoints that wrap their payload under `response`
  (e.g. `/listdevices` → `response.devices`) return the collection directly.

### Notes
- All shapes above are taken from the full Mosyle API docs. Two documented
  quirks are handled deliberately: the custom-attribute delete operation is
  singular (`delete_custom_device_attribute`), and `/devicegroups` +
  `/adminlogs` use non-standard body keys. Activation Lock is documented at
  `/v1/bulkops` in one place while every other bulkops op is `/v2`; this module
  uses `/v2` for consistency — flip via Invoke-MosyleApi if a tenant needs v1.

## [0.2.0-alpha] - 2026-07-18

### Added
- `Invoke-MosyleDeviceCommand`: unified bulk device commands via `/bulkops`
  (Restart, Shutdown, Wipe, Lock, Enable/DisableActivationLock), targeting by
  UDID and/or device group ID, with command-specific options (lock pincode/
  message, wipe RevokeVPPLicenses/PreserveDataPlan/etc, activation-lock lost
  message). Surfaces `devices_notfound` and non-success statuses as warnings.
- `Set-MosyleDeviceAttribute`: update asset tag, tags, name and lock message
  via `/devices`, batching piped rows into one request.
- `New-MosyleUser` / `Set-MosyleUser`: bulk user create/update via `/users`
  (operations save/update), with normalized location/grade entries; piped
  rosters batch into a single call.

### Changed
- `Get-MosyleDevice`: `-Os` is now required (ios/mac/tvos/visionos) matching the
  API, with new `-Tag`, `-OsVersion`, `-SerialNumber` and `-Page` filters.

### Notes
- Request/response shapes for the above are confirmed from the Mosyle API docs.
  The list-endpoint `options` wrapper is applied consistently with the documented
  `/listusers` example; verify against a live tenant during testing.

## [0.1.0-alpha] - 2026-07-18

### Added
- JWT session core: `Connect-Mosyle` (access token + admin email/password),
  reads the bearer token from the /login response header, renews automatically
  before the 24-hour expiry; `Disconnect-Mosyle`, `Get-MosyleSession`.
- Hardened request engine: accessToken injected into every body, bearer header
  applied, retry with backoff honoring Retry-After, one-shot re-login on
  401/403, and Mosyle's in-body `status: ERROR` responses surfaced as errors.
- `Invoke-MosyleApi`: generic POST reaching the entire API (every operation is
  POST /v2/<endpoint>); reads run unconfirmed, writes honor ShouldProcess.
- Typed reads: `Get-MosyleUser` (listusers, confirmed shape) and
  `Get-MosyleDevice` (listdevices) with specific_columns / os options.
- Pester suite (14 tests, fully mocked); cross-platform CI job; flattening
  build script; tag-scoped publish workflow.

### Notes
- Early scaffold. The auth core and generic cmdlet are complete; typed cmdlets
  cover only operations whose exact payloads are confirmed. The full operation
  map is in mosyle-api-docs/MOSYLE-API-MAP.md.

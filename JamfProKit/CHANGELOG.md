# Changelog

All notable changes to JamfProKit are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[SemVer](https://semver.org/).

## [Unreleased]

## [0.3.0-alpha] - 2026-07-18

### Added
- Category CRUD: `Get/New/Set/Remove-JamfCategory` (Jamf Pro API v1/categories).
- Group CRUD across all three types (`-Type Computer|MobileDevice|User`):
  `Get/New/Set/Remove-JamfGroup` for smart and static groups, plus
  `New-JamfCriterion` for building smart group criteria with auto-numbered
  priorities.
- Package CRUD: `Get/New/Set/Remove-JamfPackage` (Jamf Pro API v1/packages,
  Jamf Pro 11.5+).
- `Publish-JamfPackage`: uploads a package file to cloud distribution via
  POST /v1/packages/{id}/upload — finds or creates the record by fileName,
  streams the file as multipart form data, and can `-WaitForHash` until Jamf
  computes the server-side hash.
- Request engine: multipart `-Form` support and per-request `-TimeoutSec`
  (uploads default to 1 hour).

## [0.2.0-alpha] - 2026-07-18

### Added
- Full MUT template parity: `Update-JamfMobileDevice` (Classic inventory writes plus
  the chained Jamf Pro API PATCH for Display Name / Enforce Name, with device-ID
  resolution from the Classic response or by serial lookup) and `Update-JamfUser`
  (rename, dual email fields, LDAP server assignment with `CLEAR!` → -1, sites,
  Managed Apple ID, numeric-username heuristic with
  `-NumericIdentifiersAreNames` override).
- `EA_<id>` CSV column support across all three bulk update cmdlets — MUT templates
  with extension attribute columns now pipe straight in; explicit
  `-ExtensionAttribute` values override CSV columns.
- `Set-JamfPrestageScope`: add/remove/replace serials in computer and mobile device
  PreStage scopes with automatic `versionLock` refetch-and-retry on optimistic
  concurrency conflicts.

## [0.1.0-alpha] - 2026-07-18

### Added
- Session core: `Connect-JamfPro` (OAuth client credentials + user bearer flows,
  SecretManagement-friendly), `Disconnect-JamfPro`, `Get-JamfSession`; automatic
  token renewal with keep-alive and expiry buffering; Jamf Cloud sticky-session
  cookie support.
- Hardened request engine: retry with backoff on 429/502/503/504 honoring
  `Retry-After`, one-shot token refresh on 401, RSQL-aware pagination, Classic
  API XML and Jamf Pro API JSON behind one pipeline, normalized errors.
- Typed cmdlets: `Get-JamfComputer`, `Get-JamfMobileDevice`, `Get-JamfProVersion`,
  `Get-JamfPolicy`, script CRUD (`Get/New/Set/Remove-JamfScript`).
- MUT-compatible bulk operations: `Update-JamfComputer` (MUT computer template
  pipes straight in; blank = unchanged, `CLEAR!` = wipe) and
  `Set-JamfStaticGroupMember` (add/remove/replace with MUT identifier heuristics).
- Escape hatch: `Invoke-JamfApi` for the full API surface.
- Pester suite (52 tests, fully mocked, no network), PSScriptAnalyzer config,
  cross-platform GitHub Actions CI, flattening build script.

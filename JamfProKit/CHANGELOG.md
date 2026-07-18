# Changelog

All notable changes to JamfProKit are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[SemVer](https://semver.org/).

## [Unreleased]

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

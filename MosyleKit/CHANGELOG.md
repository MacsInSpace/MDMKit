# Changelog

All notable changes to MosyleKit are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[SemVer](https://semver.org/).

## [Unreleased]

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

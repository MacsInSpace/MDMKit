# MDMKit

Modern, cross-platform PowerShell 7 modules for Apple MDM platforms — built for 2026, not ported from 2019.

| Module | Status | Target |
|---|---|---|
| **[JamfProKit](JamfProKit/)** | v0.5.0-alpha | [Jamf Pro](https://www.jamf.com/products/jamf-pro/) — Jamf Pro API (JSON) + Classic API (XML) |
| **[JamfSchoolKit](JamfSchoolKit/)** | v0.1.0-alpha | [Jamf School](https://www.jamf.com/products/jamf-school/) — Jamf School API (first PowerShell module for it) |
| **[MosyleKit](MosyleKit/)** | v0.1.0-alpha | [Mosyle Manager](https://mosyle.com/) — Mosyle Manager API (JWT) |

One repo, one module per platform. Each MDM has its own API — different auth, versioning and
conventions — so each gets a module that fits it properly rather than a lowest-common-denominator
wrapper. They live together because they share a design (hardened request engine, session model,
strict-mode-clean cross-platform PowerShell), one issue tracker, and one release pipeline. Each
module installs independently from the PowerShell Gallery.

## Highlights (JamfProKit)

- **OAuth client credentials first** (API Roles and Clients), user bearer tokens too — automatic renewal either way
- **One hardened request engine**: retry with backoff honoring `Retry-After`, 401 token refresh, pagination, Jamf Cloud sticky sessions
- **MUT-style bulk operations**: [The MUT](https://github.com/jamf/mut)'s CSV templates pipe *directly* into `Update-JamfComputer`, with `-WhatIf` previews and per-row result objects the GUI never had
- **Live-spec generic layer**: reads your instance's own OpenAPI schema (`/api/schema`) so coverage tracks whatever your server runs
- **Strict-mode clean, macOS-native**, PowerShell 7.4+, CI on macOS/Linux/Windows

See each module's README for its full tour, cmdlet list and roadmap, and the acknowledgements to
the community projects that mapped this territory first.

## License

[MIT](LICENSE)

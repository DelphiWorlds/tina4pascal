# ADR-0007: Signed, verifiable releases

- **Status:** Accepted
- **Date:** 2026-10-01 (retrofit)

## Context

Downloadable binaries must be trustworthy: Windows SmartScreen checks Authenticode,
and every asset should carry an independent signature + checksum so anyone can
verify provenance.

## Decision

Release via `tools/release-windows.sh` / `release-macos.sh` to a GitHub release tag.
Each asset gets:

- **Authenticode** (Windows `.exe`): Certum **EV** cert on a SimplySign cloud token,
  via `osslsigncode` + the libp11 **pkcs11 provider** (not the legacy engine, which
  modern OpenSSL drops) + RFC3161 timestamp. Needs an active SimplySign Desktop
  session.
- **GPG detached signature** (`.asc`) with the release key
  `E0B36CDD76676DD08E4F1FA641DA6E7645F494AF`.
- **SHA-256** (`.sha256`).

## Consequences

- SimplySign sessions expire — "Failed to enumerate slots" means log in again.
- The release GPG private key must be in the keyring; it is not committed.
- `build-tools`/libp11/osslsigncode/gnupg/gh are release-host prerequisites.
- Do a `release-*.sh` dry run (no tag) first — it packages + signs without uploading.
- Undo this and releases become unverifiable, and Windows flags them as unsigned.

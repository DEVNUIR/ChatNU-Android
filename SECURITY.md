# Security Policy

ChatNU is pre-release software. The current UI branch does not yet provide production-ready end-to-end encryption.

Report vulnerabilities privately to the DEVNU maintainers. Do not open a public issue containing keys, credentials, exploit details, personal data, or server access information.

## Non-negotiable requirements before production

- audited identity and session protocol
- secure Android Keystore integration
- encrypted local database
- certificate validation and optional pinning policy
- replay protection and message deduplication
- attachment size, type, and decompression limits
- device revocation and recovery flow
- independent security review

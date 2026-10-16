# Security Policy

## Supported Versions

Awake is actively maintained. Security updates and patches are provided for the current major release:

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of Awake very seriously. Awake interacts directly with low-level macOS system power management APIs (`IOKit`) and privileged system settings (`pmset` for closed-lid clamshell mode). Ensuring these capabilities remain safe, robust, and contained is paramount.

If you believe you have discovered a security vulnerability in Awake, please report it responsibly:

1. **Do not open a public issue.**
2. Report the vulnerability via GitHub Private Vulnerability Reporting on the repository, or email **pawanbhayde@gmail.com** with details.
3. Include detailed reproduction steps, proof-of-concept code or commands, affected versions, and any suggested mitigations.

### Response Timeline

- **Initial Acknowledgement**: Within 48 hours of receipt.
- **Assessment & Fix Plan**: Within 7 business days.
- **Security Release**: As soon as a verified patch is tested and validated.

Thank you for helping keep Awake and its users safe.

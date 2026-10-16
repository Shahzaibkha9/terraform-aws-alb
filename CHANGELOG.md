# Changelog

All notable changes to this module are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the module uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Initial implementation of the ALB module.
- Support for multiple target groups with per-group health check and stickiness configuration.
- Listener support for HTTP and HTTPS with HTTP→HTTPS redirect action.
- Listener rules for path-pattern, host-header, and HTTP header based routing.
- Access logs to S3, deletion protection, idle timeout, and HTTP/2 toggles.
- `examples/minimal` and `examples/complete` usage examples.

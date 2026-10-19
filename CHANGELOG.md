# Changelog

All notable changes to this image.

This image has no version number of its own. Its tags are the zitadel-tools versions it holds - `latest`, the major
line such as `1`, and the exact version such as `1.0.0` - and it is rebuilt weekly with the newest release, the current
Alpine packages and the current Go toolchain. Which zitadel-tools version a particular image holds is written into it:

```
docker image inspect --format '{{index .Config.Labels "image.zitadel-tools.version"}}' epicsoft/zitadel-tools:1
```

Entries here are dated, because there is no number to give them.

---

## 2026-10-19

### Added

- **Version tags**: `1` and `1.0.0` next to `latest`, so a setup can stay on a major line or on one release. The
  version is in the label `image.zitadel-tools.version` and in `org.label-schema.version`.
- `zitadel-tools --version` reports the real version and commit; it said `dev` before, because the upstream ldflags
  were missing.
- Every image goes through `test/smoke.sh` before it is pushed, on every platform: version, `basicauth`, and
  `key2jwt` with a key created by the image's OpenSSL, from a file and from stdin - all as an unprivileged user.
- A mirror on GitHub: `github.com/epicsoft-llc/zitadel-tools`.

### Changed

- The README examples run with `--user "$(id -u):$(id -g)"`, so the files written to `/data` belong to the caller
  instead of `root`, and without `-it`, so they work in scripts and pipelines. The JWT example no longer converts the
  key with `openssl rsa -traditional` - `key2jwt` reads the key `openssl genrsa` writes. New examples: a JWT from a
  service user key, `--key=-` from stdin, and the user migration.
- Both platforms build the same zitadel-tools version: the pipeline resolves it once instead of letting each
  platform ask for `latest` on its own.
- The binary is built with `CGO_ENABLED=0`, `-trimpath` and without debug symbols, as upstream builds its releases -
  the image is about 14 MB smaller.

### Security

- The packages of the base image are upgraded as well (`apk upgrade`), so their security fixes do not wait for the
  next `alpine` image. The image of 2026-10-18 still held `zlib-1.3.2-r0`; Alpine had published `r1` with a
  backported security fix on 2026-10-06.
- The pipeline takes its tokens over stdin and through the environment instead of the command line.

### zitadel-tools 1.0.0

The weekly build of 2026-09-27 picked up zitadel-tools 1.0.0 (released 2026-09-21). It changes one default: `migrate
auth0` takes the email verification state from the Auth0 export instead of marking every user verified;
`--email-verified=true` restores the earlier result. `key2jwt` reads the key from stdin with `--key=-`. Details in the
[upstream release notes](https://github.com/zitadel/zitadel-tools/releases/tag/v1.0.0).

---

Earlier changes are in the git history of this repository.

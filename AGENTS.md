# AGENTS.md

Guidance for AI coding agents and contributors working in this repository.

## What this repository is

There is no application source code here. The repository packages the upstream Go tool
[zitadel/zitadel-tools](https://github.com/zitadel/zitadel-tools) as a multi-platform Docker image. The `Dockerfile`
is the product, `test/smoke.sh` checks it, and `README.md` is the published Docker Hub description, uploaded by the
pipeline - part of the release artifact, not just documentation.

| | |
|---|---|
| **Repository** | developed on `gitlab.com/epicsoft-networks/zitadel-tools` (branch `main`), mirrored to `github.com/epicsoft-llc/zitadel-tools` |
| **Registries** | `registry.gitlab.com/epicsoft-networks/zitadel-tools` and Docker Hub `epicsoft/zitadel-tools` |
| **Platforms** | `linux/amd64` and `linux/arm64` |

## Image design

- **Two stages.** `golang:alpine` builds the tool with `go install`; only `/go/bin/zitadel-tools` is copied into a
  plain `alpine:latest`. Nothing Go-related reaches the final image.
- **Built from source, verified by the Go checksum database.** `go install` checks every module against
  `sum.golang.org`, so the build fails on a tampered release instead of shipping it.
- **The upstream ldflags.** `-X main.version`, `main.commit` and `main.date` are set as in the upstream release build,
  so `zitadel-tools --version` names the version instead of `dev`. `CGO_ENABLED=0` and `-trimpath` as well.
- **`openssl` is part of the contract.** The README creates the RSA keys for `key2jwt` with OpenSSL inside this
  image; zitadel-tools itself does not need it.
- **`apk --no-cache upgrade` comes before `apk add`**: `apk add` never upgrades the packages of the base image.
- **`WORKDIR /data`** is where users mount their keys, and the defaults of `migrate` (`./users.json`,
  `./importBody.json`) resolve there. Keep it.
- **`CMD ["zitadel-tools"]` and no `ENTRYPOINT`** - every README example repeats the binary name after the image name,
  and `openssl` runs the same way. An `ENTRYPOINT` would break the documented invocations.
- **The image runs as `root`** so that existing invocations keep writing into mounted directories; the README runs
  everything with `--user "$(id -u):$(id -g)"`, and `test/smoke.sh` checks that this works.
- Both label blocks, `org.label-schema.*` and `image.*`/`maintainer.*`, are maintained together.

## Tests

```bash
docker build -t zitadel-tools:test --pull --no-cache --build-arg ZITADEL_TOOLS_VERSION=1.0.0 .
sh test/smoke.sh zitadel-tools:test 1.0.0          # optionally a platform as third argument
```

`test/smoke.sh` runs as an unprivileged user: the version reported by `zitadel-tools --version`, the working directory,
`basicauth` against a known value, and `key2jwt` with an RSA key created by the image's OpenSSL, from a file and from
stdin. The pipeline runs it for every platform before the push; a new documented workflow belongs into it.

Build with `--pull --no-cache` when checking a change the way the pipeline does - the image follows moving targets
(`golang:alpine`, `alpine:latest`, the newest zitadel-tools), and a cached build hides exactly that drift.

## Tags and pipeline (`.gitlab-ci.yml`)

| Tag | Holds |
|---|---|
| `latest` | the newest zitadel-tools release |
| `1` | the major line of that release |
| `1.0.0` | that exact release |

The image has no version number of its own; the tags are zitadel-tools versions, rebuilt weekly. `CHANGELOG.md`
therefore has dated entries.

The `build` job resolves the newest upstream version once (`go list -m ...@latest`), so both platforms build the same
one, and passes it as `ZITADEL_TOOLS_VERSION`. Each platform is built, loaded and smoke-tested before the
multi-platform push, which reuses those layers from the builder cache. The `docker:dind` service runs with TLS, which
buildx only takes from a Docker context - hence `docker context create dind` before `docker buildx create`.
`linux/arm64` on an `amd64` runner needs QEMU (`binfmt_misc`) on the runner host, which is why the jobs carry the
runner tag `imagex`. Publishing happens only from the default branch and the weekly schedule. A new major release
upstream needs no change here: the job derives the tags from the version.

CI variables: `DOCKER_HUB_USER`, `DOCKER_HUB_TOKEN` (masked, protected). The tokens go in over stdin and through the
environment, never onto a command line.

**GitHub mirror:** a push mirror in the GitLab project settings (Repository → Mirroring repositories) with its own
token - not part of the pipeline. Changes are never pushed to GitHub directly; the mirror would overwrite them.

## Conventions

- `.editorconfig`: 2-space indent, LF, UTF-8, final newline, trailing whitespace trimmed (except Markdown), 120 columns
  (180 for YAML, off for Markdown); `.gitattributes` keeps LF in the repository.
- `test/smoke.sh` is POSIX `sh`: it runs in the `docker:latest` job image, which has no bash.
- Commit messages follow Conventional Commits (`feat:`, `fix:`, `ci:`, `chore:`).

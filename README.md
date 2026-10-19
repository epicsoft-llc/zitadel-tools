# ZITADEL Tools

This Docker image is managed and kept up to date by [epicsoft LLC](https://epicsoft.one).

The command line helpers of [ZITADEL](https://zitadel.com) in a small image, together with OpenSSL for creating the
keys they need: `key2jwt` turns a service account key into a JWT for the JWT profile grant, `basicauth` builds the
header for Client Secret Basic, and `migrate` converts user exports from Auth0 and Keycloak into a ZITADEL import.
Nothing to install on the host - and the same tool on every machine and in every pipeline.

* Base image: https://hub.docker.com/_/alpine, platforms `linux/amd64` and `linux/arm64`
* Upstream: https://github.com/zitadel/zitadel-tools
* Dockerfile: https://gitlab.com/epicsoft-networks/zitadel-tools/-/blob/main/Dockerfile
* Repository: https://gitlab.com/epicsoft-networks/zitadel-tools, mirrored to [GitHub](https://github.com/epicsoft-llc/zitadel-tools) — issues are welcome on both; code changes only as merge requests on GitLab, the mirror overwrites anything pushed to GitHub
* Container registry: https://gitlab.com/epicsoft-networks/zitadel-tools/container_registry
* Docker Hub: https://hub.docker.com/r/epicsoft/zitadel-tools
* Changelog: https://gitlab.com/epicsoft-networks/zitadel-tools/-/blob/main/CHANGELOG.md
* License: MIT

## Versions

The image is rebuilt weekly with the newest release of zitadel-tools, the current Alpine packages and the current Go
toolchain.

| Tag | Holds |
|---|---|
| `latest` | the newest zitadel-tools release |
| `1` | the newest 1.x release; once upstream releases 2.0, it keeps the last 1.x build |
| `1.0.0` | exactly this release; rebuilt weekly while it is the newest one, then kept as it is |

The zitadel-tools version an image holds is written into it, and the tool reports it itself:

```bash
docker image inspect --format '{{index .Config.Labels "image.zitadel-tools.version"}}' epicsoft/zitadel-tools:1
docker run --rm epicsoft/zitadel-tools:1 zitadel-tools --version
```

## Usage

The working directory in the image is `/data`. Mount the directory with your keys there, and run as your own user
with `--user "$(id -u):$(id -g)"` - files the tools write then belong to you instead of `root`.

### Show help

```bash
docker run --rm epicsoft/zitadel-tools:1 zitadel-tools --help
```

### JWT from a service account key

Create a key of type JSON for a service user in the ZITADEL console and download it, then:

```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$(pwd):/data" epicsoft/zitadel-tools:1 \
  zitadel-tools key2jwt --audience=https://<your-instance> --key=/data/key.json --output=/data/jwt.txt
```

`--audience` is the URL of your ZITADEL instance. Without `--output` the JWT goes to stdout.

### JWT from your own RSA key

Create the key pair with OpenSSL from the image, register `superuser.pub` in ZITADEL, and sign with the private key:

```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$(pwd):/data" epicsoft/zitadel-tools:1 \
  openssl genrsa -out /data/superuser.pem 4096
docker run --rm --user "$(id -u):$(id -g)" -v "$(pwd):/data" epicsoft/zitadel-tools:1 \
  openssl rsa -in /data/superuser.pem -pubout -out /data/superuser.pub
docker run --rm --user "$(id -u):$(id -g)" -v "$(pwd):/data" epicsoft/zitadel-tools:1 \
  zitadel-tools key2jwt --audience=https://<your-instance> --key=/data/superuser.pem --issuer=superuser --output=/data/jwt.txt
```

`--issuer` is the user ID or client ID the key belongs to. `--key=-` reads the key from stdin, so it never has to be
written to disk - for example in a pipeline that keeps it in a masked variable:

```bash
printenv ZITADEL_KEY \
  | docker run --rm -i epicsoft/zitadel-tools:1 zitadel-tools key2jwt --audience=https://<your-instance> --key=- --issuer=superuser
```

### Client Secret Basic

```bash
docker run --rm epicsoft/zitadel-tools:1 zitadel-tools basicauth --id "example-id" --secret "example-secret"
```

The output is the value for the header `Authorization: Basic <output>`.

### Migrating users from Auth0 or Keycloak

```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$(pwd):/data" epicsoft/zitadel-tools:1 \
  zitadel-tools migrate auth0 --org=<organization-id> --users=/data/users.json --passwords=/data/passwords.json --output=/data/importBody.json
```

Since zitadel-tools 1.0.0 the Auth0 migration takes the email verification state from the export instead of marking
every user verified; `--email-verified=true` or `=false` sets it for all users. `zitadel-tools migrate keycloak --help`
shows the options for Keycloak. The result is the body for ZITADEL's data import.

## Installed Alpine packages

Installed in their newest version from the Alpine repository - https://pkgs.alpinelinux.org/packages

- openssl
- ca-certificates

## Reporting problems

Issues are welcome on [GitLab](https://gitlab.com/epicsoft-networks/zitadel-tools/-/issues) and
[GitHub](https://github.com/epicsoft-llc/zitadel-tools/issues). Please report a security problem as a
**confidential issue** on GitLab instead of a public one. Problems of zitadel-tools itself belong
[upstream](https://github.com/zitadel/zitadel-tools/issues).

## License

[MIT](https://gitlab.com/epicsoft-networks/zitadel-tools/-/blob/main/LICENSE) — Copyright (c) 2024-2026 epicsoft LLC / Alexander Schwarz

The MIT license applies only to files created by epicsoft LLC. Third-party software in the image — zitadel-tools
(Apache License 2.0), the Alpine packages and the official `alpine` image — remains under its own licenses.

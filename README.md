# Zitadel Tools

This Docker image is managed and kept up to date by [epicsoft LLC](https://epicsoft.one).

Docker image for Zitadel Tools based on official [Alpine image](https://hub.docker.com/_/alpine).

* Base image: https://hub.docker.com/_/alpine
* Dockerfile: https://gitlab.com/epicsoft-networks/zitadel-tools/blob/main/Dockerfile
* Repository: https://gitlab.com/epicsoft-networks/zitadel-tools/tree/main
* Container-Registry: https://gitlab.com/epicsoft-networks/zitadel-tools/container_registry
* Docker Hub: https://hub.docker.com/r/epicsoft/zitadel-tools

## Description

Docker image for Zitadel Tools.  
The `latest` version of [zitadel-tools](https://github.com/zitadel/zitadel-tools) is installed and deployed as a Docker image.

## Versions

`latest` based on `alpine:latest` - build `weekly`

## Installed Alpine packages

Alpine packages are installed in the current image in the latest version - https://pkgs.alpinelinux.org/packages

- openssl
- ca-certificates

## Examples

### Show help

```bash
docker run --rm -it epicsoft/zitadel-tools zitadel-tools --help
```

### Client Secret Basic

```bash
docker run --rm -it -v $(pwd):/data epicsoft/zitadel-tools zitadel-tools basicauth --id "example-id" --secret "example-secret"
```

### Create JWT

```bash
docker run --rm -it -v $(pwd):/data epicsoft/zitadel-tools openssl genrsa -out /data/superuser.pem 4096
docker run --rm -it -v $(pwd):/data epicsoft/zitadel-tools openssl rsa -in /data/superuser.pem -outform PEM -pubout -out /data/superuser.pub
docker run --rm -it -v $(pwd):/data epicsoft/zitadel-tools openssl rsa -in /data/superuser.pem -out /data/superuser.rsa.pem -traditional
docker run --rm -it -v $(pwd):/data epicsoft/zitadel-tools zitadel-tools key2jwt --audience=https://example.com --key=/data/superuser.rsa.pem --issuer=superuser --output=/data/jwt.txt
```

## License

MIT License see [LICENSE](https://gitlab.com/epicsoft-networks/azure-devops-backup/blob/main/LICENSE)

Please note that the MIT license only applies to the files created by epicsoft LLC. Other software may be licensed under other licenses.

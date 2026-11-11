# ns8-termix

[![Build Status](https://github.com/geniusdynamics/ns8-termix/actions/workflows/test-module.yml/badge.svg)](https://github.com/geniusdynamics/ns8-termix/actions/workflows/test-module.yml)

NethServer 8 module for the Termix application, providing a web-based terminal interface.

## Table of Contents

- [Install](#install)
- [Configure](#configure)
- [Update](#update)
- [Get the Configuration](#get-the-configuration)
- [Uninstall](#uninstall)
- [Debug](#debug)
- [Testing](#testing)
- [UI Translation](#ui-translation)

## Install

Instantiate the module with:

```bash
add-module ghcr.io/geniusdynamics/termix:latest 1
```

The output of the command will return the instance name. Output example:

```json
{
  "module_id": "termix1",
  "image_name": "termix",
  "image_url": "ghcr.io/geniusdynamics/termix:latest"
}
```

## Configure

Let's assume that the termix instance is named `termix1`.

Launch `configure-module`, by setting the following parameters:

- `host`: a fully qualified domain name for the application
- `http2https`: enable or disable HTTP to HTTPS redirection (true/false)
- `lets_encrypt`: enable or disable Let's Encrypt certificate (true/false)

Example:

```bash
api-cli run configure-module --agent module/termix1 --data - <<EOF
{
  "host": "termix.domain.com",
  "http2https": true,
  "lets_encrypt": false
}
EOF
```

The above command will:

- start and configure the termix instance
- configure a virtual host for traefik to access the instance

## Update

The module runs the official `ghcr.io/termix-ssh/termix` image.

Termix 26.10.0 and later cannot open a database written by Termix 2.8 or
older. The first time an instance created with an older module version
starts after the update, `bin/prepare-termix-data` runs the Termix 2.9.2
image once to migrate the data, then starts the current release. The same
happens when an old backup is restored. Expect the first start to take a few
minutes while the extra image is downloaded.

To update the module to a new version:

```bash
api-cli run update-module --data '{
  "module_url": "ghcr.io/geniusdynamics/termix:latest",
  "instances": ["termix1"],
  "force": true
}'
```

## Get the Configuration

You can retrieve the configuration with:

```bash
api-cli run get-configuration --agent module/termix1
```

## Uninstall

To uninstall the instance:

```bash
remove-module --no-preserve termix1
```

## Debug

Some CLI commands are needed to debug the module.

- The module runs under an agent that initiates many environment variables (in `/home/termix1/.config/state`). It could be useful to verify them on the root terminal:

  ```bash
  runagent -m termix1 env
  ```

- You can become the runagent for testing scripts and initiate all environment variables:

  ```bash
  runagent -m termix1
  ```

  The PATH becomes:

  ```
  /home/termix1/.config/bin:/usr/local/agent/pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/
  ```

- To debug a container or see the environment inside, first run:

  ```bash
  runagent -m termix1
  ```

  Then list containers:

  ```bash
  podman ps
  ```

  Example output:

  ```
  CONTAINER ID  IMAGE                                      COMMAND               CREATED        STATUS        PORTS                    NAMES
  d292c6ff28e9  localhost/podman-pause:4.6.1-1702418000                          9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  80b8de25945f-infra
  d8df02bf6f4a  docker.io/library/mariadb:10.11.5          --character-set-s...  9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  mariadb-app
  9e58e5bd676f  docker.io/library/nginx:stable-alpine3.17  nginx -g daemon o...  9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  termix-app
  ```

- To see environment variables inside the container:

  ```bash
  podman exec termix-app env
  ```

  Example output:

  ```
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  TERM=xterm
  PKG_RELEASE=1
  MARIADB_DB_HOST=127.0.0.1
  MARIADB_DB_NAME=termix
  MARIADB_IMAGE=docker.io/mariadb:10.11.5
  MARIADB_DB_TYPE=mysql
  container=podman
  NGINX_VERSION=1.24.0
  NJS_VERSION=0.7.12
  MARIADB_DB_USER=termix
  MARIADB_DB_PASSWORD=termix
  MARIADB_DB_PORT=3306
  HOME=/root
  ```

- To run a shell inside the container:

  ```bash
  podman exec -ti termix-app sh
  ```

## Testing

The tests are made using [Robot Framework](https://robotframework.org/) and
live in `tests/`. Every image published by the "Publish images" workflow is
tested on QEMU virtual machines by the "Test module" workflow, through the
shared [`test-module-qemu.yml`](https://github.com/NethServer/ns8-github-actions/blob/v1/docs/test-module-qemu.md)
workflow:

- the `install` scenario installs the image under test on a clean node
- the `update` scenario installs the previous release
  (`ghcr.io/geniusdynamics/termix:latest`), then updates it to the image
  under test
- the UI tests take screenshots of the Status and Settings pages, which are
  posted as a comment on the pull request

## UI Translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To set up the translation process:

- Add the [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository.
- Add your repository to [hosted.weblate.org](https://hosted.weblate.org) or ask a Genius Dynamics developer to add it to the ns8 Weblate project.

# `Visual Studio Code - DevContainer`

## Descriptions

> [**`Visual Studio Code Remote - Containers`** extension lets us use
> a Docker container as a full-featured development environment.](https://code.visualstudio.com/docs/remote/create-dev-container)

It is very complicated to match and update the dependencies between the different components needed to develop the program.  
If you store a well-organized development environment separately and call the environment when necessary, it is very easy to reproduce the development environment or share the development environment among various developers.

This document describes how to save the above development environment as an image using [`Docker`](https://docs.docker.com/engine/), [`Docker Compose`](https://docs.docker.com/compose/), and [`Visual Studio Code`](https://code.visualstudio.com/docs) and call and use it as a container as needed.

In the Windows environment without Docker Desktop, **[CLI Script](../.devcontainer/compose.sh) can be an alternative**.

---

## Requirements

Docker, Docker Compose, Visual Studio Code, and Remote - Containers (extension of VSCode)
are should be installed on your computer. (Linux PC)  
(For Windows PCs, Visual Studio Code must be installed, and Linux PCs with Docker and Docker Compose is required)
- `Docker`: <https://docs.docker.com/get-docker/>
- `Docker Compose`: <https://docs.docker.com/compose/install/>
- `Visual Studio Code`: <https://code.visualstudio.com/download>
- `Remote - Containers`: <https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers>

---

## Components

The following three files are usually required to run DevContainer.
- [`dev.Dockerfile`](../dev.Dockerfile)
- [`docker-compose.yml`](../docker-compose.yml)
- [`.devcontainer/devcontainer.json`](./devcontainer.json)

### Dockerfile
`Dockerfile` is a file for building docker images.  
An image made from the script is used to run a container.

The file is not required when using the docker image that has already been created.
Originally, the name of the script is usually 'Dockerfile', but here it is used separately as follows to distinguish between the development image and the release image.

- For Development: [`dev.Dockerfile`](../dev.Dockerfile)
- For release: [`Dockerfile`](../Dockerfile)

### docker-compose.yml
[`docker-compose.yml`](../docker-compose.yml) file is a setting file for driving [`Docker Compose`](https://docs.docker.com/compose/).
The [YAML](https://yaml.org/) file with `.yml` and `.yaml` extensions is a file format with a key-value structure that is often used to create settings, and is used to display multiple containers at the same time or to store and use the Docker argument required to drive containers.

### devcontainer.json
[`devcontainer.json`](./devcontainer.json) file is a setting file for DevContainer operation of Visual Studio Code.
Here, you can decide whether to use Dockerfile only when running the container, Docker-compose, workspace path inside the container, which shell to use, and which formatter or extension to use as a default.

---

## Run DevContainer (Linux OS)

Once all of the above settings are complete, development can begin inside the container following the following description.

<https://code.visualstudio.com/docs/remote/containers>

---

## Run DevContainer (Windows OS)

There are many restrictions on configuring the development environment using Windows OS.  
By combining WSL and Docker Desktop, Windows PCs were able to establish a development environment almost similar to Linux PCs, but it is difficult to configure the environment through that method.

Although all developers can use Docker Desktop and WSL in Windows PCs, but it is not recommended due to various limitations and difficulty in debugging.  
This document only deals with how to run a container on a Linux PC and then connect it remotely(`Remote - SSH`) using Windows PC to develop codes.

### CLI (compose.sh)
This is a CLI script that makes it easy to use frequently used commands without typing the entire command of Docker Compose.  
**This script creates and uses/removes only one container for convenience of development.**

- Basic Usage
    <pre><code>$ .devcontainer/compose.sh -b
    <b>-b</b> : build an image  
    <b>-r</b> : run a container  
    <b>-l</b> : print a log of the container(force log)
    <b>-s</b> : connect to shell(bash)  
    <b>-k</b> : kill container (attach and kill)  
    <b>-d</b> : down container (kill container and remove container, network and volumes)  
    <b>-p</b> : push image to remote repository  
    <b>--service=?</b> : specify service name of docker-compose to run  
    <b>--tag=?</b> : tag image version  
    <b>--release</b> : use image for release  
    <b>--no-cache</b> : build an image without caching
    
    <b>This script makes ONLY 1 CONTAINER</b></code></pre>
    
- Connect to the Shell of the Container  
  (Build automatically when there is no image, run automatically when there is no container)
    ```bash
    $ .devcontainer/compose.sh -s
    ```

- Connect to a container of another service
    ```bash
    $ .devcontainer/compose.sh -s --service=new_service
    ```
    
- Connec to a container for release
    ```bash
    $ .devcontainer/compose.sh -s --release
    ```

- Tag and push to remote repository
    ```bash
    $ .devcontainer/compose.sh --tag=v1.0.1-a0 --service=release -p
    ```

### `Remote - SSH`

Use the above script to run the container on the Linux PC and then connect remotely through 'Remote-SSH' in VSCode.

Here, the port to be used for SSH(Secure Shell) is should be specified in [`docker-compose.yml`](./examples/docker-compose.yml).

**`docker-compose.yml`**
<pre><code>services:
  dev:
    build:
      network: host
      context: .
      dockerfile: dev.Dockerfile
    image: "${COMPOSE_IMAGE_NAME}:${USER}"
    hostname: ${COMPOSE_IMAGE_NAME}
    container_name: ${COMPOSE_IMAGE_NAME}_dev
      <b>- '922:22'</b>
    volumes:
      - .:/app/${COMPOSE_IMAGE_NAME}:rw
      - /var/run/docker.sock:/var/run/docker.sock  # for docker-in-docker
</code></pre>

In addition, the user account to be used for SSH(Secure Shell) should be a default user of the image or created when the image was built.

<pre><code>services:
  dev:
    build:
      network: host
      context: .
      dockerfile: dev.Dockerfile
      args:
        <b>USER: ${USER}</b>
        <b>PUID: ${PUID}</b>
        <b>PGID: ${PGID}</b>
        DOCKER_GID: ${DOCKER_GID}
        LC: ko_KR.UTF-8
        TZ: Asia/Seoul
        COMPOSE_IMAGE_NAME: ${COMPOSE_IMAGE_NAME}
    image: "${COMPOSE_IMAGE_NAME}:${USER}"
    hostname: ${COMPOSE_IMAGE_NAME}
    container_name: ${COMPOSE_IMAGE_NAME}_dev
    user: ${USER}
    environment:
      <b>- USER=${USER}</b>
      <b>- PUID=${PUID}</b>
      <b>- PGID=${PGID}</b>
      - DOCKER_GID=${DOCKER_GID}
      - COMPOSE_IMAGE_NAME=${COMPOSE_IMAGE_NAME}
</code></pre>

After running the container set as above, connect to the container through 'Remote - SSH' to proceed with development.  
<https://code.visualstudio.com/docs/remote/ssh>

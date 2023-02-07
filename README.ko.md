# Visual Studio Code - DevContainer

[English](README.md)　|　**한국어**

## 시작하기

> [**Visual Studio Code Remote - Containers** extension lets us use
> a Docker container as a full-featured development environment.](https://code.visualstudio.com/docs/remote/create-dev-container)

프로그램 개발에 필요한 여러 구성요소 사이의 의존성을 맞추고 업데이트하는 것은 매우 복잡한 일입니다.
잘 구성된 개발환경을 따로 저장해두고 필요할 때 해당 환경을 호출해 사용하면, 개발환경을 재현하거나 여러 개발자들 사이에 개발환경을 공유하기 매우 용이합니다.

이 문서에서는 [Docker](https://docs.docker.com/engine/)와 [Docker Compose](https://docs.docker.com/compose/), [Visual Studio Code](https://code.visualstudio.com/docs)를 이용하여 위와 같은 개발환경을 이미지로 저장하고, 필요에 따라 컨테이너로 호출하여 사용하는 방법에 대해 설명합니다.

Docker Desktop이 없는 Windows 환경에서는 **'Remote - SSH'로 접속가능하게하는 [CLI 스크립트](./compose.sh)도 제공**합니다.

---

## 요구사항
Docker, Docker Compose, Visual Studio Code, Remote - Containers (VSCode 확장프로그램)가
컴퓨터에 설치되어 있어야 합니다. (Linux PC 기준)
(Windows PC의 경우 Visual Studio Code가 설치되어 있어야하며, Docker와 Docker Compose가 설치된 Linux PC가 별도로 있어야 합니다)
- Docker: <https://docs.docker.com/get-docker/>
- Docker Compose: <https://docs.docker.com/compose/install/>
- Visual Studio Code: <https://code.visualstudio.com/download>
- Remote - Containers: <https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers>

---

## 구성요소

DevContainer 구동을 위해서는 대개 아래 세 가지 파일이 필요합니다.
- [`dev.Dockerfile`](./example/dev.Dockerfile)
- [`docker-compose.yml`](./example/docker-compose.yml)
- [`.devcontainer/devcontainer.json`](./devcontainer.json)

### Dockerfile
`Dockerfile`은 도커 이미지를 빌드하기 위한 파일입니다.
컨테이너 구동 시에 해당 스크립트로 만들어진 도커 이미지를 사용해서 컨테이너를 띄우게 됩니다.
이미 만들어져있는 도커 이미지를 사용만 할 때에는 해당 파일이 필요하지 않습니다.

본래 위 파일의 이름은 보통 'Dockerfile'이라고 작성하지만, 여기서는 개발용 이미지와 릴리즈용 이미지의 구분을 위해 아래와 같이 구분하여 사용합니다.

- 개발용: [`dev.Dockerfile`](./example/dev.Dockerfile)
- 릴리즈용: [`Dockerfile`](./example/Dockerfile)

### docker-compose.yml
[`docker-compose.yml`](./example/docker-compose.yml)파일은 [Docker Compose](https://docs.docker.com/compose/) 구동을 위한 설정파일입니다.
`.yml`, `.yaml` 확장자를 가지는 [YAML](https://yaml.org/) 파일은 설정 작성에 자주 사용되는 키-값 구조를 가지는 파일포맷으로, 여러 컨테이너를 동시에 띄우거나 컨테이너 구동에 필요한 Docker argument를 저장해두고 사용하기 위해 사용합니다.

### devcontainer.json
[`devcontainer.json`](./devcontainer.json)파일은 Visual Studio Code의 DevContainer 구동을 위한 설정파일입니다.
이 곳에서는 컨테이너 구동시 Dockerfile만 사용할 지, docker-compose를 사용할 지, 컨테이너 내부 workspace경로, 어떤 쉘을 사용할 지, 어떤 formatter나 extension을 기본으로 사용할 지 등을 결정할 수 있습니다.

---

## DevContainer 실행하기 (Linux OS)

위 설정이 모두 완료되어 있으면, 다음 설명을 따라 컨테이너 내부에서 개발을 시작할 수 있습니다.

<https://code.visualstudio.com/docs/remote/containers>

---

## DevContainer 실행하기 (Windows OS)

Windows OS를 이용하여 개발환경을 구성하는 데에 여러 제약이 있습니다.
WSL과 Docker Desktop을 조합하여 Windows PC에서도 Linux PC와 거의 유사한 개발환경을 구축할 수 있었으나, 해당 방법을 통해 GPU 개발환경을 구성하기는 여전히 복잡합니다.

WSL과 Docker Desktop을 조합하여 Windows PC만을 이용해 개발을 진행할 수 있지만, 여러 한계점이나 디버깅의 난해함으로 인해 추천하지 않습니다.
여기서는 오직 Linux PC에서 컨테이너를 실행한 뒤, 이를 윈도우 PC를 통해 원격으로 접속(`Remote - SSH`)하여 개발하는 방법에 대해서만 다룹니다.

### CLI (compose.sh)
Docker Compose 전체 명령어를 입력할 필요 없이 자주 쓰는 명령어를 쉽게 호출하기 위한 CLI 스크립트입니다.
**이 스크립트는 개발의 편의성을 위해 단 하나의 컨테이너만을 만들고 사용/제거합니다.**

- 기본 사용법
    <pre><code>$ .devcontainer/compose.sh -b
    <b>-b</b> : build an image
    <b>-r</b> : run a container
    <b>-l</b> : print a log of the container
    <b>-s</b> : connect to shell(bash)
    <b>-k</b> : kill container (attach and kill)
    <b>-d</b> : down container (kill container and remove container, network and volumes)
    <b>-p</b> : push image to remote repository
    <b>--service=?</b> : specify service name of docker-compose to run
    <b>--tag=?</b> : tag image version
    <b>--release</b> : use image for release
    <b>--no-cache</b> : build an image without caching

    <b>This script makes ONLY 1 CONTAINER</b></code></pre>

- 컨테이너의 쉘에 접속하기
  (이미지가 없을 시 자동으로 빌드, 컨테이너가 없을 시 자동으로 실행해 줌)
    ```bash
    $ .devcontainer/compose.sh -s
    ```

- 다른 이름의 서비스 컨테이너에 접속하기
    ```bash
    $ .devcontainer/compose.sh -s --service=new_service
    ```

- 릴리즈용 컨테이너에 접속하기
    ```bash
    $ .devcontainer/compose.sh -s --release
    ```

- 태그를 붙여 원격 레포지토리에 푸시하기
    ```bash
    $ .devcontainer/compose.sh --tag=v1.0.1-a0 --service=release -p
    ```

### Remote - SSH

Linux PC에 위 스크립트를 사용하여 컨테이너를 구동한 뒤 VSCode의 'Remote-SSH'를 통해 원격으로 접속합니다.

여기서 SSH(Secure Shell) 접속에 사용할 port는 [`docker-compose.yml`](./example/docker-compose.yml)에 포트를 지정해두어야 합니다.

**docker-compose.yml**
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

또한, SSH(Secure Shell) 접속에 사용할 사용자계정은 이미지 기본값을 사용하거나 이미지 빌드 시에 지정해두어야 합니다.
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

위처럼 설정된 컨테이너를 실행 후에 'Remote - SSH'를 통해 해당 컨테이너에 접속하여 개발을 진행하면 됩니다.
<https://code.visualstudio.com/docs/remote/ssh>

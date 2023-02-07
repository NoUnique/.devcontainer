#!/bin/bash

# export VSCODE_IPC_HOOK_CLI="$(ls -td /tmp/vscode-ipc-* | head -1)"
# export PATH="$(ls -td ${HOME}/.vscode-server/bin/* | head -1)/bin:${PATH}"
# CODE_BIN="$(ls -td ${HOME}/.vscode-server/bin/* | head -1)/bin/remote-cli/code"

# hack: use code-server instead of remote-cli to install extensions
CODE_BIN="$(ls -td ${HOME}/.vscode-server/bin/* | head -1)/bin/code-server"
EXTENSION_CONFIG="/app/${COMPOSE_IMAGE_NAME}/.vscode/extensions.json"
if [ -f ${EXTENSION_CONFIG} ]; then
  jq -rc '.recommendations[]' ${EXTENSION_CONFIG} | while read i; do
    ${CODE_BIN} --install-extension ${i}
  done
fi

# hack: read service-wise dotenv file and export variables to bashrc
DOTENV_FILE=".env.dev"
if [ -f ${DOTENV_FILE} ]; then
  source ${DOTENV_FILE}
  cat ${DOTENV_FILE} | awk '!/^\s*#/' | awk '!/^\s*$/' | while IFS='' read -r line; do
    key=$(echo "$line" | cut -d '=' -f 1)
    value=$(echo "$line" | cut -d '=' -f 2-)
    echo "export $key=\"$value\"" >> ~/.bashrc
  done
fi

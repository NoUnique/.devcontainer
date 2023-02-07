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

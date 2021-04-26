#!/usr/bin/env bash
# install github runner and its dependencies
echo "checking github runner latest version"
GITHUB_RUNNER_VERSION=$(curl --silent https://api.github.com/repos/actions/runner/releases/latest | grep '"tag_name":' | cut -d'"' -f4|sed 's/^.//')
echo "latest version of github runner is ${GITHUB_RUNNER_VERSION}"
echo "installing github runner ${GITHUB_RUNNER_VERSION}"
curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-arm64-${GITHUB_RUNNER_VERSION}.tar.gz | tar -zx
echo "installing github runner dependencies"
sudo ./bin/installdependencies.sh
echo "latest github runner has been successfully installed"

set -e

readonly _GH_API_ENDPOINT="${GH_API_ENDPOINT:-https://github.com}"

if [ -z "$RUNNER_TOKEN" ]
then
  echo "Must define RUNNER_TOKEN variable"
  exit 255
fi

if [ -z "$GH_REPO" ]
then
  readonly RUNNER_URL=${_GH_API_ENDPOINT}/${GH_ORG}
else
  readonly RUNNER_URL="${_GH_API_ENDPOINT}/${GH_ORG}/${GH_REPO}"
fi

./config.sh --unattended --replace --url "${RUNNER_URL}" --token "${RUNNER_TOKEN}"
exec "./run.sh" "${RUNNER_ARGS}"

#!/bin/bash

# Fail if variables are unset
set -eu -o pipefail

echo '🔧 Install tools'
npm init -y && npm install -y postcss-cli autoprefixer

echo '🤵 Install Hugo'
HUGO_VERSION=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | jq -r '.tag_name')
mkdir tmp/ && cd tmp/
curl -sSL https://github.com/gohugoio/hugo/releases/download/${HUGO_VERSION}/hugo_extended_${HUGO_VERSION: -6}_Linux-64bit.tar.gz | tar -xvzf-
mv hugo /usr/local/bin/
cd .. && rm -rf tmp/
cd ${GITHUB_WORKSPACE}
hugo version || exit 1

echo '👯 Clone remote repository'
git clone https://github.com/${REMOTE} ${DEST}

echo '🧹 Clean site'
if [ -d "${DEST}" ]; then
    rm -rf ${DEST}/*
fi

echo '🍳 Build site'
hugo ${HUGO_ARGS:-""} -d ${DEST}

echo '🎁 Publish to remote repository'
cd ${DEST}
git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git add .
git status | grep "nothing to commit"
if [ $? -eq 0 ]; then
    echo "nothing to commit"
    exit 0
fi
git commit -am "🚀 Deploy with ${GITHUB_WORKFLOW}"
if [ $? != 0 ]; then
    echo "commit failed"
    exit 1
fi
git push -f -q https://${TOKEN}@github.com/${REMOTE} master
if [ $? != 0 ]; then
    echo "push failed"
    exit 1
fi

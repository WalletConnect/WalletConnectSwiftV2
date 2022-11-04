#!/bin/bash

set -e

printf '\nset user agent\n\n'

FILE=Sources/WalletConnectRelay/PackageVersion.swift
PACKAGE_VERSION=${{ github.event.pull_request.title }}

if [ -f "$FILE" ];
then
    cat "$FILE"
    echo "var packageVersion = \"$PACKAGE_VERSION\"" > "$FILE"
    cat "$FILE"

else

printf '\nError setting PACKAGE_VERSION\n\n'

fi


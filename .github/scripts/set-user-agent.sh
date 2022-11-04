#!/bin/bash

set -e

printf '\nset user agent\n\n'

FILE=Sources/WalletConnectRelay/PackageConfig.json

if [ -f "$FILE" ];
then
    printf '\ncurrent user agent:\n'
    cat "$FILE"
    printf '\nsetting user agent... \n'
    echo "{\"version\": \"$PACKAGE_VERSION\"}" > "$FILE"
    printf '\nuser agent set for:\n'
    cat "$FILE"

else

printf '\nError setting PACKAGE_VERSION\n\n'

fi


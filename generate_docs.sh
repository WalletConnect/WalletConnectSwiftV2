#!/bin/bash

DOCS_BASE_DIR="./docs"

dump=$(swift package dump-package | jq -r '.products[].targets[]')

IFS=$'\n' read -rd '' -a TARGETS <<<"$dump"

mkdir -p tmp-doc

for target in "${TARGETS[@]}"
do
    swift package --allow-writing-to-directory "./tmp-doc/${target}-docs"  \
        generate-documentation \
        --target $target \
        --disable-indexing \
        --include-extended-types \
        --output-path "./tmp-doc/${target}-docs" \
        --hosting-base-path WalletConnectSwiftV2
done 

rm -rf ${DOCS_BASE_DIR}
is_first=1
for target in "${TARGETS[@]}"
do
	if [ $is_first -eq 1 ]; then
        echo "Copying initial documentation for ${target}"
        cp -R "tmp-doc/${target}-docs" "${DOCS_BASE_DIR}"
        is_first=0
    else
        echo "Merging documentation for ${target}"
        cp -R "tmp-doc/${target}-docs/data/documentation/"* "${DOCS_BASE_DIR}/data/documentation/"
        cp -R "tmp-doc/${target}-docs/documentation/"* "${DOCS_BASE_DIR}/documentation/"
    fi
done

rm -rf tmp-doc 


# swift package --allow-writing-to-directory ./docs  \
#     generate-documentation \
#     --product WalletConnect \
#     --disable-indexing \
#     --include-extended-types \
#     --output-path ./docs \
#     --hosting-base-path WalletConnectSwiftV2 \
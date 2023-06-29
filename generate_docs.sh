#!/bin/bash

DOCS_BASE_DIR="./docs"

dump=$(swift package dump-package | jq -r '.targets[].name')

IFS=$'\n' read -rd '' -a TARGETS <<<"$dump"

mkdir -p tmp-doc

for target in "${TARGETS[@]}"; do
    swift package --allow-writing-to-directory "./tmp-doc/${target}-docs" \
        generate-documentation \
        --target $target \
        --disable-indexing \
        --include-extended-types \
        --output-path "./tmp-doc/${target}-docs" \
        --hosting-base-path WalletConnectSwiftV2
done

rm -rf ${DOCS_BASE_DIR}
is_first=1
for target in "${TARGETS[@]}"; do
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
echo "Deleting non-mergable metadata.json"
rm -f "${DOCS_BASE_DIR}/metadata.json"
rm -rf tmp-doc

TARGET_DOCS_DIR='./docs/documentation'
INDEX_FILE='./docs/index.html'
BASE_URL='https://walletconnect.github.io/WalletConnectSwiftV2/documentation'
REPO_NAME='WalletConnectSwiftV2'

target_count=0
target_list=""
single_target_name=""
for target in $(ls "${TARGET_DOCS_DIR}"); do
    if [ -d "${TARGET_DOCS_DIR}/${target}" ]; then
        single_target_name="${target}"
        target_count=$((target_count + 1))
        target_list="${target_list}<li><a href=\"${BASE_URL}/${target}\"><code>${target}</code> Documentation</a></li>"
    fi
done
if [ ${target_count} -gt 1 ]; then
    echo "Found ${target_count} targets. Generating list..."
    cat >"${INDEX_FILE}" <<EOF
<!DOCTYPE html>
<html>
    <head>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #d2d2d2;
        }

        h1 {
            text-align: center;
        }

        ul {
            list-style-type: none;
            padding: 0;
        }

        li {
            margin-bottom: 10px;
        }

        a {
            display: block;
            padding: 10px;
            background-color: #ccc;
            text-decoration: none;
            color: #337ab7;
            border-radius: 5px;
            transition: background-color 0.3s ease;
        }

        a:hover {
            background-color: #aaa;
        }
    </style>
        <title>${REPO_NAME} Documentation</title>
    </head>
    <body>
        <h1>${REPO_NAME} Documentation</h1>
        <ul>
        ${target_list}
        </ul>
    </body>
</html>
EOF
else
    echo "Found one target. Generating redirect file to target ${single_target_name}"
    cat >"${INDEX_FILE}" <<EOF
<!DOCTYPE html>
<html>
    <head>
        <title>${REPO_NAME} Documentation</title>
        <meta http-equiv="refresh" content="0; url=${BASE_URL}/${single_target_name}" />
    </head>
    <body>
        <p>Redirecting...</p>
    </body>
</html>
EOF
fi
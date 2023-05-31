
# Artifacts sometimes not available in Actions -> Build name -> Artifacts

For some reason GitHub sometimes won't show uploaded artifacts from nested workflows if the top-level workflow fails or does not finish. However for troubleshooting you still might want to download the artifacts. Since they are not shown anywhere, we need to resort to using GitHub API. This guide shows how to set it up (specifically through [GH CLI](https://cli.github.com/manual/gh_api)) and how to download the artifacts using it.

## Setup GH CLI

```bash
brew install gh
```

```bash
gh auth login
```

This will ask you to sign to Github in your browser and call back with Authentication token which will be stored internally for future use.

## List artifacts

```bash
gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/OWNER/REPO/actions/runs/RUN_ID/artifacts 
```

`RUN_ID` can be found as part of the url path when you open the detail of failing run e.g. `https://github.com/WalletConnect/WalletConnectSwiftV2/actions/runs/5122160070`

Usually you will end up with something like this -> `/repos/WalletConnect/WalletConnectSwiftV2/actions/runs/5121357531/artifacts`

This will return list of artifacts in following format 

```JSON
"artifacts": [
    ...
    {
      "id": 721939865,
      "node_id": "MDg6QXJ0aWZhY3Q3MjE5Mzk4NjU=",
      "name": "relay-tests test_results",
      "size_in_bytes": 30310,
      "url": "https://api.github.com/repos/WalletConnect/WalletConnectSwiftV2/actions/artifacts/721939865",
      "archive_download_url": "https://api.github.com/repos/WalletConnect/WalletConnectSwiftV2/actions/artifacts/721939865/zip",
      "expired": false,
      "created_at": "2023-05-30T15:04:29Z",
      "updated_at": "2023-05-30T15:04:34Z",
      "expires_at": "2023-08-28T15:03:44Z",
      "workflow_run": {
        "id": 5121357531,
        "repository_id": 492875108,
        "head_repository_id": 492875108,
        "head_branch": "master",
        "head_sha": "31fa447a8ed3cd321eb6e57ca5829b6aabec068a"
      }
    }
    ...
]
```
Once you find the artifact you are interested in, you really need only `id` and/or `archive_download_url` fields from it, as they are necessary for next step which is dowloading the artifact

You can learn more at https://docs.github.com/en/rest/actions/artifacts?apiVersion=2022-11-28#list-artifacts-for-a-repository

## Download artifacts

```bash
gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/OWNER/REPO/actions/artifacts/ARTIFACT_ID/zip > YOUR_FILENAME.zip
```

Using either `id` from previous step as ARTIFACT_ID or path part from `archive_download_url` to populate above format. And then just appending `> YOUR_FILENAME.zip` to redirect output of the command to be stored in the file. 

Usually you will end up with something like this -> `/repos/WalletConnect/WalletConnectSwiftV2/actions/artifacts/721939868/zip > cool_artifact.zip`

You can learn more at https://docs.github.com/en/rest/actions/artifacts?apiVersion=2022-11-28#download-an-artifact
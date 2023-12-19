# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

# Warn when there is a big PR
warn("Big PR") if git.lines_of_code > 500

failure("Please provide a summary in the Pull Request description") if vsts.pr_body.length < 5

# xcov.report(
#    scheme: 'EasyPeasy',
#    workspace: 'Example/EasyPeasy.xcworkspace',
#    exclude_targets: 'Demo.app',
#    minimum_coverage_percentage: 90
# )
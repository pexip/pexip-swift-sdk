if danger.env.danger_id == 'danger-pr'
    # Pull request
    warn "Big PR, consider splitting into smaller" if git.lines_of_code > 500

    if git.commits.any? { |c| c.message =~ /^Merge branch '#{github.branch_for_base}'/ }
        fail "Please rebase to get rid of the merge commits in this PR"
    end

    if github.pr_body.length == 0
        fail "Please provide a summary in the Pull Request description"
    end

    swiftlint.config_file = '.swiftlint.yml'
    swiftlint.lint_files inline_mode: true
else
    # Build and test summary
    platform = danger.env.danger_id == 'danger-iOS' ? 'iOS' : 'macOS'
    xccov_file = 'resultBundle.xcresult'
    xcode_summary.report xccov_file

    message "Code coverage for #{platform}"

    # Code coverage
    xcov.report(
        scheme: 'Pexip-Package',
        include_targets: 'PexipInfinityClient, PexipMedia, PexipRTC, PexipVideoFilters, PexipScreenCapture, PexipCore',
        is_swift_package: true,
        xccov_file_direct_path: [xccov_file],
        minimum_coverage_percentage: 70.0,
        html_report: false
        skip_slack: true
    )
end

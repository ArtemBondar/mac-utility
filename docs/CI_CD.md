# CI and draft preview releases

Feature pull requests target `develop`; only a pull request from this repository's `develop` branch may promote changes to `main`. Pull requests targeting either branch run macOS checks, and the promotion check fails other PRs to `main`. Pushes to `develop` run the same checks after a merge, and the checks can also be started manually. Configure branch protection separately to require the checks and restrict direct pushes; a workflow alone cannot enforce branch protection.

`main` starts with an empty release baseline descended from the repository's initial commit. `develop` retains the implementation history. The CI setup branch incorporates that baseline while preserving the development tree, so a future release PR can promote the complete app. Verify the comparison and resolve any conflicts before the first release.

The workflow runs `bash scripts/ci-checks.sh`, including the feature, localization, bundle and pipeline tests. It builds and ad-hoc signs test bundles, but does not validate the provisioned App Group or live Finder actions. GitHub-hosted runner availability and the Xcode version supplied by `macos-latest` can change. No secrets are used in pull-request jobs.

Pushing a version tag such as `v1.2.3` triggers the release workflow. The tag must point to a commit reachable from `main`. After the same checks pass, it builds a Release configuration preview and creates a **draft** GitHub release containing `MacUtility-preview.zip`. The workflow does not publish the draft. A duplicate release tag fails instead of overwriting an existing release. Review the tag's commit and artifact before taking any further action.

The artifact is **ad-hoc signed and not notarized**. The App Group identifier and provisioning are not production-ready, and Finder behavior remains unverified. It is for local evaluation, not a production release. It does not use Developer ID credentials and is not an App Store submission. Follow [release preparation](RELEASE.md) for signing, notarization, permission and clean-account validation before distribution.

To test the preview packaging locally, run `bash scripts/build-preview.sh /tmp/macutility-preview-output` with a path that does not already exist. Run `python3 -m unittest discover -s Tests -p 'test_ci_pipeline.py'` for pipeline contract and packaging regression checks.

# CI and releases

Feature pull requests target `develop`; only a pull request from this repository's `develop` branch may promote changes to `main`. Pull requests targeting either branch run macOS checks, and the promotion check fails other PRs to `main`. Pushes to `develop` run the same checks after a merge, and the checks can also be started manually. Configure branch protection separately to require the checks and restrict direct pushes; a workflow alone cannot enforce branch protection.

`main` starts with an empty release baseline descended from the repository's initial commit. `develop` retains the implementation history. The CI setup branch incorporates that baseline while preserving the development tree, so a future release PR can promote the complete app. Verify the comparison and resolve any conflicts before the first release.

The workflow runs `bash scripts/ci-checks.sh`, including the feature, localization, bundle and pipeline tests. It builds and ad-hoc signs test bundles, but does not validate the provisioned App Group or live Finder actions. GitHub-hosted runner availability and the Xcode version supplied by `macos-latest` can change. No secrets are used in pull-request jobs.

Pushing a version tag such as `v1.0.0` triggers the release workflow. You can also run **Publish release** manually from `main` with version `1.0.0`; that run creates the tag at the checked commit. The release commit must be reachable from `main`, all six app/extension marketing versions must match the requested version, and `docs/releases/v1.0.0.md` must exist. An existing tag pointing to a different commit is rejected.

After the checks pass, the workflow builds the Direct configuration and publishes `Clicklet-<version>.zip` with the version's release notes. If a release already exists for the same tag, its asset is uploaded and its notes updated. Existing assets are never silently overwritten. The artifact is **ad-hoc signed and not notarized**; it does not use Developer ID credentials and is not an App Store submission. Follow [release preparation](RELEASE.md) for Developer ID signing, notarization, and clean-account validation.

To build the Direct artifact locally, run `bash scripts/build-direct-preview.sh /tmp/macutility-release-output` with a path that does not exist. Run `python3 scripts/verify_release_version.py v1.0.0` and `python3 -m unittest discover -s Tests -p 'test_*.py'` for release metadata and pipeline regression checks.

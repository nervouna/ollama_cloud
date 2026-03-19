# Releasing ollama_cloud

This document defines the release process for this package.

## 1. Pre-check

1. Ensure version is updated in pubspec.yaml.
2. Update CHANGELOG.md with release notes.
3. Ensure metadata fields in pubspec.yaml are valid:
   - homepage
   - repository
   - issue_tracker
   - documentation

## 2. Quality gates

Run these commands from the project root:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test example
dart analyze
flutter test
```

All checks must pass before publishing.

## 3. Dry run publish

```bash
dart pub publish --dry-run
```

Fix all blocking warnings and rerun the dry run.

## 4. Publish

```bash
dart pub publish
```

## 5. Tag and release

```bash
git tag v<version>
git push origin v<version>
```

Then create a GitHub Release using the CHANGELOG entry.

## 6. Post-release verification

1. Verify package page on pub.dev.
2. Validate README rendering and code snippets.
3. Smoke test integration in a clean Flutter sample project.

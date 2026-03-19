# Contributing to ollama_cloud

Thanks for contributing.

## Development environment

1. Install Flutter and Dart.
2. Clone the repository.
3. Install dependencies:

```bash
flutter pub get
```

## Branch and PR workflow

1. Create a feature branch from main.
2. Keep PR scope focused and small.
3. Add or update tests for behavior changes.
4. Update README.md or CHANGELOG.md when user-facing behavior changes.

## Code quality gates

Run these commands before opening a PR:

```bash
dart format --output=none --set-exit-if-changed lib test example
dart analyze
flutter test
```

## Testing expectations

1. Add happy-path and error-path tests for new API methods.
2. For streaming logic, include:
   - normal completion
   - malformed chunk handling
   - done flag edge cases
   - status code mapping (401, 5xx)
3. For parsers, add boundary tests (empty input, fragmented input).

## Documentation expectations

1. Keep public API examples accurate and compile-safe.
2. Keep model examples and prerequisites consistent across README and example files.
3. Update RELEASING.md when release flow changes.

## Commit guidance

Recommended commit style:

- feat: add new capability
- fix: bug fix
- test: testing updates
- docs: documentation updates
- chore: maintenance changes

## Security and secrets

1. Never commit real API keys.
2. Keep example/.env excluded from version control.
3. Avoid logging sensitive request or token values.

## Release-related changes

If your PR changes release behavior, verify:

1. pubspec metadata remains valid.
2. CHANGELOG.md includes release notes.
3. RELEASING.md instructions still work.

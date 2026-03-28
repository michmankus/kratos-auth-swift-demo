fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build_sdk

```sh
[bundle exec] fastlane ios build_sdk
```

Build the OryAuth & OryUI SDK (Swift Package)

### ios test_sdk

```sh
[bundle exec] fastlane ios test_sdk
```

Run OryAuth SDK unit tests (Swift Package)

### ios build_app

```sh
[bundle exec] fastlane ios build_app
```

Build the Example App (OryKratosDemo)

### ios test_app

```sh
[bundle exec] fastlane ios test_app
```

Run Example App unit tests

### ios build_all

```sh
[bundle exec] fastlane ios build_all
```

Build everything (SDK + Example App)

### ios test_all

```sh
[bundle exec] fastlane ios test_all
```

Run all tests (SDK + Example App)

### ios coverage_sdk

```sh
[bundle exec] fastlane ios coverage_sdk
```

Run SDK tests with code coverage report

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Removed

- Removed the `AttendiMicrophone.onVolume` plugin API. Instead, use `AttendiMicrophone.recorder.onSignalEnergy` to access the recorded audio's signal energy / volume.

## [0.1.0] - 2023-10-16

First release of the package.

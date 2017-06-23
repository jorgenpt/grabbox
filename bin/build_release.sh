#!/bin/bash

cd "$(dirname "$0")/.."

xcodebuild -workspace GrabBox.xcworkspace -scheme Distribution -configuration Release -parallelizeTargets "$@" build

#!/bin/sh -

TIMESTAMP=$(perl -MTime::HiRes=time -e 'printf "%.9f\n", time')

if [ "$XcodeProject" ]; then
  # Normal Xcode Project
  PROJECT_NAME=`basename "$XcodeProject" .xcodeproj`
  PROJECT_PATH=$XcodeProjectPath
elif [ "$XcodeWorkspace" = "package.xcworkspace" ]; then
  # Swift Package Library
  PROJECT_NAME=`basename $(dirname "$XcodeWorkspacePath" | sed -r "s/\.swiftpm.+//")`
  PROJECT_PATH=$XcodeWorkspacePath
else
  # XCWorkspace (Probably using CocoaPods.)
  PROJECT_NAME=`basename "$XcodeWorkspace" .xcworkspace`
  PROJECT_PATH=$XcodeWorkspacePath
fi

logger -s "🔧 XCHook ${PROJECT_NAME} Testing Succeeds"
swift ${HOME}/.xchook/Message.swift $PROJECT_NAME $PROJECT_PATH TESTING_SUCCEEDS $TIMESTAMP

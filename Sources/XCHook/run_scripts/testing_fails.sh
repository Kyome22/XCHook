#!/bin/sh -

if [ "$XcodeProject" ]; then
  # Normal Xcode Project
  PROJECT_NAME=`basename "$XcodeProject" .xcodeproj`
elif [ "$XcodeWorkspace" = "package.xcworkspace" ]; then
  # Swift Package Library
  PROJECT_NAME=`basename $(dirname "$XcodeWorkspacePath" | sed -r "s/\.swiftpm.+//")`
else
  # XCWorkspace (Probably using CocoaPods.)
  PROJECT_NAME=`basename "$XcodeWorkspace" .xcworkspace`
fi

logger -s "🔧 XCHook ${PROJECT_NAME} Testing Fails"
swift ~/.xchook/Message.swift $PROJECT_NAME TESTING_FAILS

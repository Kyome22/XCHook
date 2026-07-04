#!/bin/zsh -f
zmodload zsh/datetime

STATUS=$1
TIMESTAMP=$EPOCHREALTIME

if [[ -n "$XcodeProject" ]]; then
  PROJECT_NAME="${XcodeProject:t:r}"
  PROJECT_PATH="$XcodeProjectPath"
elif [[ "$XcodeWorkspace" == "package.xcworkspace" ]]; then
  PROJECT_NAME="${${XcodeWorkspacePath%%/.swiftpm*}:t}"
  PROJECT_PATH="$XcodeWorkspacePath"
else
  PROJECT_NAME="${XcodeWorkspace:t:r}"
  PROJECT_PATH="$XcodeWorkspacePath"
fi

escape_json() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  print -rn -- "$value"
}

EVENTS_DIRECTORY="$HOME/.xchook/events"
mkdir -p "$EVENTS_DIRECTORY"

EVENT_JSON="{\"project\":\"$(escape_json "$PROJECT_NAME")\",\"path\":\"$(escape_json "$PROJECT_PATH")\",\"status\":\"$STATUS\",\"timestamp\":$TIMESTAMP}"

TEMPORARY_FILE=$(mktemp "$EVENTS_DIRECTORY/.event.XXXXXX")
print -r -- "$EVENT_JSON" > "$TEMPORARY_FILE"
mv "$TEMPORARY_FILE" "$EVENTS_DIRECTORY/${TIMESTAMP}-$$.json"

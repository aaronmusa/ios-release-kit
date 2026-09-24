#!/usr/bin/env bash
#
# Bumps CURRENT_PROJECT_VERSION in an Xcode project, and optionally moves the
# tag a cloud build watches.
#
#   bump-build.sh                      # bump by one, print the result
#   bump-build.sh --to 42              # set an explicit number
#   bump-build.sh --tag ci/testflight  # bump, then move and force-push the tag
#
# App Store Connect rejects an upload whose build number is not higher than the
# last one, and the counter drifts the moment a build is distributed from a
# machine without the bump coming back into git. Check what is already uploaded
# before trusting the project.

set -euo pipefail

project=""
target=""
tag=""
remote="origin"

while [ $# -gt 0 ]; do
  case "$1" in
    --project) project="$2"; shift 2 ;;
    --to)      target="$2"; shift 2 ;;
    --tag)     tag="$2"; shift 2 ;;
    --remote)  remote="$2"; shift 2 ;;
    -h|--help) sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$project" ]; then
  project="$(find . -maxdepth 2 -name '*.xcodeproj' -not -path '*/.*' | head -1)"
fi
[ -n "$project" ] || { echo "no .xcodeproj found; pass --project" >&2; exit 1; }

pbxproj="$project/project.pbxproj"
[ -f "$pbxproj" ] || { echo "not a project: $pbxproj" >&2; exit 1; }

current="$(grep -oE 'CURRENT_PROJECT_VERSION = [0-9]+;' "$pbxproj" \
  | grep -oE '[0-9]+' | sort -n | tail -1)"
[ -n "$current" ] || { echo "CURRENT_PROJECT_VERSION not found in $pbxproj" >&2; exit 1; }

next="${target:-$((current + 1))}"
if [ "$next" -le "$current" ] && [ -n "$target" ]; then
  echo "refusing to move $current backwards to $next" >&2
  exit 1
fi

sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = ${next};/g" "$pbxproj"
echo "build number ${current} -> ${next} in ${pbxproj}"
echo
echo "Verify it reached the product, not just the file:"
echo "  plutil -extract CFBundleVersion raw <built>.app/Info.plist"

[ -n "$tag" ] || exit 0

if [ -n "$(git status --porcelain)" ]; then
  echo >&2
  echo "working tree is dirty — commit the bump before moving ${tag}," >&2
  echo "or the tag will point at a commit that does not contain it." >&2
  exit 1
fi

head="$(git rev-parse HEAD)"
git tag -f -a "$tag" -m "Trigger build ${next}" "$head" >/dev/null
git push -f "$remote" "$tag"
echo "moved ${tag} -> ${head:0:7} and pushed to ${remote}"

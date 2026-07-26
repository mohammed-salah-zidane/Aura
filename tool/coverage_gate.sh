#!/usr/bin/env bash
#
# Fails the build when the tested packages fall below the line coverage bar.
#
# Generated sources are excluded: a *.g.dart file is the generator's output,
# and covering it measures the generator rather than this repository.
set -euo pipefail

MINIMUM=${1:-80}

total_hit=0
total_found=0

while IFS= read -r report; do
  package=$(dirname "$(dirname "$report")")
  hit=0
  found=0
  skip=0

  while IFS= read -r line; do
    case "$line" in
      SF:*)
        file=${line#SF:}
        case "$file" in
          *.g.dart|*.freezed.dart|*/l10n/generated/*) skip=1 ;;
          *) skip=0 ;;
        esac
        ;;
      LH:*) [ "$skip" -eq 0 ] && hit=$((hit + ${line#LH:})) ;;
      LF:*) [ "$skip" -eq 0 ] && found=$((found + ${line#LF:})) ;;
    esac
  done < "$report"

  if [ "$found" -gt 0 ]; then
    printf '%-40s %3d%%  (%d/%d)\n' \
      "$package" $((hit * 100 / found)) "$hit" "$found"
    total_hit=$((total_hit + hit))
    total_found=$((total_found + found))
  fi
done < <(find . -name lcov.info -not -path '*/build/*' | sort)

if [ "$total_found" -eq 0 ]; then
  echo "no coverage was produced" >&2
  exit 1
fi

percent=$((total_hit * 100 / total_found))
printf '\n%-40s %3d%%  (%d/%d)\n' TOTAL "$percent" "$total_hit" "$total_found"

if [ "$percent" -lt "$MINIMUM" ]; then
  echo "coverage $percent% is below the $MINIMUM% gate" >&2
  exit 1
fi

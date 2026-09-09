#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
cd "$project_dir"

secret_pattern='(sk-(proj-)?[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|Bearer [A-Za-z0-9._-]{20,})'
personal_path_pattern='/Users/[A-Za-z0-9._-]+/'

scan_args=(--hidden --glob '!.git/**' --glob '!.build/**' --glob '!dist/**' --glob '!Scripts/check_repository.sh')

scan_repository() {
    local pattern="$1"
    local message="$2"
    local scan_status

    set +e
    if command -v rg >/dev/null 2>&1; then
        rg -n -e "$pattern" "${scan_args[@]}" .
        scan_status=$?
    elif command -v grep >/dev/null 2>&1; then
        grep -RInIE \
            --exclude='check_repository.sh' \
            --exclude-dir='.git' \
            --exclude-dir='.build' \
            --exclude-dir='dist' \
            -e "$pattern" .
        scan_status=$?
    else
        echo "Privacy check requires either rg or grep."
        exit 2
    fi
    set -e

    if (( scan_status == 0 )); then
        echo "$message"
        exit 1
    fi

    if (( scan_status > 1 )); then
        echo "Privacy scan failed before it could verify the repository."
        exit "$scan_status"
    fi
}

scan_repository "$secret_pattern" "Potential credential found. Remove it before publishing."
scan_repository "$personal_path_pattern" "Absolute personal path found. Move it to runtime settings or documentation placeholders."

echo "Repository privacy checks passed."

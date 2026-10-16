#!/bin/bash
# Downloads the Render OpenAPI spec into api/. The spec is not committed; it is
# fetched as the first step of `go generate`.
set -euo pipefail
trap 'on_error "$?" "$LINENO"' ERR

LOG_FILE="${LOG_FILE:-/tmp/$(basename "$0" .sh).log}"
exec > >(tee -a "$LOG_FILE") 2>&1

readonly SPEC_URL="https://api-docs.render.com/openapi/render-public-api-1.json"
readonly DOWNLOAD_TIMEOUT_SECONDS=60
readonly SPEC_FILE="openapi.json"
SPEC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/api"
readonly SPEC_DIR

on_error() {
	local exit_code="$1"
	local line="$2"

	printf '{"level":"ERROR","file":"%s","line":%d,"msg":"command failed","exit_code":%d}\n' \
		"${BASH_SOURCE[1]}" "$line" "$exit_code" >&2
}

log() {
	local level="$1"
	shift

	jq -nc \
		--arg time "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
		--arg level "$level" \
		--arg file "${BASH_SOURCE[1]##*/}" \
		--arg line "${BASH_LINENO[0]}" \
		--arg func "${FUNCNAME[1]:-main}" \
		--arg msg "$*" \
		'{time:$time,level:$level,file:$file,line:($line|tonumber),func:$func,msg:$msg}' >&2
}

main() {
	mkdir -p "$SPEC_DIR"
	local tmp
	tmp="$(mktemp "${SPEC_DIR}/.${SPEC_FILE}.XXXXXX")"
	# shellcheck disable=SC2064 # expand tmp now, the local is gone when EXIT fires
	trap "rm -f -- '${tmp}'" EXIT

	log INFO "downloading spec=${SPEC_FILE}"
	wget -q \
		-T "$DOWNLOAD_TIMEOUT_SECONDS" \
		--header 'Accept: application/json' \
		-O "$tmp" \
		"$SPEC_URL"

	if ! jq -e 'type == "object" and (.openapi | type == "string")' "$tmp" >/dev/null; then
		log ERROR "downloaded file is not an OpenAPI document"
		exit 1
	fi

	chmod 0644 "$tmp"
	mv -- "$tmp" "${SPEC_DIR}/${SPEC_FILE}"
	log INFO "saved spec=${SPEC_FILE} version=$(jq -r '.info.version' "${SPEC_DIR}/${SPEC_FILE}")"
}

main "$@"

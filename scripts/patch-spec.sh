#!/bin/bash
# Patches api/openapi.json in place so oapi-codegen can generate from it.
#
# 1. Inlines every $ref that is not a plain #/components/<section>/<name>
#    reference. Render's spec reuses schemas and parameters by pointing inside
#    the first operation or schema that declared them (#/paths/...,
#    #/components/schemas/X/properties/Y), and oapi-codegen only follows
#    references to a whole component. Each such $ref is replaced by a copy of
#    its target, and the pass repeats until none are left, since a copied
#    target can itself hold another deep reference.
# 2. Collapses an anyOf or oneOf with a single inline branch into that branch.
#    oapi-codegen turns such a union into a wrapper whose accessors name a
#    branch type (N0) it never declares, so the package does not compile.
# 3. Drops x-go-type: SandboxPlan. The spec points it at a type that no
#    component declares, so the generated package references an undefined name.
set -euo pipefail
trap 'on_error "$?" "$LINENO"' ERR

LOG_FILE="${LOG_FILE:-/tmp/$(basename "$0" .sh).log}"
exec > >(tee -a "$LOG_FILE") 2>&1

readonly MAX_PASSES=20
SPEC_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/api/openapi.json"
readonly SPEC_FILE

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

count_deep_refs() {
	# shellcheck disable=SC2016 # $ref is a JSON key, not a shell expansion
	jq '[.. | objects | select(has("$ref")) | .["$ref"] | select(test("^#/components/[^/]+/[^/]+$") | not)] | length' "$SPEC_FILE"
}

# shellcheck disable=SC2016 # $ref and $root are jq names, not shell expansions
readonly INLINE_FILTER='
def pointer_get($root; $ptr):
  reduce ($ptr | ltrimstr("#/") | split("/")[] | gsub("~1"; "/") | gsub("~0"; "~")) as $seg
    ($root; if type == "array" then .[$seg | tonumber] else .[$seg] end);
. as $root
| walk(
    if type == "object" and (.["$ref"]? | type == "string") and (.["$ref"] | test("^#/components/[^/]+/[^/]+$") | not)
    then pointer_get($root; .["$ref"]) + del(.["$ref"])
    else . end
  )
'

# shellcheck disable=SC2016 # $ref and $key are jq names, not shell expansions
readonly COLLAPSE_FILTER='
def single_inline($key):
  (.[$key]? | type == "array" and length == 1 and (.[0] | type == "object" and (has("$ref") | not)));
walk(
  if type == "object" and single_inline("anyOf") then del(.anyOf) + .anyOf[0]
  elif type == "object" and single_inline("oneOf") then del(.oneOf) + .oneOf[0]
  else . end
)
'

readonly DROP_GO_TYPE_FILTER='
walk(
  if type == "object" and .["x-go-type"]? == "SandboxPlan" then del(.["x-go-type"])
  else . end
)
'

drop_undeclared_go_types() {
	local tmp="$1"

	jq "$DROP_GO_TYPE_FILTER" "$SPEC_FILE" >"$tmp"
	chmod 0644 "$tmp"
	mv -- "$tmp" "$SPEC_FILE"
	log INFO "dropped undeclared x-go-type"
}

collapse_single_unions() {
	local tmp="$1"

	jq "$COLLAPSE_FILTER" "$SPEC_FILE" >"$tmp"
	chmod 0644 "$tmp"
	mv -- "$tmp" "$SPEC_FILE"
	log INFO "collapsed single-branch unions"
}

main() {
	if [[ ! -f "$SPEC_FILE" ]]; then
		log ERROR "spec not found path=${SPEC_FILE}"
		exit 1
	fi

	local tmp
	tmp="$(mktemp "${SPEC_FILE}.XXXXXX")"
	# shellcheck disable=SC2064 # expand tmp now, the local is gone when EXIT fires
	trap "rm -f -- '${tmp}'" EXIT

	local pass remaining
	remaining="$(count_deep_refs)"
	log INFO "deep references found count=${remaining}"

	for ((pass = 1; pass <= MAX_PASSES; pass++)); do
		if [[ "$remaining" -eq 0 ]]; then
			break
		fi

		jq "$INLINE_FILTER" "$SPEC_FILE" >"$tmp"
		chmod 0644 "$tmp"
		mv -- "$tmp" "$SPEC_FILE"
		remaining="$(count_deep_refs)"
		log INFO "inline pass=${pass} remaining=${remaining}"
	done

	if [[ "$remaining" -ne 0 ]]; then
		log ERROR "deep references left after max passes count=${remaining}"
		exit 1
	fi

	collapse_single_unions "$tmp"
	drop_undeclared_go_types "$tmp"
}

main "$@"

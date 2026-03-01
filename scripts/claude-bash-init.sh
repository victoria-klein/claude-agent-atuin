# Stripped-down atuin init for non-interactive Claude Code bash sessions.
# Records commands in atuin history via preexec/precmd hooks.
# Sourced automatically via BASH_ENV.

if [[ ${__atuin_initialized-} == true ]]; then
    return 0
fi
__atuin_initialized=true

if [[ -z "${ATUIN_SESSION:-}" ]]; then
    ATUIN_SESSION=$(agent-atuin uuid)
    export ATUIN_SESSION
fi
ATUIN_HISTORY_ID=""

__atuin_preexec() {
    local id
    id=$(agent-atuin history start -- "$1" 2>/dev/null)
    export ATUIN_HISTORY_ID=$id
    __atuin_preexec_time=${EPOCHREALTIME-}
}

__atuin_precmd() {
    local EXIT=$? __atuin_precmd_time=${EPOCHREALTIME-}

    [[ ! $ATUIN_HISTORY_ID ]] && return

    local duration=""
    if ((BASH_VERSINFO[0] >= 5)); then
        duration=$((${__atuin_precmd_time//[!0-9]} - ${__atuin_preexec_time//[!0-9]}))
        if ((duration >= 0)); then
            duration=${duration}000
        else
            duration=""
        fi
    fi

    (ATUIN_LOG=error agent-atuin history end --exit "$EXIT" ${duration:+"--duration=$duration"} -- "$ATUIN_HISTORY_ID" &) >/dev/null 2>&1
    export ATUIN_HISTORY_ID=""
}

# bash-preexec integration
precmd_functions+=(__atuin_precmd)
preexec_functions+=(__atuin_preexec)

# If bash-preexec isn't loaded, use DEBUG trap + PROMPT_COMMAND as fallback
if [[ -z "${bash_preexec_imported-}" && -z "${__bp_imported-}" ]]; then
    __atuin_last_command=""
    trap '__atuin_last_command=$BASH_COMMAND; __atuin_preexec "$BASH_COMMAND"' DEBUG
    PROMPT_COMMAND="__atuin_precmd;${PROMPT_COMMAND:-}"
fi

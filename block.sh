alias @with_block='{ __@func() { __@setfunc'
__open_block='[;'
__close_block=';]'
alias ']'='}; __@run_block; }'

__@setfunc() {
    if [[ -z "$__BLOCK" ]]; then
        local args=( "$@" )
        printf '%q ' "${args[@]::${#args[@]}-1}"
        exit
    fi
}

__@run_block() {
    eval "set -- $(__BLOCK='' __@func)"
    eval "$(declare -f __@func | sed '/__@setfunc /{ d; q }')"
    __BLOCK=__@func "$@"
}

if [ "$SHELL_EXT" = zsh ]; then
    __read_array() { read -r "${@:2}" -A "$1"; }
else
    __read_array() { read -r "${@:2}" -a "$1"; }
fi

@map() {
    __failed=0
    while __read_array __args; do
        "$__BLOCK" "${__args[@]}" || __failed=1
    done
    (( !__failed ))
}
alias @map='@with_block @map'

@filter() {
    while __read_array __args; do
        if "$__BLOCK" "${__args[@]}"; then
            printf '%s\n' "${__args[*]}"
        fi
    done
    true
}
alias @filter='@with_block @filter'

alias @with_block='{ __block_func() { __block_set_func'
# __block_open='[;'
# __block_close=';]'
alias ']'='}; __block_run; }'

__block_set_func() {
    local args=( "$@" )
    printf '%q ' "${args[@]::${#args[@]}-1}"
    exit
}

__block_run() {
    eval "set -- $(eval "$(declare -f __block_func | sed -n '/__block_set_func /{ p; q}')"; wait)"
    local call_block="$__block_func_$RANDOM$RANDOM$RANDOM"
    eval "$( (echo; declare -f __block_func) | sed "1,/__block_set_func / { s/^__block_func/$call_block/; /__block_set_func /d }")"
    "$@"
}

# and that's it!

# alias to make a block
__block__make-block() {
    local funcname="__block-$1"
    # save a new function
    eval "$(declare -f "$call_block" | sed "1s/^$call_block/$funcname/")"
    alias "@$1=@with_block $funcname"
    alias "@$1[=@with_block $funcname {;"
}
alias @make-block='@with_block __block__make-block'

#### some block funcs

if [[ -n "$ZSH_VERSION" ]]; then
    __block_read_array() { read -r "${@:2}" -A "$1"; }
else
    __block_read_array() { read -r "${@:2}" -a "$1"; }
fi

@make-block map [
    __failed=0
    while __block_read_array __args; do
        "$call_block" "${__args[@]}" || __failed=1
    done
    (( !__failed ))
]

@make-block filter [
    while __block_read_array __args; do
        if "$call_block" "${__args[@]}"; then
            printf '%s\n' "${__args[*]}"
        fi
    done
    true
]

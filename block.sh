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
    local call_block="__block_func_$RANDOM$RANDOM$RANDOM"
    local __block_lines='' __block_line='' __block_setfunc=''
    while read -r __block_line ; do
        if [[ -n "$__block_setfunc" ]]; then
            __block_lines+="$__block_line"$'\n'
        elif [[ "$__block_line" == *__block_set_func* ]]; then
            __block_setfunc="${__block_line% &}"
        fi
    done < <(declare -f __block_func)
    unset -f __block_func

    eval "local args=( $__block_setfunc )"
    set -- "${args[@]::${#args[@]}-1}"
    shift
    eval "$call_block() { $__block_lines"
    unset __block_lines __block_line __block_setfunc
    "$@"
    local code="$?"
    unset -f "$call_block"
    return "$code"
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


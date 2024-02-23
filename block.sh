alias @with_block='{ block.call() { __block_set_func'
# __block_open='[;'
# __block_close=';]'
alias ']'='}; __block_run; }'

__block_set_func() {
    local args=( "$@" )
    printf '%q ' "${args[@]::${#args[@]}-1}"
    exit
}

__block_run() {
    eval "set -- $(eval "$(declare -f block.call | sed -n '/__block_set_func /{ p; q}')"; wait)"
    eval "$( (echo; declare -f block.call) | sed '1,/__block_set_func / { /__block_set_func /d }')"
    "$@"
}

# and that's it!

# alias to make a block
__block__make-block() {
    local funcname="__block-$1"
    # save a new function
    eval "$(declare -f block.call | sed "1s/^block\\.call/$funcname/")"
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
        block.call "${__args[@]}" || __failed=1
    done
    (( !__failed ))
]

@make-block filter [
    while __block_read_array __args; do
        if block.call "${__args[@]}"; then
            printf '%s\n' "${__args[*]}"
        fi
    done
    true
]

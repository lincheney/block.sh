# block.sh

Dodgy hacks to get ruby-style blocks / inline anonymous functions in bash and zsh.

Like, add a timestamp to the start of each line:
```bash
ls -l | @map [; echo "$(date) $*" ;]
```

Yeah, I could have done this with a while-read loop.

Anyway, you probably shouldn't use this.

## Installation

1. Download this repo.
1. Run `source block.sh`. Or add it to your `.zshrc` or `.bashrc` or something.

## Usage

There's only 3 pre-defined "block-enabled" commands:
`@map`, `@filter` (guess what they do)
and `@make-block` which helps you make more "block-enabled" commands.

You must also have aliases enabled in your shell.

And then the rough syntax is:
```bash
block-enabled-command ARGS... [; a whole; bunch of; commands ;]
```

The commands between the `[;` and `;]` are wrapped up into a function called `BLOCK.call`
and then the command is run with the `ARGS...` and it can invoke the function when it wants.

### Defining your own commands

You can use the `@make-block` helper or do it yourself.

To make one yourself, define an alias `alias SOMETHING=@with_block FUNC`
then define a function `FUNC` that calls `BLOCK.call`.
Now you can invoke it with `SOMETHING`.

If you run `@make-block NAME [; SOME COMMANDS ;]`, it will do basically the same for you,
but the alias will be called `@NAME` (with a `@` in front).

### Examples

Here's how to make a retry:
```bash
@make-block retry [
    local tries="${1:-5}";
    for i in $(seq "$tries"); do 
        BLOCK.call "$i" && return
    done
    echo "Failed after $tries tries">&2
    return 1 
]
```
(I don't need the semicolons in `[;` and `;]` because there's newlines instead.)

Then use this like:
```bash
# retry numbers until they are below the limit
@retry 5 [; echo try $1; limit=5000; x=$RANDOM; echo "Checking $x < $limit"; (( x < limit )) ;]
```

How about some [hyperfine](https://github.com/sharkdp/hyperfine#shell-functions-and-aliases):
```bash
@make-block hyperfine [; hyperfine --shell=bash "$@" "$(declare -f BLOCK.call); BLOCK.call"; ;]
```
And use like:
```bash
@hyperfine [; sleep 1 ;]
```

You can probably do some dodgy test framework stuff:
```bash
level=0
@make-block describe [
    local level=$(( level+1 )) before_each=
    echo "$1:" >&2
    BLOCK.call 2> >(sed "s/^/$(printf '\t%.s' {1..$level})/" >&2)
]

@make-block before_each [
    before_each="$( (echo; declare -f BLOCK.call) | sed '1,/{/d; $d')"
]

@make-block test [
    if ( eval "$before_each"; BLOCK.call ); then
        echo "PASS: $1" >&2
    else
        echo "FAIL: $1" >&2
    fi
]

@test 'this test works' [; true ;]
@test 'this test doesnt' [; false ;]
@describe 'when the variable x is set' [
    @before_each [; x=hello ;]
    @test 'we can access $x' [; [ "$x" = hello ] ;]
]
@describe 'when the variable x is not set' [
    @test 'we cannot access $x' [; [ "$x" != hello ] ;]
]
```

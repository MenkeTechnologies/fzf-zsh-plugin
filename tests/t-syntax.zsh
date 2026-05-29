#!/usr/bin/env zunit
#{{{                    MARK:Header
#**************************************************************
##### Purpose: fzf-zsh-plugin syntax smoke. Sourcing the plugin
#####          requires `fzf` on PATH (the plugin's `main` runs
#####          unconditionally at source-time); we therefore stub
#####          fzf to a no-op for sourcing.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
}

@test 'plugin entrypoint parses cleanly' {
    run zsh -n "$pluginDir/fzf-zsh-plugin.plugin.zsh"
    assert $state equals 0
}

@test 'fzf-settings.zsh parses cleanly' {
    run zsh -n "$pluginDir/fzf-settings.zsh"
    assert $state equals 0
}

@test 'completions/*.zsh parse cleanly' {
    for file in "$pluginDir/completions/"*; do
        [[ -f "$file" ]] || continue
        run zsh -n "$file"
        assert $state equals 0
    done
}

@test 'sourcing the plugin (fzf stubbed) appends bin/ to PATH' {
    run zsh -c '
        export PATH="/usr/bin:/bin"
        function fzf { true }
        source "'"$pluginDir"'/fzf-zsh-plugin.plugin.zsh"
        echo "$PATH"
    '
    assert $state equals 0
    assert "$output" contains "bin"
}

@test 'bin/ scripts have executable bit set' {
    local non_exec=""
    for file in "$pluginDir/bin/"*; do
        [[ -f "$file" ]] || continue
        [[ -x "$file" ]] || non_exec="$non_exec $file"
    done
    assert "$non_exec" is_empty
}

#--------------------------------------------------------------
# Plugin metadata + dispatch contract pins
#--------------------------------------------------------------

@test 'completions/ directory contains at least one _file' {
    # zsh completion files start with `_`; if the dir holds none,
    # the `fpath` extension at source-time produces no completions.
    local count=0
    for file in "$pluginDir/completions/"_*; do
        [[ -f "$file" ]] && count=$((count + 1))
    done
    [[ $count -gt 0 ]]
    assert $state equals 0
}

@test 'every completion file starts with #compdef directive' {
    local missing=""
    for file in "$pluginDir/completions/"_*; do
        [[ -f "$file" ]] || continue
        run head -1 "$file"
        [[ "$output" =~ ^#compdef ]] || missing="$missing ${file##*/}"
    done
    assert "$missing" is_empty
}

@test 'sourcing plugin twice does not duplicate fpath entries' {
    run zsh -c '
        export PATH="/usr/bin:/bin"
        function fzf { true }
        source "'"$pluginDir"'/fzf-zsh-plugin.plugin.zsh"
        before=$#fpath
        source "'"$pluginDir"'/fzf-zsh-plugin.plugin.zsh"
        after=$#fpath
        echo "delta=$((after-before))"
    '
    assert $state equals 0
    assert "$output" contains "delta=0"
}

@test 'README references the plugin entrypoint filename' {
    run grep -F 'fzf-zsh-plugin.plugin.zsh' "$pluginDir/README.md"
    assert $state equals 0
}

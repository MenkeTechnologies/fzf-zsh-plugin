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
    for file in "$pluginDir/bin/"*; do
        [[ -f "$file" ]] || continue
        [[ -x "$file" ]] || { echo "$file not executable"; exit 1; }
    done
}

#!/usr/bin/env bash
#
# SteamCMD wrapper that strips ANSI escape sequences and carriage returns from
# stdout before arkmanager parses it. SteamCMD can emit colour codes / CR-based
# progress redraws that corrupt arkmanager's mod-download success detection
# (`sed -n 's@...Success. Downloaded item...@...@p'`), leaving mods half-installed
# (#97, #91).
#
# arkmanager invokes "${steamcmdroot}/${steamcmdexec}"; point steamcmdexec at this
# file (see conf.d/arkmanager.cfg) so the filtering is transparent. The real
# steamcmd.sh sits next to this wrapper and is left untouched — arkmanager's
# doDownloadSteamCMD only (re)downloads when steamcmdexec is missing, so a
# distinctly-named wrapper is never clobbered.
#
# stderr is passed through unfiltered; the real SteamCMD exit code is preserved.

set -o pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${here}/steamcmd.sh" "$@" \
  | sed -u -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g' -e 's/\r//g'

exit "${PIPESTATUS[0]}"

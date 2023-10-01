# Copyright (c) 2023 konsolebox
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files
# (the “Software”), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

DID_YOU_MEAN_COMMANDS_CACHE=
DID_YOU_MEAN_COMMANDS_CACHE_SECONDS=0
DID_YOU_MEAN_COMMANDS_CACHE_TTL=60

function did_you_mean {
	local bash_commands=("${BASH_COMMANDS[@]}") r=$? extglob_was_enabled=false
	shopt -q extglob && extglob_was_enabled=true || shopt -s extglob

	if [[ ${bash_commands-} && ${bash_commands} != : && ${bash_commands[1]-} == : &&
			r -eq 127 ]]; then
		function _did_you_mean_compgen_to_var {
			local var=$1
			shift

			if [[ BASH_VERSINFO -ge 6 || BASH_VERSINFO -eq 5 && BASH_VERSINFO[1] -ge 3 ]]; then
				compgen -V "${var}" "$@"
			else
				readarray -t "${var}" < <(compgen "$@")
			fi
		}

		function _did_you_mean_simple_quote {
			local q
			printf -v q %q "$1"

			if [[ $1 == "$q" ]]; then
				__=$1
			elif [[ $1 == *\'* ]]; then
				__=$q
			else
				__="'$1'"
			fi
		}

		local last_command=${bash_commands} best_match command_args possible_commands __
		_did_you_mean_compgen_to_var command_args -W "${last_command}"

		if [[ -z ${DID_YOU_MEAN_COMMANDS_CACHE} ]] || (( SECONDS - \
				DID_YOU_MEAN_COMMANDS_CACHE_SECONDS > DID_YOU_MEAN_COMMANDS_CACHE_TTL )); then
			_did_you_mean_compgen_to_var possible_commands -c
			DID_YOU_MEAN_COMMANDS_CACHE=("${possible_commands[@]}")
			DID_YOU_MEAN_COMMANDS_CACHE_SECONDS=${SECONDS}
		else
			possible_commands=("${DID_YOU_MEAN_COMMANDS_CACHE[@]}")
		fi

		if [[ ${command_args+.} && ${command_args} != exec && ${possible_commands+.} ]]; then
			IFS= read -rd '' best_match < <(pick-best-match -0 -- "${command_args}" \
					"${possible_commands[@]}")

			if [[ ${best_match} != "${command_args}" ]]; then
				_did_you_mean_simple_quote "${best_match}"

				if [[ ${#command_args[@]} -eq 1 ]]; then
					new_command=$__
				else
					# TODO: Need a better way to remove the first word
					new_command=$__" ${last_command##*([[:space:]])+([![:space:]])*([[:space:]])}"
				fi

				until
					read -N1 -rp "Did you mean \"${new_command//$'\n'/\\n}\"? " -d ''
					[[ ${REPLY} == $'\n' ]] || echo
					[[ ${REPLY} == [yYnN] ]]
				do
					:
				done

				if [[ ${REPLY} == [yY] ]]; then
					eval -- "${new_command}"
					r=$?
				fi
			fi
		fi

		unset -f _did_you_mean_compgen_to_var _did_you_mean_simple_quote
	fi

	[[ ${extglob_was_enabled} == false ]] && shopt -u extglob
	return "$r"
}

PROMPT_COMMAND+=(did_you_mean)

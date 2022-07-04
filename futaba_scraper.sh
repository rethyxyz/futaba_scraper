#!/bin/bash
# futaba_scraper: Download matching media-types in a thread.

BAD='\033[0;31m'
GOOD='\033[0;32m'
WARN='\033[0;34m'
ENDC='\033[0m'

EXTS=("png" "gif" "jpg" "jpeg" "webm")
PROGS=("curl" "pup")

main() {
	# counter
	local x=0

	checkdeps ${PROGS[@]}

	[[ ! "$1" ]] && printf "${BAD}Error${ENDC}: No arguments provided.\n"

	for thread_url in "$@"; do
		thread_title=$(\
			curl -s "$thread_url" \
			| pup 'span .subject text{}' \
			| sed -e "s/\ /_/g" -e "s/\#//g" -e "s/\\///g" -e "s/\///g" 
		)

		[[ ! "$thread_title" ]] && thread_title="untitled"

		[[ ! -d "$thread_title" ]] && mkdir -p "$thread_title"

		printf "${WARN}%s${ENDC}\n" "$thread_title"

		for ext in ${EXTS[@]}; do
			# Get the thread_suburls that match the ext.
			thread_suburls=$(\
				curl -s "$thread_url" \
				| pup "a attr{href}" \
				| grep -i "$ext" \
				| sed "s/^\/\///g"\
				| sort -u
			)

			for thread_suburl in ${thread_suburls[@]}; do
				fname="${thread_suburl##*/}"

				[[ ! "$fname" ]] || [[ -e "$thread_title/$fname" ]] && continue

				[[ ! $(echo "$thread_suburl" | grep "^http") ]] \
					&& thread_suburl="https://$thread_suburl"

				curl "$thread_suburl" 2> /dev/null > "$thread_title/$fname" \
					&& printf "${GOOD}$thread_title/$fname${ENDC}\n"
			done
		done
	done
}

checkdeps() {
	local missingdeps=()

	for dep in "$@"; do
		[[ ! $(command -v "$dep") ]] && missingdeps+=($dep)
	done
	if [[ $missingdeps ]]; then
		[[ ${#missingdeps[@]} > 1 ]] \
			&& printf "Missing dependencies:\n" \
			|| printf "Missing dependency:\n"
		for missingdep in ${missingdeps[@]}; do printf "\t$missingdep\n"; done
		exit 1
	fi
}

main "$@"

#!/bin/sh

set -e 

: ${BINDIR:=/usr/local/bin}
: ${EDITOR:=vi}
: ${TMPDIR:=/tmp}
export EDITOR TMPDIR

: ${dummy:=}

# tempfile for mus template
LST=`tempfile`;
# tempfile for directories
dtmp=`tempfile`;
trap 'rm -f "${LST}" "$dtmp"' 0


do_dir() {
	cp /dev/null "$LST"

	while : ; do
		[ -s "${LST}" ] || \
			${BINDIR}/dudl_musgen.pl "$@" > "${LST}" \
			|| return 1
		$dummy ${EDITOR} "${LST}"
		
		invalid=true
		while $invalid ; do
			invalid=false

			echo "what shall I do?"
			echo " r - re-generate list loosing your changes"
			echo " e - re-edit list"
			echo " i - add list to database"
			echo " n - skip to next"
			echo " x - exit"
			read reply

			case "$reply" in
			  i)
				if ${dummy} ${BINDIR}/dudl_musimport.pl "${LST}" ; then
					return 0
				else
					echo "press ENTER to continue";
					read junk
				fi
				;;

			  e)
				:
				;;

			  r)
				cp /dev/null "$LST"
				;;

			  n)
			  	return 0
				;;

			  x)
				return 1
				;;

			  *)
				echo "invalid respnse" >&2
				invalid=true
				;;
			esac
		done
	done
}

unit="$1"
if [ -z "$unit" ]; then
	echo "need at least a unit name like 'sl23'" >&2
	exit 1
fi
shift




${BINDIR}/dudl_musdirs.pl "$unit" > "$dtmp"
${EDITOR} "$dtmp"


exec 6< "$dtmp"

# skip header
read junk <&6
	
while read tit fil genre unitid dir <&6 ; do
	if [ $tit -eq 0 ]; then
		echo "processing $dir" >&2
		do_dir "$@" "$unitid" "$dir" "$genre" || exit 1
	else
		echo "skipping non-virgin '$dir'" >&2
	fi
done


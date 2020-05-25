#!/bin/bash

_obi_comp ()
{
	local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
	if [ "${#COMP_WORDS[@]}" = "2" ]; then
		COMPREPLY=($(compgen -W "align alignpairedend annotate build_ref_db clean_dms clean count ecopcr ecotag export grep head history import less ls ngsfilter sort stats tail test uniq" "${COMP_WORDS[1]}"))
	else
		if [[ "$cur" == *VIEWS* ]]; then
			COMPREPLY=($(compgen -o plusdirs -f -X '!*.obiview' -- "${COMP_WORDS[COMP_CWORD]}"))
		elif  [[ -d $cur.obidms ]]; then
			COMPREPLY=($(compgen -o plusdirs -f $cur.obidms/VIEWS/ -- "${COMP_WORDS[COMP_CWORD]}"), $(compgen -o plusdirs -f -X '!*.obidms/' -- "${COMP_WORDS[COMP_CWORD]}"))
		elif [[ "$cur" == *obidms* ]]; then
			COMPREPLY=($(compgen -o plusdirs -f $cur/VIEWS/ -- "${COMP_WORDS[COMP_CWORD]}"))
    	else
			COMPREPLY=($(compgen -o plusdirs -f -X '!*.obidms/' -- "${COMP_WORDS[COMP_CWORD]}"))
		fi
		if [[ "$prev" == import ]]; then
			COMPREPLY+=($(compgen -f -- "${COMP_WORDS[COMP_CWORD]}"))
		fi
	fi
}

complete -o nospace -F _obi_comp obi

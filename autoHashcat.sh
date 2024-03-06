#!/bin/bash

helpmenu() {
	echo -e "Why you calling the help menu you dumb shit!"
}

getoptions() {
	while getopts ":vh" opt; do
		case $opt in
		v)
			LOG=1
			;;
		\?)
			echo -e "Invalid option"
			helpmenu
			exit 0
			;;
		esac
	done
	shift $((OPTIND - 1))
}

function log() {
	local log=$1
	local message=$2
	if [[ $log = 1 ]]; then
		echo -e "[LOG] $message"
	fi
}

#Formato de nombre de fichero: hashname.mode.<dictId>
function parseName() {
	local file=$1
	log $LOG "File: $file"
	local hashname=$(echo $file | awk -F "." '{print$1}')
	log $LOG "Hashname: $hashname"
	local hashid=$(echo $file | awk -F "." '{print$2}')
	log $LOG "Hashid: $hashid"
	local dict=$(echo $file | awk -F "." '{print$3}')
	if [[ $dic != "" ]]; then
		log $LOG "Dictionary name received: $dict"
	fi
	echo "$hashname" "$hashid" "$dict"
	mv $file $hashname
	log $LOG "Moved hashfile to $hashname"
}

runningHashcat() {
	#Asignacion de variables necesarias
	local dict=$3
	local hashname=$2
	local hashmode=$1

}

getoptions "$@"
parseName "mihash.1340"

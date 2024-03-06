#!/bin/bash

#TODO ahora mismo si recibe un hash ya crackeado se rompè, implementar un regex que reconoce si ya ha sido crackeado y si es asi guardar tmb la salida
#TODO enable config file (probably too lazy to do this anytime soo
helpmenu() {
	echo -e "Why you calling the help menu you dumb shit!"
}

LOG=1

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

#Funcion para depurar la salida( -v)
function log() {
	local log=$1
	local message=$2
	if [[ $log = 1 ]]; then
		echo -e "[LOG] $message" >&2
	fi
}

#Leemos el fichero recivido
#Devolvemos el nombre del hash, y el modo de hashcat a usar
#Formato de nombre de fichero: hashname.mode.<dictId>
parseName() {
	local file=$1
	log "$LOG" "File: $file"
	local hashname=$(echo $file | awk -F "-" '{print$1}')
	log "$LOG" "Hashname: $hashname"
	local hashid=$(echo $file | awk -F "-" '{print$2}')
	log "$LOG" "Hashid: $hashid"
	local dict=$(echo $file | awk -F "-" '{print$3}')
	if [[ $dic != " " ]]; then
		log "$LOG" "Dictionary name received: $dict"
	fi
	echo "$hashname $hashid $dict"
	mv $file $hashname
	log "$LOG" "Moved hashfile to $hashname"
}

#Corremos hashcat
runningHashcat() {
	#Asignacion de variables necesarias
	local dict=$3
	local hashname=$2
	local hashmode=$1
	log $LOG "dict: $dict"
	log $LOG "hashname: $hashname"
	log $LOG "hashmode: $hashmode"
	hashcat -m $hashmode $hashname $dict >tmp.txt
}

#Recibimos el output de hashcat
#Devolvemos el hash, la contraseña y sino ha sido crackeada devolvemos -1
#Si la contraseña no se ha podido crackear devolvemos un error
parseHashcatOutput() {
	local hashOutput=$(cat tmp.txt)
	rm tmp.txt
	local hash=$(echo "$hashOutput" | grep Hash.Target | awk -F " " '{print$2}')
	local status=$(echo "$hashOutput" | grep Status | awk -F " " '{print$2}')
	#Si el hash ha sido crackeado devolvemos esos parametros, si no avisamos y devolvemos -1
	if [[ $status == "Cracked" ]]; then
		local cracked=$(echo "$hashOutput" | grep $hash | head -n 1 | awk -F ":" '{print$2}')
		log $LOG "Cracked!!! \n Password: $cracked"
		log $LOG "Hash: $hash \n Cracked: $cracked"
		echo "$hash $cracked"
	else
		echo -e "Hash couldn't be cracked using $dict, try another dictionary"
		echo -1
	fi
}

getDictionary() {
	dictId=$1
	case $dictId in
	1)
		dict="~/Passlists/SecLists/Passwords/2023-200_most_used_passwords.txt"
		;;
	2)
		dict="~/Passlists/SecLists/Passwords/WiFi-WPA/probable-v2-wpa-top4800.txt"
		;;
	3)
		dict="~/Passlists/SecLists/Passwords/Leaked-Databases/rockyou.txt"
		;;
	4)
		dict="/usr/share/wordlists/rockyou.txt" #TODO remove this option as it is only set to debug
		;;
	esac
	echo "$dict"
}

#recibimos el hash y la crackeada, ademas del nombre del fichero
#Escribimos en el fichero hash:cracked
writeHashCracked() {
	local date=$(date | cut -c 12-19)
	local hash=$1
	local cracked=$2
	local filename=$3
	log $LOG "$cracked $filename $hash"
	echo -e "$hash->$cracked" &>"$date.$filename"
}

main() {
	getoptions "$@"            #Parseamos las opciones recibidas (-v)
	local file=$(ls | grep \-) #Asumimos que el fichero original de hash sera borrado para ser sustituido con el crackeado, si no le ponemos uncracked.hashname
	local result=$(parseName $file)
	local hashName=$(echo $result | awk '{print$1}')
	local hashId=$(echo $result | awk '{print$2}')
	local dictId=$(echo $result | awk '{print$3}')

	local dict=$(getDictionary $dictId)
	log $LOG "Dictionary selected: $dict"
	log $LOG "Hashid: $hashId"
	log $LOG "hashName: $hashName"
	local hashCatOutput=$(runningHashcat $hashId $hashName $dict)
	echo $hashCatOutput
	local result=$(parseHashcatOutput)
	if [[ result != -1 ]]; then
		local hash=$(echo $result | awk '{print$1}')
		local cracked=$(echo $result | awk '{print$2}')
		writeHashCracked $hash $cracked $hashName
	fi
}

main

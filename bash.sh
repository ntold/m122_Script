#!/bin/bash

#===========================================================================#
#Aufruf: 	sudo ./bash.sh						    #
#---------------------------------------------------------------------------#
#Beschreibung: 	Ein Bash Script welche einen Apache-Server einrichtet	    #
#---------------------------------------------------------------------------#
#Autor: 	Nico Berchtold						    #
#---------------------------------------------------------------------------#
#Verison: 	1.0							    #
#---------------------------------------------------------------------------#
#Datum: 	22. Januar 2018						    #
#===========================================================================#

#Variablen
RED='\e[31m'
WHITE='\e[39m'
GREEN='\e[32m'
BLUE='\e[36m' 


#Funktionen

function Start(){
	clear
	CheckInternet
}


function GitEingabe(){
	echo -e "${BLUE}Apache Setup Script"	
	echo -e "${GREEN}Operation wählen ${WHITE}[Setup/Git/Löschen]: "	
	read eingabe;
	case $eingabe in
		Git | git)
			clear			
			GithubSite
		;;
		Setup | setup)
			clear			
			InstallApache
		;;
		Löschen | löschen)
			clear
			DeleteThis
		;;
		*)
			clear
			echo -e "${RED}Falsche Eingabe" 		
			sleep 1
			clear
			GitEingabe
		;;
	esac
}

function CheckInternet(){

	Print "Internetverbindung wird geprüft"

	wget -q --spider http://google.com

	if [ $? -eq 0 ]; then
		PrintSucc "Online!"
		sleep 1
		clear
		GitEingabe
	else
	    	PrintErr "Sie sind offline"
		PrintErr "Bitte Internetverbindung überprüfen"
		sleep 3
		exit 0		
	fi


}


function Install(){

	dpkg -s $1 >> /dev/null 2>&1
	if [ $? -eq 0 ];then
		PrintErr "$1 Ist bereits installiert"
	else
		Print "$1 wird installiert"
		sudo apt-get install $1 -y >> /dev/null
	fi
}

function InstallCheck(){

	dpkg -s $1 >> /dev/null 2>&1
	if [ $? -eq 0 ];then
		PrintSucc "Installation von $1 erfolgreich Abgeschlossen"
	else
		PrintErr "Installation Fehlgeschlafen. Neu Versuch"		
		Install $1		
	fi
}	

#Funktionen der Installation
function InstallApache(){

	Install apache2	
	InstallCheck apache2

	#hostname -I

	sudo systemctl enable apache2 >> /tmp/logfilegit.log 2>&1

	Firewall
}

function Firewall(){

	Install ufw
	InstallCheck ufw
	Print "Firewall wird konfiguriert"
	sudo ufw allow 'Apache Full' >> /dev/null
   	sudo ufw default deny incoming >> /dev/null
   	sudo ufw default allow outgoing >> /dev/null
	sudo ufw allow ssh >> /dev/null
	sudo ufw allow 443 >> /dev/null
	sudo ufw enable	>> /dev/null
	PrintSucc "Erfolgreich konfiguriert"
	sleep 4
	clear

	OpenSite
}


#Beachte mich nicht
#Funktionen der Github Seite
function GithubSite(){
	
	echo -e "${GREEN}Bitte gegen Sie eine ${BLUE}Github-Clone-URL ${GREEN}ein:${WHITE} "
	read -p "" githubsite

	if [[ $githubsite = *"github"* ]]; then		
		Install git
		InstallCheck git
		if [ -d /tmp_gitsite ]; then
			rm -r /tmp_gitsite/*
			Print "Vorhandene Seite wird gelöscht"
		else
			mkdir /tmp_gitsite
		fi	
		cd /tmp_gitsite	 
		Print "Seite wird heruntergeladen"		
		git clone $githubsite >> /tmp/logfilegit.log 2>&1
		PrintSucc "Seite wurde erfolgreich heruntergeladen"
		InstallApache
		SiteInApache
	else 
		clear		
		echo -e "${RED}Ungültiger Github-Link${WHITE}" 	
		GithubSite
	fi
}

function SiteInApache(){
	
	mv /tmp_gitsite/* /tmp_gitsite/html
	yes | sudo cp -rf /tmp_gitsite/* /var/www/ >> /dev/null
	rm -rf /tmp_gitsite
}

function OpenSite(){
	
	echo -e "${GREEN}Wollen Sie die Site mit dem Browser öffnen?${WHITE}"
	read eingabe;
	case $eingabe in
		Ja | ja | Gerne | gerne) 
			x-www-browser http://localhost
		;;
	esac
}

#Funktionen des Löschvorgangs
function DeleteThis(){

	echo -e "${GREEN}Sind Sie sicher, dass Sie den Webserver ${RED}deinstallieren ${GREEN} wollen?${WHITE}" 
	read Deleingabe;
	case $Deleingabe in	
		Ja | ja | j | J) 
			clear		
			Print "Löschvorgang beginnt"		
			Uninstall apache2
			[ -d /var/www/html ] && rm -r /var/www/* 
			Uninstall ufw
			Uninstall git
			[[ -d /tmp_gitsite ]] && rm -rf /tmp_gitsite &
			PrintSucc "Deinstallation abgeschlossen"
			sleep 3
			clear
		;;
		Nein | nein | n | N)
			Print "Vorgang wird abgebrochen. Kehre zurück zum Hauptmenü"
			echo ""
		;;
		*)
			
			
	esac
}

function Uninstall(){

	dpkg -s $1 >> /dev/null 2>&1
	if [ $? -eq 0 ];then
		apt-get purge $1 -y >> /dev/null
		Print "$1 wird deinstalliert"
	else
		PrintErr "Ist nicht installiert. Deinstallation von $1 wird übersprungen"
	fi

}

#Allgemeine Funktionen
function Print(){

	DATE=`date '+%Y-%m-%d %H:%M:%S'`
	echo -e -n "${WHITE}${DATE} ${GREEN} $1 ${WHITE}"
	TrippleDot
	echo ""

}

function PrintSucc(){

	DATE=`date '+%Y-%m-%d %H:%M:%S'`
	echo -e "${WHITE}${DATE} ${BLUE} $1 ${WHITE}"

}

function PrintErr(){
	
	DATE=`date '+%Y-%m-%d %H:%M:%S'`
	echo -e "${WHITE}${DATE} ${RED} $1 ${WHITE}"

}

function TrippleDot(){

	for ((i=1; i<=3; i=i+1));do
		sleep 0.3s		
		echo -e -n "${GREEN}."
		sleep 0.5s
	done
}


Start





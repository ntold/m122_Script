#!/bin/bash

#===============================================================================#
#Aufruf: 	sudo ./bash.sh						    #
#-------------------------------------------------------------------------------#
#Beschreibung: 	Dieses Bashscript hat folgende Funktionen:						#
#	    		- Bei der Option "Setup" wird ein apache2 Webserver installiert	#
#				und eine Firewall heruntergeladen. Diese Firewall wird			#
#				anschliesend noch Konfiguriert. Es wird der "https"-Port		#
#				(443) freigegeben und der "ssh"-Port. Ebenso wird noch alles	#
#				was zum Webserver kommt blockiert.								#
#				- Bei der Option "Git" wird man aufgefordert einen "https"		#
#				Clone Link von Github einzugeben. Dieses Respository wird		#
#				anschliesend in das "/tmp_gitsite" Verzeichnis					#
#				geklont. Dieses Verzeichnis wird anschliesend in das			#
#				"/var/www/html" Verzeichnis kopiert, so dass auf dem			#
#				Webserver die von Ihnen gewünsche Seite angezeigt wird.			#
#				Das vorhin erstellte Verzeichnis wird im nachhinein wieder		#
#				gelöscht.														#
#				- Bei der Option "Löschen" wird alles gelöscht, was im			#
#				Script erstellt wurde (ink. Verzeichnis).						#
#------------------------------------------------------------------------------	#
#Autor: 	Nico Berchtold						    							#
#------------------------------------------------------------------------------	#
#Verison: 	1.0 																#
#-------------------------------------------------------------------------------#
#Datum: 	22. Januar 2018														#
#===============================================================================#

#Variablen

#In diesem Abschnitt werden alle Variablen definiert, welche ich für die Farbige
#Ausgabe haben will
RED='\e[31m'
WHITE='\e[39m'
GREEN='\e[32m'
BLUE='\e[36m'


#Funktionen

#Diese Funktion hat nur die Aufgaben, die "CheckInternet" Funktion aufzurufen
#Die "Start" Funktion wird ganz am Ende des Scriptes aufgerufen. Damit
#alle anderen Funktionen einmal "durchgelaufen" sind. Dies hat den Vorteil,
#dass jede Funktion aufgerufen werden kann, ohne eine bestimmte Reihenfolge einzuhalten.
function Start(){
	clear
	CheckInternet
}


#In dieser Funktion wird die Eingabe "eingabe" vom User eingelesen. Diese Eingabe wird in
#einer "Case" Funktion ausgewertet. Je nach Eingabe werden hier andere Funktionen aufgerufen
function StartEingabe(){
	echo -e "${BLUE}Apache Setup Script"
	echo -e "${GREEN}Operation wählen ${WHITE}[Setup/Git/Löschen]: "
	read -r eingabe;
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
			#Wenn die Eingabe nicht der Norm entspricht, so wird dies gesagt heruntergeladen
			#die "StartEingabe" Funktion nochmal aufgerufen.
			clear
			echo -e "${RED}Falsche Eingabe"
			sleep 1
			clear
			StartEingabe
		;;
	esac
}


# In dieser Funktion wird nur geprüft, ob der Client Internetverbindung hat. Wenn ja, dann
# wird das Script normal ausgegeführt, sprich "StartEingabe" aufgerufen Falls nicht, wird der User aufgefordert seine
# Internetverbindung zu überprfen.

function CheckInternet(){

	Print "Internetverbindung wird geprüft"

	if ! wget -q --spider http://google.com; then
		PrintErr "Sie sind offline"
		PrintErr "Bitte Internetverbindung überprüfen"
		sleep 3
		exit 0
	else
		PrintSucc "Online!"
		sleep 1
		clear
		StartEingabe
	fi


}

# Diese FUnktion wird immer mit einem Parameter aufgerufen. Sie bekommt den Namen eines Programms
# welches installiert werden soll. Falls das Programm schon installiert ist, so wird dies ausgegeben und das Script läuft weiter
function Install(){


	if ! dpkg -s "$1" >> /dev/null 2>&1;then
		Print "$1 wird installiert"
		sudo apt-get install "$1" -y >> /dev/null
	else
		PrintErr "$1 Ist bereits installiert"
	fi
}

# Diese Funktion wird nach jeder Installation aufgerufen. Sie überprüft nach einer Installation von einem Programm nochmal
# ob das Programm wirklich intstalliert wurde. Falls nicht, wird die Funtkion 'Install' mit dem Parameter des Programmnames nochmal
# aufgerufen.
function InstallCheck(){

	if ! dpkg -s "$1" >> /dev/null 2>&1;then
		PrintErr "Installation Fehlgeschlafen. Neu Versuch"
		Install "$1"
	else
		PrintSucc "Installation von $1 erfolgreich Abgeschlossen"
	fi
}

# Funktionen der Installation

# In dieser Funktion werden die Funktionen 'Install' und 'InstallCheck' mit dem Parameter 'apache2' aufgerufen
# Ebenso wird der Autostart von apache2 aktiviert
# Am Ende wird noch die Funktio 'Firewall' aufgerufen
function InstallApache(){

	Install apache2
	InstallCheck apache2

	#hostname -I

	sudo systemctl enable apache2 >> /dev/null 2>&1

	Firewall
}

# In dieser Funktion wird auch 'Install' und 'InstallCheck' mit dem Parameter 'ufw' (<-- Firewall tool) aufgerufen.
# Danach wird die Firewall konfiguriert
# Am schluss wird die Funktion 'OpenSite' aufgerufen
function Firewall(){

	Install ufw
	InstallCheck ufw
	Print "Firewall wird konfiguriert"
	{
		sudo ufw allow 'Apache Full' 		# Port von Apache erlauben
	   	sudo ufw default deny incoming 		# Alles was reinkommt, wird blockiert
	   	sudo ufw default allow outgoing 	# Alles was rausgeht wird erlaubt
		sudo ufw allow ssh 					# Hier wird der Port für SSH freigegeben (futuer proof)
		sudo ufw allow 443 					# Hier wird der Standart https Port freigegeben
		sudo ufw enable						# Am Schluss wird noch die Firewall aktiviert.
	} >> /dev/null
	PrintSucc "Erfolgreich konfiguriert"
	sleep 4
	clear

	OpenSite
}

# In dieser Funktion wird die Github Clone URL in eine Variabel gespeichert und danach überprüft,
# ob dieser Validiert. Falls nicht wird der User nochmal aufgefordert, einen Link einzugeben.
# Falls der Link Validiert wird 'git' installiert, mit der Funtkion Install und danach noch InstallCheck ('git' wird als Parameter übergeben)
# Falls es schon eine githubsite vorhanden ist, wird diese gelöscht.
# Am Ende werden noch die Funtkion 'InstallApache' und 'SiteInApache' aufgerufen
function GithubSite(){

	echo -e "${GREEN}Bitte gegen Sie eine ${BLUE}Github-Clone-URL ${GREEN}ein:${WHITE} "
	read -p -r "" githubsite

	if [[ $githubsite = *"github"* ]]; then
		Install git
		InstallCheck git
		if [ -d /tmp_gitsite ]; then
			rm -r /tmp_gitsite/*
			Print "Vorhandene Seite wird gelöscht"
		else
			mkdir /tmp_gitsite
		fi
		cd /tmp_gitsite || exit
		Print "Seite wird heruntergeladen"
		git clone "$githubsite" >> /tmp/logfilegit.log 2>&1
		PrintSucc "Seite wurde erfolgreich heruntergeladen"
		InstallApache
		SiteInApache
	else
		clear
		echo -e "${RED}Ungültiger Github-Link${WHITE}"
		GithubSite
	fi
}

# In dieser Funktion wird die vorhin heruntergeladene githubsite auf den Apacheserver gezogen.
# Die heruntergeladene Seite wird in "html" benannt, dass man sie anschliesend in das 'var/www/' Verzeichnis
# kopieren kann. Anschliesend wird noch das alte Verzeichnis '/tmp_gitsite' gelöscht, da dieses nicht mehr von nöten ist.
function SiteInApache(){

	mv /tmp_gitsite/* /tmp_gitsite/html
	yes | sudo cp -rf /tmp_gitsite/* /var/www/ >> /dev/null
	rm -rf /tmp_gitsite
}

function OpenSite(){

	echo -e "${GREEN}Wollen Sie die Site mit dem Browser öffnen?${WHITE}"
	read -r eingabe;
	case $eingabe in
		Ja | ja | j | J | aaah | Gerne | gerne)
			x-www-browser http://localhost
		;;
		*)
			exit
		;;
	esac
}

#Funktionen des Löschvorgangs

# Diese Funktion hat die Aufgabe, alles zu löschen, was mit dem Script insalliert worden ist.
# Als erstes wird gefragt, ob man alles wirklich deinstallieren will. Falls nicht, wird die Funktion des "Hauptmenüs" --> "StartEingabe" aufgerufen
# Es ruft die Funktion 'Unintall' auf mit dem Namen des Programmes (Parameter).
function DeleteThis(){

	echo -e "${GREEN}Sind Sie sicher, dass Sie den Webserver ${RED}deinstallieren ${GREEN} wollen?${WHITE}"
	read -r Deleingabe;
	case $Deleingabe in
		Ja | ja | j | J | aaah | Gerne | gerne)
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
			exit 0
		;;
		Nein | nein | n | N)
			Print "Vorgang wird abgebrochen. Kehre zurück zum Hauptmenü"
			echo ""
			StartEingabe
		;;
		*)


	esac
}

# Hier findet die Deinstallation von den aufgerufen	Programmen statt.
# Es erwartet einen Paramter, der den Namen des Programmes hat, welches deinstalliert werden soll.
# Danach überpüft es ob das Programm schon deinstalliert ist oder nicht. Falls es schon deinstalliert ist, so
# wird das Programm übersprungen und das nächste wird deinstalliert.
function Uninstall(){

	#dpkg -s "$1" >> /dev/null 2>&1
	if ! dpkg -s "$1" >> /dev/null 2>&1 ;then
		PrintErr "Ist nicht installiert. Deinstallation von $1 wird übersprungen"
	else
		apt-get purge "$1" -y >> /dev/null
		Print "$1 wird deinstalliert"
	fi

}

#Allgemeine Funktionen

# Funktion, welche einen Parameter erwertet, der den Text beihnhaltet.
# Dieser Paramter wird dann ausgegeben, mit dem entsprechendem Datum und Zeit.
# Es greitf ebenso noch auf Varibalen der Farbe zu. Hier wird der Text Grün ausgegeben
# Ebenso wird noch die Funktion 'TrippleDot' aufgerufen.
function Print(){

	DATE=$(date '+%Y-%m-%d %H:%M:%S')
	echo -e -n "${WHITE}${DATE} ${GREEN} $1 ${WHITE}"
	TrippleDot
	echo ""

}

# Funktion, welche einen Parameter erwertet, der den Text beihnhaltet.
# Dieser Paramter wird dann ausgegeben, mit dem entsprechendem Datum und Zeit.
# Es greitf ebenso noch auf Varibalen der Farbe zu. Hier wird der Text Blau ausgegeben
function PrintSucc(){

	DATE=$(date '+%Y-%m-%d %H:%M:%S')
	echo -e "${WHITE}${DATE} ${BLUE} $1 ${WHITE}"

}

# Funktion, welche einen Parameter erwertet, der den Text beihnhaltet.
# Dieser Paramter wird dann ausgegeben, mit dem entsprechendem Datum und Zeit.
# Es greitf ebenso noch auf Varibalen der Farbe zu. Hier wird der Text Rot ausgegeben
function PrintErr(){

	DATE=$(date '+%Y-%m-%d %H:%M:%S')
	echo -e "${WHITE}${DATE} ${RED} $1 ${WHITE}"

}

# Diese Funktion gibt einfach nur 3 Punkte nacheinander in der Farbe Grün aus.
function TrippleDot(){

	for ((i=1; i<=3; i=i+1));do
		sleep 0.3s
		echo -e -n "${GREEN}."
		sleep 0.5s
	done
}

# Aufruf von der Funktion 'Start'
Start

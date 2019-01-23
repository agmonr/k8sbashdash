#!/bin/bash

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

export sleeptime=0.5

function usage {
  printf "%s\n" "Usage:"
  printf "%s\n" "-n namespace"
  printf "%s\n" "-t sleep time in seconds"
  exit 0 
}



while [ "$1" != "" ]; do
    case $1 in
        -n | --namespace )      shift
                                NameSpace=$1
                                ;;
        -t | --timewait )       shift
                                sleeptime="$1"
                                ;;
        -h | --help )           usage
                                ;;
        * )                     usage
    esac
    shift
done 

if [ "${NameSpace}" == "" ]; then
  usage
  exit
fi

CheckNS=$( kubectl get namespaces | grep -c -w "${NameSpace}"" " )
if [ "${CheckNS}" == "0" ]; then
  echo "No namespace ${NameSpace}"
  echo "Please check"
  kubectl get namespaces
  exit 2
fi


reset
export COLOR_NC='\e[0m' # No Color
export COLOR_WHITE='\e[1;37m'
export COLOR_BLACK='\e[0;30m'
export COLOR_BLUE='\e[0;34m'
export COLOR_LIGHT_BLUE='\e[1;34m'
export COLOR_GREEN='\e[0;32m'
export COLOR_LIGHT_GREEN='\e[1;32m'
export COLOR_CYAN='\e[0;36m'
export COLOR_LIGHT_CYAN='\e[1;36m'
export COLOR_RED='\e[0;31m'
export COLOR_LIGHT_RED='\e[1;31m'
export COLOR_PURPLE='\e[0;35m'
export COLOR_LIGHT_PURPLE='\e[1;35m'
export COLOR_BROWN='\e[0;33m'
export COLOR_YELLOW='\e[1;33m'
export COLOR_GRAY='\e[0;30m'
export COLOR_LIGHT_GRAY='\e[0;37m'
tmpfile=$(mktemp /tmp/k8sd-XXXXXX)


# creating headers
function echon {
  chrlen="${#1}"
  tmpfile1=${tmpfile}-${2}.txt
  printf "" > "${tmpfile1}"
  printf  "${1}" >> "${tmpfile1}"
  for f in $( seq ${chrlen} ${Columns} ); do printf "~" >> "${tmpfile1}"; done
  printf "\n" >> "${tmpfile1}"

}

# putting status into files
function get_status {
  Columns=$(($( tput cols )))
  echon "~~~~~~~~~~ Pods " pods
  kubectl get pods --namespace=${NameSpace} -o wide 2>>/dev/null | grep -e 'Running\|pending\|NAME' | grep -v 'post-' >> "${tmpfile}-pods.txt"

  echon "~~~~~~~~~~ Deployments " deployments
  kubectl get deployments --namespace=${NameSpace} -o wide 2>>/dev/null >> "${tmpfile}-deployments.txt"

  echon "~~~~~~~~~~ Ingresses " ingresses
  kubectl get ingresses --namespace=${NameSpace} -o wide 2>>/dev/null >>"${tmpfile}-ingresses.txt"

  echon "~~~~~~~~~~ Events " events 
  kubectl get events --namespace=${NameSpace} 2>>/dev/null >> "${tmpfile}-events.txt"
}


# reading files line by line and setting colors 
function display_status  {
    StartTlines=$(($( tput lines )-2 ))
    while read l; do
      Tlines=$(($( tput lines )-2 ))

      if [ "${StartTlines}" != "${Tlines}" ]; then
          break
      fi

      if [[ "${element}" == "events" ]]; then
        if [[ $( echo ${l} | grep -c 'Normal' ) != "1"  ]] ; then #marking not read and restart pods
         printf "${COLOR_LIGHT_RED}" 
       fi
      fi

      # pods
      if [[ "${element}" == "pods" ]]; then #marking less then 10 minutes pods
         if [[ "$( echo ${l} | awk '{ print $5 }' | grep -c "m" )" != 0  ]] ; then #marking young pods
           if [[ "$( echo ${l} | awk '{ print $5 }' | sed -e 's/m//' )" -lt 10  ]] ; then #marking young pods
             printf "${COLOR_LIGHT_CYAN}" 
           fi
         fi
         if [[ $( echo ${l} | grep -c '0/' ) != "0" ]]; then #running 0/x pods
           printf "${COLOR_LIGHT_RED}" 
         fi
         if [[ $( echo "${l}" | awk '{ print $4 }' ) != "0" ]] && [[ $( echo "${l}" | awk '{ print $3 }' ) == "Running" ]]; then #marking not read and restart pods
           printf "${COLOR_RED}" 
         fi
      fi

      # Header
      if [[ $( echo ${l} | grep -c 'NAME' ) != "0" ]]; then
        printf "${COLOR_YELLOW}" 
      fi
      if [[ $( echo ${l} | grep -ce "^~" ) != "0" ]]; then #header colors 
        printf "${COLOR_LIGHT_PURPLE}" 
      fi

      # events
      if [[ "${element}" == "events" ]] && [[ $( echo ${l} | grep -ce "^~" ) == "0" ]]; then
        let Ncolumns=${Columns}-21
        PodName=${l:35:20} #get only the evednts and pod names
        Event="${l:220:${Ncolumns}}"
        printf "${PodName} ${Event}\n"
      else
        printf "${l}\n" | cut -c -${Columns} #all of the prints but events
      fi

      printf "${COLOR_NC}"
      tput el #clear to the end of the line
      if [[ "${Line}" -gt "${Tlines}" ]]; then
        break
      fi
      let Line=${Line}+1
     done < "${tmpfile}-${element}.txt"
    rm "${tmpfile}-${element}.txt"

}


function print2end { #clear to scren bottom
   if [[ "${Line}" -lt "${Tlines}" ]]; then
        for f in $( seq ${Line} ${Tlines}); do
        printf "\n"
        tput el 
     done
   fi
}

function ctrl_c() {
  printf "\n\n${COLOR_YELLOW}bye bye${COLOR_NC}\n\n"
  exit 0
}


function main {
  clear
  while true; do 
    get_status
    tput home 
    Line=1
    for element in pods deployments ingresses events; do
      display_status ${element}
    done 
    print2end
    sleep "${sleeptime}"
  done
}


check_params
main



#!/bin/bash
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


function echon {
  chrlen="${#1}"
  echo > /tmp/${2}.txt
  echo -e -n  ${1} >>/tmp/${2}.txt
  for f in $( seq ${chrlen} ${Columns} ); do echo -n "~" >> /tmp/${2}.txt; done 
  echo >> /tmp/${2}.txt
}

NameSpace=$1
Count=0

clear
while true; do 

  Columns=$(($( tput cols )-2 ))
  Tlines=$(($( tput lines )-2 ))
  echon "~~~~~~~~~~ Pods " pods
  kubectl get pods --namespace=${NameSpace} -o wide | grep -e 'Running\|pending\|NAME' >> /tmp/pods.txt

  echon "~~~~~~~~~~ Deployments " deployments
  kubectl get deployments --namespace=${NameSpace} -o wide >> /tmp/deployments.txt 

  echon "~~~~~~~~~~ Ingresses " ingresses
  kubectl get ingresses --namespace=${NameSpace} -o wide >> /tmp/ingresses.txt 

  echon "~~~~~~~~~~ Events " events 
  kubectl get events --namespace=${NameSpace}  >> /tmp/events.txt
  

  tput home 
  Line=1
  for f in pods deployments ingresses events; do
    while read l; do
      if [[ "${f}" == "pods" ]]; then
        if [[ $( echo "${l}" | awk '{ print $4 }' ) != "0" ]] && [[ $( echo "${l}" | awk '{ print $3 }' ) == "Running" ]]; then #marking not read and restart pods
         echo -en "${COLOR_RED}" 
       fi
      fi
      if [[ "${f}" == "events" ]]; then
        if [[ $( echo ${l} | grep -c 'Normal' ) != "1"  ]] ; then #marking not read and restart podsa
         echo -en "${COLOR_RED}" 
       fi
      fi

      if [[ "${f}" == "pods" ]]; then #marking less then 10 minutes pods
        if [[ $( echo ${l} | awk '{ print $5 }' | grep -c "[0-9]m" ) == "1"  ]] ; then #marking young pods
         echo -en "${COLOR_LIGHT_CYAN}" 
       fi
      fi
      if [[ $( echo ${l} | grep -c 'NAME' ) != "0" ]]; then
        echo -en "${COLOR_YELLOW}" 
      fi
      if [[ $( echo ${l} | grep -c '0/' ) != "0" ]]; then
        echo -en "${COLOR_RED}" 
      fi
      if [[ $( echo ${l} | grep -ce "^~" ) != "0" ]]; then #header colors 
        echo -en "${COLOR_LIGHT_PURPLE}" 
      fi
      echo -en "${l}" | cut -c -${Columns}
      echo -en "${COLOR_NC}"
      tput el #clear to the end of the line
      if [[ "${Line}" -gt "${Tlines}" ]]; then
        break
      fi
      let Line=${Line}+1
     done < /tmp/${f}.txt
  done 
 
  sleep 0.1

done

#kubectl get cronjobs --namespace='${NameSpace}' | grep -v Normal

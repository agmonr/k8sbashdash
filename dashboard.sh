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
  echo -e -n  "${1}" >>/tmp/${2}.txt
  for f in $( seq ${chrlen} ${Columns} ); do echo -n "~" >> /tmp/${2}.txt; done 
  echo >> /tmp/${2}.txt
}

function get_status {
  Columns=$(($( tput cols )-2 ))
  Tlines=$(($( tput lines )-2 ))
  echon "~~~~~~~~~~ Pods " pods
  kubectl get pods --namespace=${NameSpace} -o wide | grep -e 'Running\|pending\|NAME' | grep -v 'post-' >> /tmp/pods.txt

  echon "~~~~~~~~~~ Deployments " deployments
  kubectl get deployments --namespace=${NameSpace} -o wide >> /tmp/deployments.txt 

  echon "~~~~~~~~~~ Ingresses " ingresses
  kubectl get ingresses --namespace=${NameSpace} -o wide >> /tmp/ingresses.txt 

  echon "~~~~~~~~~~ Events " events 
  kubectl get events --namespace=${NameSpace}  >> /tmp/events.txt
}

function display_status  {
    while read l; do
      if [[ "${element}" == "events" ]]; then
        if [[ $( echo ${l} | grep -c 'Normal' ) != "1"  ]] ; then #marking not read and restart pods
         echo -en "${COLOR_LIGHT_RED}" 
       fi
      fi

      # pods
      if [[ "${element}" == "pods" ]]; then #marking less then 10 minutes pods
         if [[ "$( echo ${l} | awk '{ print $5 }' | grep -c "m" )" != 0  ]] ; then #marking young pods
           if [[ "$( echo ${l} | awk '{ print $5 }' | sed -e 's/m//' )" -lt 10  ]] ; then #marking young pods
             echo -en "${COLOR_LIGHT_CYAN}" 
           fi
         fi
         if [[ $( echo ${l} | grep -c '0/' ) != "0" ]]; then #running 0/x pods
           echo -en "${COLOR_LIGHT_RED}" 
         fi
         if [[ $( echo "${l}" | awk '{ print $4 }' ) != "0" ]] && [[ $( echo "${l}" | awk '{ print $3 }' ) == "Running" ]]; then #marking not read and restart pods
           echo -en "${COLOR_RED}" 
         fi
      fi

      # Header
      if [[ $( echo ${l} | grep -c 'NAME' ) != "0" ]]; then
        echo -en "${COLOR_YELLOW}" 
      fi
      if [[ $( echo ${l} | grep -ce "^~" ) != "0" ]]; then #header colors 
        echo -en "${COLOR_LIGHT_PURPLE}" 
      fi

      # events
      if [[ "${element}" == "events" ]] && [[ $( echo ${l} | grep -ce "^~" ) == "0" ]]; then
        let Ncolumns=${Columns}+188
        echo -n "$( echo -n "$( echo -en "${l}" | cut -c 36-65 )")" #get only the evednts and pod names
        echo "${l}" | cut -c 219-${Ncolumns} 
      else
        echo -en "${l}" | cut -c -${Columns}
      fi


      echo -en "${COLOR_NC}"
      tput el #clear to the end of the line
      if [[ "${Line}" -gt "${Tlines}" ]]; then
        break
      fi
      let Line=${Line}+1
     done < /tmp/${element}.txt
   
    rm /tmp/${element}.txt
}
if [[ "${Line}" -lt "${Tlines}" ]]; then
   for f in $( seq ${Line} ${Tline}); do
    echo " "
   done
fi


echo $1

function check_param {
  if [ -z "${1}" ]; then
    echo 
    echo "Please provide a namespace."
    echo
    kubectl get namespace
    exit 2
  else
    NameSpace=$1
  fi
}

check_param $1

Count=0
function main {
  clear
  while true; do 
    get_status
    tput home 
    Line=1
    for element in pods deployments ingresses events; do
      display_status ${element}
    done 
    sleep 1
  done
}

main


#kubectl get cronjobs --namespace='${NameSpace}' | grep -v Normal

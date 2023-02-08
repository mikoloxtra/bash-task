#!/bin/bash

#Check number of sites live

SITES_AVAILABLE_FOLDER="/etc/nginx/sites-available"
SITES_ENABLED_FOLDER="/etc/nginx/sites-enabled"

SITES_AVAILABLE=$(grep -r "server_name" $SITES_AVAILABLE_FOLDER | grep -c "server_name")
SITES_ENABLED=$(grep -R "server_name" $SITES_ENABLED_FOLDER | grep -c "server_name")

echo "Websites available: $SITES_ENABLED"
echo "Websites unavailable: $SITES_AVAILABLE"

#Check the status of an array of services and their resource usage ram, disk, cpu, port

SERVICES=(nginx  docker jenkins glances mysql openvpn php8.2 teamviewer windscribe)

declare -A INSTALLATION_FOLDERS
INSTALLATION_FOLDERS=(["nginx"]="/var/lib/nginx" ["docker"]="/var/lib/docker" ["jenkins"]="/var/lib/jenkins" ["glances"]="/usr/share/glances" ["mysql"]="/usr/lib/mysql" ["openvpn"]="/etc/openvpn" ["php8.2"]="/etc/php/8.2" ["teamviewer"]="/opt/teamviewer" ["windscribe"]="/etc/windscribe")

for SERVICE in "${SERVICES[@]}"; do
  PID=$(pgrep -c $SERVICE)

  if [ ! -z "$PID" ]; then
    USAGE=$(top -b n1 -p $PID | tail -n 1)

    CPU_USAGE=$(echo $USAGE | awk '{print $9}')

    MEMORY_USAGE=$(echo $USAGE | awk '{print $10}')

    INSTALLATION_FOLDER=${INSTALLATION_FOLDERS[$SERVICE]}

    if [ -d "$INSTALLATION_FOLDER" ]; then
      DISK_USAGE=$(du -s $INSTALLATION_FOLDER | awk '{print $1}')

      DISK_USAGE=$(echo "$DISK_USAGE/1024" | bc)

      PORTS=$(lsof -i -P -n | grep $SERVICE | awk '{print $9}' | cut -d ":" -f 2 | sort -u)

      if [ ! -z "$PORTS" ]; then
        echo -e "$SERVICE: CPU=$CPU_USAGE% Disk=$DISK_USAGE MB Memory=$MEMORY_USAGE% Ports=$PORTS"
      else
        echo -e "$SERVICE: CPU=$CPU_USAGE% Disk=$DISK_USAGE MB Memory=$MEMORY_USAGE% Ports=None"
      fi
    else
      echo -e "$SERVICE: Installation folder does not exist"
    fi
  else
    echo -e "$SERVICE: Not Running"
  fi
done



#Last 10 lines of nginx logs


access_log="/var/log/nginx/access.log"
error_log="/var/log/nginx/error.log"

if [ -f $access_log ]; then
  echo -e "\033[32mLast 10 lines of Nginx access log:\033[0m"
  tail -n 10 $access_log
else
  echo "No access log to show"
fi

if [ -f $error_log ]; then
  echo -e "\033[31mLast 10 lines of Nginx error log:\033[0m"
  tail -n 10 $error_log
else
  echo "No error log to show"
fi


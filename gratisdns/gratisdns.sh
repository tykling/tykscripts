#!/bin/sh
#####################################################################
#
# The script gratisdns.sh updates a DNS hostname using a DDNS 
# password created in the gratisdns.dk webinterface. The domain and 
# hostname to be updated should be configured below, along with the 
# username and the DDNS password. The script will log to syslog and 
# send an email to the address specified below when the outside IP 
# changes. 
#
# The website used to check the outside IP is http://ip.tyk.nu but 
# this can be changed to any site that only returns the IP and 
# nothing else. 
#
# The script only supports IPv4 at the moment, but can easily be 
# extended to IPv6 as well.
#
# The script needs either the command "fetch" or the command "wget" 
# available, it will automatically use the one it finds available.
#
# This script is public domain, feel free to use it as you wish. The 
# latest version of the script can always be found at the SVN 
# repository at the URL 
# https://svn.tyknet.dk/svn/tykscripts/gratisdns/gratisdns.sh
#
# The script should run on most non-windows platforms. Please report
# any problems to Tykling on IRC (efnet#gratisdns) or to the email
# address thomas@gibfest.dk.
#
# Read more on http://wiki.larsendata.dk/wiki/Dynamisk_IP_%28DDNS%29 
# and http://www.gratisdns.dk
#
#                 /Tykling <thomas@gibfest.dk> january 2012
#####################################################################
#  $Id: gratisdns.sh 5 2012-01-28 16:39:49Z tykling $
#####################################################################


### Configuration
MAILADDY=email@example.com
GDNSUSER=username
GDNSPASS=password
DOMAIN=example.com
HOSTNAME=home.example.com
IPURL=http://ipv4.tyk.nu

################## SCRIPT START #########################################


### Paths
PIDFILE=/var/run/gratisdns.pid
IPFILE=/tmp/lastip
MAILFILE=/tmp/tempmail

### Use either fetch or wget ...
which fetch > /dev/null 2>&1
if [ $? -eq 0 ]; then
	FETCHCMD="fetch -4qo - "
else
	which wget  > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		FETCHCMD="wget -4qO - "
	else
		echo "Unable to find 'fetch' or 'wget' - bailing out"
		exit 1
	fi
fi


### Check pidfile (check if script is already running)
if [ -f $PIDFILE ]; then
	#pidfile exists
	pgrep -qF $PIDFILE
	if [ $? -eq 0 ]; then
		echo "Script already running, bailing out"
		exit 1
	else
		rm $PIDFILE
	fi
fi
echo $$ > $PIDFILE


### Get current outside IP
IP=`${FETCHCMD}${IPURL}`
echo $IP | grep -qE [0-9]+.[0-9]+.[0-9]+.[0-9]+.
if [ $? -ne 0 ]; then
	#The output from the IP service doesn't look like an IP address, unable to get outside IP, bailing out
	exit 0
fi


### check if outside IP has changed ($IPFILE might not exist, if this is the first run)
if [ -f $IPFILE ]; then
	LASTIP=`cat $IPFILE`
	if [ "$IP" = "$LASTIP" ]; then
		#IP unchanged, exiting
		exit 0
	fi
fi


### New outside IP detected, update $IPFILE
echo $IP > $IPFILE


### put the update URL together
GDNSURL="https://ssl.gratisdns.dk/ddns.phtml?u=${GDNSUSER}&p=${GDNSPASS}&d=${DOMAIN}&h=${HOSTNAME}&i=${IP}"


### do the actual update (and save output)
OUTPUT=`${FETCHCMD}${GDNSURL}`


### update complete, send email
rm -f $MAILFILE
echo "New IP detected, hostname $HOSTNAME updated with new IP ${IP} (old IP was ${LASTIP})" > $MAILFILE
echo "Output from GratisDNS service was:" >> $MAILFILE
echo >> $MAILFILE
echo $OUTPUT >> $MAILFILE
cat $MAILFILE | mail -s "New IP detected, hostname $HOSTNAME updated with new IP ${IP} (old IP was ${LASTIP})" $MAILADDY


### log to syslog
logger -t gratisdns.sh "New IP detected, hostname $HOSTNAME updated with new IP ${IP} (old IP was ${LASTIP})"


### clean exit
rm $PIDFILE
exit 0

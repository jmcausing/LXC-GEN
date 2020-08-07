#!/bin/bash

clear
echo "#### LXC generator by John Mark C."
echo "#"

if [ "$1" == "clean" ]
  then

   #  - START - Clean up ssh keys with lxc string
   #
   if [[ $(ls $HOME/.ssh/ | grep lxc) ]]; 
   then
      echo "# LXC ssh files found! Deleting.."
      rm $HOME/.ssh/*lxc*
   else
      echo "# No LXC SSH key found. Already clean!"
   fi
   #
   # - END -  Clean up ssh keys with lxc string


   #  - START - Clean up LXC containers
   #
   if [[ $(lxc list | awk '!/NAME/{print $2}') ]]; 
   then
      echo "# LXC Containers found! Deleting.."
      lxc delete $(lxc list | awk '!/NAME/{print $2}' | awk NF) --force
  
   else
      echo "# No LXC Containers found. Already clean!"
   fi   
   #
   # - END -   Clean up LXC containers

    lxc list
    ls -al $HOME/.ssh/
    echo "#"
    echo "# Done!"
    exit 1
fi


echo "# Hello! Enter the LXC container name please:"

read -p "# Enter LXC name: " lxcname


echo "# Alright! Let's generate the LXC container: $lxcname"
echo "#"
echo "#"

# 18.04
lxc launch ubuntu:18.04 $lxcname

# 16.04
#lxc launch ubuntu:16.04 $lxcname


echo "#"
echo "#Let's generate SSH-KEY gen for this LXC"
echo "#"
ssh-keygen -f $HOME/.ssh/id_lxc_$lxcname -N '' -C 'key for local LXC'

echo "#"
echo "# - START - Details from ssh key gen"

ls $HOME/.ssh/
cat $HOME/.ssh/id_lxc_$lxcname.pub


echo "#"
echo "#"
echo "# START - Info of LXC: ${lxcname}"


echo "#"
echo "# Trying to get the LXC IP Address.."


LXC_IP=$(lxc list | grep ${lxcname} | awk '{print $6}')

VALID_IP=^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$


# START - SPINNER 
#
sp="/-\|"
sc=0
spin() {
   printf "\b${sp:sc++:1}"
   ((sc==${#sp})) && sc=0
}
endspin() {
   printf "\r%s\n" "$@"
}
#
# - END SPINNER


while ! [[ "${LXC_IP}" =~ ${VALID_IP} ]]; do

 # sleep 1
 #  echo "LXC ${lxcname} has still no IP "
 #  echo "Checking again.." 
 #  echo "#"
 #  echo "#"
 #  lxc list
    LXC_IP=$(lxc list | grep ${lxcname} | awk '{print $6}')
    spin
 #  echo "IP is: ${LXC_IP}"
done
endspin

echo "# IP Address found!  ${lxcname} LXC IP: ${LXC_IP}"
#lxc info $lxcname
echo "# "

echo "# Checking status of LXC list again.."
lxc list


echo "# Sending public key to target LXC: " ${lxcname}
echo "#"
#echo lxc file push $HOME/.ssh/id_lxc_${lxcname}.pub ${lxcname}/root/.ssh/authorized_keys

#Pause for 2 seconds to make sure we get the IP and push the file.
sleep 2

# Send SSH key file from this those to the target LXC
lxc file push $HOME/.ssh/id_lxc_${lxcname}.pub ${lxcname}/root/.ssh/authorized_keys --verbose

echo "#"
echo "# Fixing root permission for authorized_keys file"
lxc exec ${lxcname} -- chmod 600 /root/.ssh/authorized_keys --verbose
lxc exec ${lxcname} -- chown root:root /root/.ssh/authorized_keys --verbose
echo "#"
echo "# Adding SSH-key for this host so we can SSH to the target LXC."
eval $(ssh-agent); 
ssh-add $HOME/.ssh/id_lxc_$lxcname
echo "#"
echo "# Done! Ready to connect?"
echo "#"
echo "# Connect to this: ssh -i ~/.ssh/id_lxc_${lxcname} root@${LXC_IP}"
echo "#"
echo "#"
echo "# Thank you for using this basic LXC SSH setup!"
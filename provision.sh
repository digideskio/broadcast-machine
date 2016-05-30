#!/bin/bash

if [[ -z "${IP}" ]]; then
	echo -n "IP of VM: "              ; read IP
fi

if [[ -z "${BDPW}" ]]; then
	echo -n "Stream admin password: " ; read -s BDPW
	echo
fi

echo
echo "Provisioning ${IP}…"
echo

scp -r \
	sc_serv_1.9.8_Linux.tar.gz \
	nginx \
	root@${IP}:

ssh root@${IP} "\
	apt-get update ;\
	apt-get install -y nginx screen htop ;\
	\
	tar zxvf sc_serv_1.9.8_Linux.tar.gz ;\
	\
	sed -i 's/^MaxUser=.*$/MaxUser=800/' sc_serv.conf ;\
	sed -i 's/^Password=.*$/Password=${BDPW}/' sc_serv.conf ;\
	sed -i 's/^PortBase=.*$/PortBase=8300/' sc_serv.conf ;\
	sed -i 's/^AutoDumpSourceTime=.*$/AutoDumpSourceTime=0/' sc_serv.conf ;\
	\
	mv -v ~/nginx/root /usr/share/nginx/ ;\
	ln -vfs /usr/share/nginx/root ~/nginx/root ;\
	/etc/init.d/nginx stop ;\
	sed -i 's#^\troot .*;#\troot /usr/share/nginx/root;#' /etc/nginx/sites-available/default ;\
	/etc/init.d/nginx start ;\
	\
	echo htop… ;\
	screen -S broadcast -t htop -d -m ; sleep 2 ;\
	screen -S broadcast -t htop -X stuff $'htop\n' ; sleep 2 ;\
	echo sc_serv… ;\
	screen -S broadcast -X screen -t sc_serv ; sleep 2 ;\
	screen -S broadcast -t sc_serv -X stuff $'./sc_serv\n' ; sleep 2 ;\
	echo curl… ;\
	screen -S broadcast -X screen -t curl ; sleep 2 ;\
	screen -S broadcast -t curl -X stuff $'while true; do curl -L -C - -o archive_\\\$(date +%Y-%m-%d-%H-%M-%S).mp3 http://localhost:8300/; done' ;\
"

echo
echo "Now: "
echo " ssh root@${IP}"
echo " screen -r"

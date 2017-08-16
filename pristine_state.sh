#/bin/bash

iptables -F # удалить все правила
iptables -X # удалить все цепочки
iptables -P FORWARD ACCEPT # установить дефолтную политику ACCEPT

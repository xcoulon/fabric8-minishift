oc adm policy  --as system:admin add-cluster-role-to-user cluster-admin developer
oc adm policy  --as system:admin add-cluster-role-to-user cluster-admin serviceaccount

MINISHIFT_IP=`minishift ip` DEVELOPER_TOKEN=`oc whoami -t` kedge apply -f tenant.yml
#!/bin/bash

NEWUSER=$1

echo "username:" $NEWUSER
echo -n "password: "
hashauthenticator $JYHUP_AUTH_SECRET $NEWUSER

mkdir -v /jupyterhub-volumes/${NEWUSER}

#EOF

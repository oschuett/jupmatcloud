#!/bin/bash -e

source jupyterhub_secret.sh

set -x
docker pull oschuett/jupyterhub-singleuser:latest
docker container prune -f
rm -v jupyterhub.sqlite
jupyterhub -f jupyterhub_config_docker.py

#EOF


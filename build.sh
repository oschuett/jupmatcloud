#!/bin/bash -e

set -x

docker build -t oschuett/jupyterhub-singleuser:latest ./
#EOF
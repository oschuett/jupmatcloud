#!/bin/bash -e

#===============================================================================

#TODO setup signal handler which shuts down posgresql and aiida.

# setup postgresql
PGBIN=/usr/lib/postgresql/9.5/bin
if [ ! -d /project/.postgresql ]; then
   mkdir /project/.postgresql
   ${PGBIN}/initdb -D /project/.postgresql
   echo "unix_socket_directories = '/project/.postgresql'" >> /project/.postgresql/postgresql.conf
   ${PGBIN}/pg_ctl -D /project/.postgresql -l /project/.postgresql/logfile start
   psql -h localhost -d template1 -c "CREATE USER aiida WITH PASSWORD 'aiida_db_passwd';"
   psql -h localhost -d template1 -c "CREATE DATABASE aiidadb OWNER aiida;"
   psql -h localhost -d template1 -c "GRANT ALL PRIVILEGES ON DATABASE aiidadb to aiida;"
else
   # Postgresql was probably not shutdown properly. Cleaning up the mess...
   echo "" > /project/.postgresql/logfile # empty log files
   rm -vf /project/.postgresql/.s.PGSQL.5432
   rm -vf /project/.postgresql/.s.PGSQL.5432.lock
   rm -vf /project/.postgresql/postmaster.pid
   #${PGBIN}/pg_ctl -D /project/.postgresql stop || true
   ${PGBIN}/pg_ctl -D /project/.postgresql -l /project/.postgresql/logfile start
   TIMEOUT=20
   until psql -h localhost template1 -c ";" || [ $TIMEOUT -eq 0 ]; do
      echo ">>>>>>>>> Waiting for postgres server, $((TIMEOUT--)) remaining attempts..."
      tail -n 50 /project/.postgresql/logfile
      sleep 1
   done
fi


#===============================================================================
# setup AiiDA
if [ ! -d /project/.aiida ]; then
   verdi setup                          \
      --non-interactive                 \
      --email some.body@xyz.com         \
      --first-name Some                 \
      --last-name Body                  \
      --institution XYZ                 \
      --backend django                  \
      --db_user aiida                   \
      --db_pass aiida_db_passwd         \
      --db_name aiidadb                 \
      --db_host localhost               \
      --db_port 5432                    \
      --repo /project/.aiida/repository \
      default

   verdi profile setdefault verdi default 
   verdi profile setdefault daemon default
   bash -c 'echo -e "y\nsome.body@xyz.com" | verdi daemon configureuser'

   # increase logging level
   verdi devel setproperty logging.celery_loglevel DEBUG
   verdi devel setproperty logging.aiida_loglevel DEBUG

   # start the daemon
   verdi daemon start

   # setup pseudopotentials
   cd /opt/pseudos
   for i in *; do
      verdi data upf uploadfamily $i $i $i
   done

else
   verdi daemon stop || true
   verdi daemon start
fi


#===============================================================================
# create bashrc
if [ ! -e /project/.bashrc ]; then
   cp -v /etc/skel/.bashrc /etc/skel/.bash_logout /etc/skel/.profile /project/
   echo 'eval "$(verdi completioncommand)"' >> /project/.bashrc
   echo 'export PYTHONPATH="${PYTHONPATH}:/project"' >> /project/.bashrc
fi


#===============================================================================
# generate ssh key
if [ ! -e /project/.ssh/id_rsa ]; then
   mkdir -p /project/.ssh
   ssh-keygen -f /project/.ssh/id_rsa -t rsa -N ''
fi


#===============================================================================
# setup AiiDA jupyter extension
if [ ! -e /project/.ipython/profile_default/ipython_config.py ]; then
   mkdir -p /project/.ipython/profile_default/
   echo "c = get_config()"                         > /project/.ipython/profile_default/ipython_config.py
   echo "c.InteractiveShellApp.extensions = ["    >> /project/.ipython/profile_default/ipython_config.py
   echo "  'aiida.common.ipython.ipython_magics'" >> /project/.ipython/profile_default/ipython_config.py
   echo "]"                                       >> /project/.ipython/profile_default/ipython_config.py
fi


#===============================================================================
#start Jupyter notebook server
export SHELL=/bin/bash

cd /project
jupyterhub-singleuser            \
  --port=8888                    \
  --ip=0.0.0.0                   \
  --user=$JPY_USER               \
  --cookie-name=$JPY_COOKIE_NAME \
  --base-url=$JPY_BASE_URL       \
  --hub-prefix=$JPY_HUB_PREFIX   \
  --hub-api-url=$JPY_HUB_API_URL \
  --notebook-dir="/project"

#===============================================================================

#EOF

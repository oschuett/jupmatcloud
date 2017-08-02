FROM ubuntu:latest

USER root

# install debian packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales               \
    psmisc                \
    bzip2                 \
    build-essential       \
    libssl-dev            \
    libffi-dev            \
    python-dev            \
    git                   \
    postgresql            \
    cp2k                  \
    quantum-espresso      \
    python-pip            \
    python-setuptools     \
    python-wheel          \
    python3-pip           \
    python3-setuptools    \
    python3-wheel         \
    python-tk             \
    wget                  \
    ca-certificates       \
    vim                   \
    ssh                   \
  && rm -rf /var/lib/apt/lists/*


# fix locals
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen


# install PyPI packages for Pyhon 3
RUN pip3 install --upgrade \
    'pip'               \
    'jupyter'           \
    'jupyterhub'


# install PyPI packages for Pyhon 2
#IPython 6 requires Python 3.3 or later
RUN pip2 install --upgrade \
    'pip'               \
    'ipython>=5,<6'     \
    'ase'               \
    'seekpath'          \
    'aiida'             \
    'pythreejs'         \
    'nglview'           \
    'bqplot'            \
    'ipympl'


# enable nbextension
RUN jupyter nbextension enable  --sys-prefix --py widgetsnbextension && \
    jupyter nbextension enable  --sys-prefix --py pythreejs          && \
    jupyter nbextension enable  --sys-prefix --py nglview            && \
    jupyter nbextension enable  --sys-prefix --py bqplot             && \
    jupyter nbextension enable  --sys-prefix --py ipympl


# Quantum-Espresso Pseudo Potentials
WORKDIR /opt/pseudos
RUN for name in SSSP_acc_PBE SSSP_acc_PBESOL SSSP_eff_PBE SSSP_eff_PBESOL; do  \
       wget http://www.materialscloud.ch/sssp/pseudos/${name}.tar.gz;          \
       tar -xvzf ${name}.tar.gz;                                               \
       rm -v ${name}.tar.gz;                                                   \
    done;                                                                      \
    chown -R root:root /opt/pseudos/;                                          \
    chmod -R +r /opt/pseudos/
# remove misplaced pseudo
RUN rm -vf /opt/pseudos/SSSP_eff_PBE/Be_ONCV_PBE-1.0.upf


# install Leopold's ASEtk
RUN ASETK_VERSION=0.3-beta                                                  && \
    cd /opt                                                                 && \
    wget https://github.com/ltalirz/asetk/archive/v${ASETK_VERSION}.tar.gz  && \
    tar -xvzf v${ASETK_VERSION}.tar.gz                                      && \
    rm -v v${ASETK_VERSION}.tar.gz                                          && \
    cd asetk-${ASETK_VERSION}                                               && \
    cp -rv asetk/  /usr/local/lib/python2.7/dist-packages/                  && \
    cp -rv scripts/* /usr/local/bin/


# install aiida-cp2k
WORKDIR /opt
RUN git clone https://github.com/cp2k/aiida-cp2k.git && \
    cp -rv ./aiida-cp2k/aiida_cp2k/calculations  /usr/local/lib/python2.7/dist-packages/aiida/orm/calculation/job/cp2k && \
    cp -rv ./aiida-cp2k/aiida_cp2k/parsers       /usr/local/lib/python2.7/dist-packages/aiida/parsers/plugins/cp2k


# # install ipython-file-upload
# # pip install fileupload # outdated
WORKDIR /opt
RUN git clone https://github.com/peteut/ipython-file-upload.git             && \
    cd ipython-file-upload                                                  && \
    pip2 install .                                                          && \
    jupyter nbextension install --sys-prefix --py --symlink fileupload      && \
    jupyter nbextension enable  --sys-prefix --py           fileupload


# install Jupyter Appmode
WORKDIR /opt
RUN git clone https://github.com/oschuett/jupyter_appmode.git  && \
    ln -s /opt/jupyter_appmode/jupyter_appmode /usr/local/lib/python2.7/dist-packages/jupyter_appmode  && \
    jupyter nbextension     install --sys-prefix --py --symlink jupyter_appmode  && \
    jupyter nbextension     enable  --sys-prefix --py           jupyter_appmode  && \
    jupyter serverextension enable  --sys-prefix --py           jupyter_appmode


# install MolPad
WORKDIR /opt
RUN git clone https://github.com/oschuett/molview-ipywidget.git  && \
    ln -s /opt/molview-ipywidget/molview_ipywidget /usr/local/lib/python2.7/dist-packages/molview_ipywidget  && \
    jupyter nbextension     install --sys-prefix --py --symlink molview_ipywidget  && \
    jupyter nbextension     enable  --sys-prefix --py           molview_ipywidget


# install Tini
WORKDIR /opt
RUN wget https://github.com/krallin/tini/releases/download/v0.15.0/tini && \
    chmod +x /opt/tini
ENTRYPOINT ["/opt/tini", "--"]

#===============================================================================
RUN mkdir /project                                                 && \
    useradd --home /project --uid 1234 --shell /bin/bash scientist && \
    chown -R scientist:scientist /project

EXPOSE 8888
USER scientist
COPY start-singleuser.sh /opt/
WORKDIR /project
CMD ["/opt/start-singleuser.sh"]

#EOF
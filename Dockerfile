FROM wolframresearch/wolframengine:12.2.0
# avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive
USER root

# ---- PYTHON3 ----
# install python3, git,  and some additional libs for wolfram engine
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl git libgl1-mesa-glx libfontconfig1 libasound2 \
  python3-pip python3-dev python3-setuptools \
  && apt-get -qq purge \
  && apt-get -qq clean \
  && rm -rf /var/lib/apt/lists/* \
  && cd /usr/local/bin \
  && ln -s /usr/bin/python3 python \
  && pip3 install --upgrade pip

# install the notebook package
RUN pip install --no-cache --upgrade pip && \
    pip install --no-cache notebook

# set up user
ARG NB_USER="george"
ARG NB_UID="1000"
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}

RUN groupadd \
        --gid ${NB_UID} \
        ${NB_USER} && \
    useradd \
        --comment "Default user" \
        --create-home \
        --gid ${NB_UID} \
        --no-log-init \
        --shell /bin/bash \
        --uid ${NB_UID} \
        ${NB_USER}

ARG REPO_DIR=${HOME}
ENV REPO_DIR ${REPO_DIR}
WORKDIR ${REPO_DIR}
ENV PATH ${HOME}/.local/bin:${REPO_DIR}/.local/bin:${PATH}
ENV APP_BASE /srv


# ---- WOLFRAM ENGINE ----
ENV WOLFRAMSCRIPT_ENTITLEMENTID O-WSDS-9826-R46Z92PDKGS2Z
ENV WOLFRAM_PATH ${APP_BASE}/wolfram

# add wolframengine jupyter kernel
RUN mkdir -p ${WOLFRAM_PATH} && cd ${WOLFRAM_PATH} && \
    git clone https://github.com/okofish/WolframLanguageForJupyter.git && \
    cd WolframLanguageForJupyter && \
    git checkout 1429f1c86b60ba79794eace378eae4f5941fc9cf -b feature/OnDemandLicensing && \
    ./configure-jupyter.wls add && \
    jupyter kernelspec list

# ---- WRAP UP ----
COPY . ${REPO_DIR}
RUN chown -R ${NB_USER}:${NB_USER} ${REPO_DIR}
USER ${NB_USER}
CMD ["jupyter", "notebook", "--ip", "0.0.0.0"]

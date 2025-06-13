FROM python:3.11-slim-bookworm

# Basissetup
ENV USERNAME=inventree \
    HOME_DIR=/home/inventree \
    APP_DIR=/home/inventree/app \
    SRC_DIR=/home/inventree/app/inventree \
    VENV_DIR=/home/inventree/venv \
    INVENTREE_STATIC_ROOT=/home/inventree/static\
    PATH="/home/inventree/venv/bin:$PATH"

# Systempakete installieren
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip gnupg build-essential libpq-dev libjpeg-dev zlib1g-dev libmagic-dev \
    gettext libxml2-dev libxslt-dev python3-dev libffi-dev pkg-config libxmlsec1-dev \
    libssl-dev libxmlsec1-openssl cargo rustc postgresql-client \
    libpango-1.0-0 libpangocairo-1.0-0 libcairo2 libgdk-pixbuf2.0-0 shared-mime-info \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# User & Arbeitsverzeichnis
RUN useradd -ms /bin/bash ${USERNAME}
USER ${USERNAME}
WORKDIR ${APP_DIR}

# Letzten stabilen Tag von GitHub holen
RUN export INVENTREE_TAG=$(curl -s https://api.github.com/repos/inventree/InvenTree/releases/latest | grep -oP '"tag_name":\s*"\K(.*)(?=")') && \
    echo "InvenTree neueste Version: $INVENTREE_TAG" && \
    echo "$INVENTREE_TAG" > ${APP_DIR}/.inventree-version

# InvenTree-Code holen
RUN export INVENTREE_TAG=$(cat ${APP_DIR}/.inventree-version) && \
    git clone --branch $INVENTREE_TAG https://github.com/inventree/InvenTree.git ${SRC_DIR}

# Requirements patchen
WORKDIR ${SRC_DIR}
RUN sed -i 's|^rapidfuzz==.*$|rapidfuzz==3.13.0|' src/backend/requirements.txt && \
    sed -i 's|cryptography==43.0.3.*|cryptography==45.0.2|' src/backend/requirements.txt && \
    sed -i 's|xmlsec==1.3.*|xmlsec==1.3.13|' src/backend/requirements.txt && \
    sed -i 's|^zopfli==.*$|zopfli|' src/backend/requirements.txt && \
    sed -i '/--hash=/d' src/backend/requirements.txt

# Python-Umgebung aufsetzen
RUN python -m venv ${VENV_DIR} && \
    . ${VENV_DIR}/bin/activate && \
    pip install --upgrade pip setuptools wheel && \
    pip install maturin scikit-build-core && \
    pip install git+https://github.com/mehcode/python-xmlsec.git@1.3.13 && \
    pip install psycopg2-binary && \
    pip install --no-build-isolation --no-cache-dir -r ${SRC_DIR}/src/backend/requirements.txt && \
    pip install invoke

# Wechsel ins Quellverzeichnis
WORKDIR ${SRC_DIR}
# Entferne --require-hashes aus allen pip-Aufrufen in tasks.py
RUN sed -i 's/--require-hashes //g' tasks.py


# Frontend herunterladen & bauen
WORKDIR ${SRC_DIR}/src/backend/InvenTree
RUN mkdir -p web/static/web
RUN    invoke frontend-download -t $(cat ${APP_DIR}/.inventree-version) 
COPY .env ${SRC_DIR}/.env
RUN export $(grep -v '^#' ${SRC_DIR}/.env | xargs) && \
    invoke static
# Done
WORKDIR ${SRC_DIR}/src/backend/InvenTree

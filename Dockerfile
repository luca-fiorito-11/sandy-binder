FROM python:3.11-slim

# Avoid writing .pyc files and enable unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gfortran \
    cmake \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# install the notebook package
RUN pip install --no-cache --upgrade pip && \
    pip install --no-cache notebook jupyterlab \
    matplotlib \
    seaborn \
    scikit-learn \
    pandas \
    numpy \
    scipy \
    serpentTools \
    sandy

# create user with a home directory
ARG NB_USER
ARG NB_UID
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}
WORKDIR ${HOME}
USER ${USER}

# --- Build NJOY2016 and keep only the binary ---
RUN git clone --depth 1 https://github.com/njoy/NJOY2016.git \
 && cd NJOY2016 && mkdir build && cd build \
 && FC=gfortran CFLAGS="-w" FFLAGS="-w" cmake -DPython3_EXECUTABLE=$(which python3) .. \
 && make -j$(nproc) && make install \
 # Save binary and remove everything else
 && cp /usr/local/bin/njoy /tmp/njoy_binary \
 && apt-get purge -y build-essential gfortran cmake git \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/* /app/NJOY2016 \
 && mv /tmp/njoy_binary /usr/local/bin/njoy
    
# Make NJOY available via env var
ENV NJOY=/usr/local/bin/njoy

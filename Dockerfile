FROM python:3.11-slim AS builder

# Install system dependencies for NJOY compilation
RUN apt-get update && apt-get install -y \
    build-essential \
    gfortran \
    cmake \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# --- Build NJOY2016 ---
RUN git clone --depth 1 https://github.com/njoy/NJOY2016.git \
 && cd NJOY2016 && mkdir build && cd build \
 && cmake -DPython3_EXECUTABLE=$(which python3) .. \
 && make -j$(nproc) && make install

# --- Stage 2: Final Image ---
FROM python:3.11-slim

# Avoid writing .pyc files and enable unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# install sandy and the notebook package
RUN pip install --no-cache --upgrade pip && \
    pip install --no-cache notebook jupyterlab \
    matplotlib \
    seaborn \
    scikit-learn \
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
# Switch to the non-root user
USER ${USER}

# Copy the NJOY binary from the builder stage
COPY --from=builder /usr/local/bin/njoy /usr/local/bin/

# Set NJOY environment variable
ENV NJOY=/usr/local/bin/njoy

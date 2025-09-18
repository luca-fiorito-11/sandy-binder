# ------------------------
# Dockerfile for NJOY + Sandy + Binder
# ------------------------

FROM python:3.11-slim

# Avoid writing .pyc files and enable unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# ------------------------
# Install system dependencies for building NJOY
# ------------------------
RUN apt-get update && apt-get install -y \
    build-essential \
    gfortran \
    cmake \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# ------------------------
# Create Binder-compatible user
# ------------------------
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER=${NB_USER}
ENV HOME=/home/${NB_USER}
RUN adduser --disabled-password --gecos "Default user" --uid ${NB_UID} ${NB_USER}

# ------------------------
# Compile NJOY2016 and keep only the binary
# ------------------------
RUN git clone --depth 1 https://github.com/njoy/NJOY2016.git /tmp/NJOY2016 \
 && mkdir /tmp/NJOY2016/build \
 && cd /tmp/NJOY2016/build \
 && cmake -DPython3_EXECUTABLE=$(which python3) .. \
 && make -j$(nproc) && make install \
 # Save the binary and clean up source & build tools
 && cp /usr/local/bin/njoy /usr/local/bin/njoy_binary \
 && apt-get purge -y build-essential gfortran cmake git \
 && apt-get autoremove -y \
 && rm -rf /tmp/NJOY2016 \
 && mv /usr/local/bin/njoy_binary /usr/local/bin/njoy

# ------------------------
# Set NJOY environment variable
# ------------------------
ENV NJOY=/usr/local/bin/njoy

# ------------------------
# Copy your code/notebooks into home directory
# ------------------------
COPY --chown=${NB_USER}:${NB_USER} . ${HOME}
WORKDIR ${HOME}
USER ${NB_USER}

# ------------------------
# Install Python packages
# ------------------------
RUN pip install --no-cache-dir \
    sandy \
    "jupyterlab>=4.0,<5" \
    "notebook>=7.0,<8" \
    matplotlib \
    seaborn \
    scikit-learn \
    serpentTools

# ------------------------
# Expose Jupyter port
# ------------------------
EXPOSE 8888

# ------------------------
# Launch JupyterLab
# ------------------------
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--NotebookApp.token=''"]

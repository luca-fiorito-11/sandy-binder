# ------------------------
# Dockerfile for Sandy + Binder (without NJOY)
# ------------------------

FROM python:3.11-slim

# Avoid writing .pyc files and enable unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# ------------------------
# Create Binder-compatible user
# ------------------------
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER=${NB_USER}
ENV HOME=/home/${NB_USER}
RUN adduser --disabled-password --gecos "Default user" --uid ${NB_UID} ${NB_USER}

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
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser"]

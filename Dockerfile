FROM fedora:35
RUN dnf update -y && \
    dnf install -y gcc-g++ openmpi-devel && \
    dnf clean all -y && \
    groupadd demo && \
    useradd demo -d /home/demo -g demo
COPY --chown=demo:demo scripts runtime_analysis compress_package related_work spack.yaml process_script_mpi.py README.md  /app
WORKDIR /app
RUN dnf install -y git tar zip patch 
RUN dnf install -y xz bzip2 file
RUN dnf install -y python3-devel
USER demo
RUN git clone --depth=1 https://github.com/spack/spack &&\
    git clone --depth=1 https://github.com/robertu94/spack_packages && \
    source ./spack/share/spack/setup-env.sh &&\
    spack compiler find &&  \
    spack external find && \
    spack repo add --scope=site ./spack_packages  && \
    spack env activate /app && \
    spack install
RUN Rscript setup.R
ENV foo=bar

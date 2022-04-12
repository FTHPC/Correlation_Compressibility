from fedora:35 as builder

RUN dnf update -y && \
    dnf install -y gcc-g++ gfortran glib-devel libtool findutils file pkg-config lbzip2 git tar zip patch xz python3-devel coreutils m4 automake autoconf cmake openssl-devel openssh-server openssh bison bison-devel gawk && \
    dnf clean all -y && \
    groupadd demo && \
    useradd demo -d /home/demo -g demo
RUN echo "demo    ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/demo
RUN mkdir /app && chown demo:demo /app
COPY --chown=demo:demo spack.yaml /app
RUN ln -s /usr/lib64/libpthread.so.0 /usr/lib64/libpthread.so
RUN su demo -c "git clone --depth=1 https://github.com/spack/spack /app/spack"
RUN su demo -c "git clone --depth=1 https://github.com/robertu94/spack_packages /app/robertu94_packages"
WORKDIR /app
USER demo
RUN source /etc/profile &&\
    spack external find && \
    spack repo add /app/robertu94_packages && \
    spack install && \
    spack gc -y && \
    spack clean -a

RUN find -L /app/.spack-env/view/* -type f -exec readlink -f '{}' \; | \
    grep -v 'nsight-compute' | \
    xargs file -i | \
    grep 'charset=binary' | \
    grep 'charset=binary' | \
    grep 'x-executable\|x-archive\|x-sharedlib' | \
    awk -F: '{print $1}' | xargs strip -s


from fedora:35 as final
RUN dnf update -y && \
    dnf install -y libgfortran python3-devel libstdc++ openssh-clients && \
    dnf clean all -y && \
    groupadd demo && \
    useradd demo -d /home/demo -g demo && \
    ln -s /usr/lib64/libpthread.so.0 /usr/lib64/libpthread.so
RUN echo "demo    ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/demo
COPY --from=builder --chown=demo:demo /app /app
COPY --chown=demo:demo process_script_mpi.py README.md  /app
COPY --chown=demo:demo scripts /app/scripts
COPY --chown=demo:demo runtime_analysis /app/runtime_analysis
COPY --chown=demo:demo compress_package /app/compress_package
COPY --chown=demo:demo related_work /app/related_work 
COPY --chown=demo:demo datasets /app/datasets 
WORKDIR /app
RUN Rscript scripts/setup.R
USER demo

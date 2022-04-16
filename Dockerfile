from fedora:35 as builder

RUN dnf install -y gcc-g++ gfortran glib-devel libtool findutils file pkg-config lbzip2 git tar zip patch xz python3-devel coreutils m4 automake autoconf cmake openssl-devel openssh-server openssh bison bison-devel gawk which && \
    dnf clean all -y && \
    groupadd demo && \
    useradd demo -d /home/demo -g demo
RUN echo "demo    ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/demo
RUN mkdir /app && chown demo:demo /app
RUN ln -s /usr/lib64/libpthread.so.0 /usr/lib64/libpthread.so
RUN su demo -c "git clone --depth=1 https://github.com/spack/spack /app/spack"
RUN su demo -c "git clone --depth=1 https://github.com/robertu94/spack_packages /app/robertu94_packages"
WORKDIR /app
USER demo
COPY container_startup.sh /etc/profile.d/
COPY --chown=demo:demo spack.yaml /app
RUN source /etc/profile &&\
    source /app/spack/share/spack/setup-env.sh &&\
    spack env activate /app &&\
    spack external find && \
    spack repo add /app/robertu94_packages && \
    spack install -j 2 && \
    spack gc -y && \
    spack clean -a
RUN find -L /app/.spack-env/view/* -type f -exec readlink -f '{}' \; | \
    grep -v 'nsight-compute' | \
    xargs file -i | \
    grep 'charset=binary' | \
    grep 'charset=binary' | \
    grep 'x-executable\|x-archive\|x-sharedlib' | \
    awk -F: '{print $1}' | xargs strip -s



RUN sudo dnf install -y zlib-devel
COPY --chown=demo:demo scripts /app/scripts
RUN source /app/spack/share/spack/setup-env.sh &&\
  spack env activate /app && \
  Rscript scripts/setup.R
COPY --chown=demo:demo process_script_mpi.py README.md  /app
COPY --chown=demo:demo runtime_analysis /app/runtime_analysis
COPY --chown=demo:demo compress_package /app/compress_package
COPY --chown=demo:demo related_work /app/related_work 
COPY --chown=demo:demo datasets /app/datasets 
COPY --chown=demo:demo replicate_figures /app/replicate_figures


from fedora:35 as final
RUN dnf update -y && \
    dnf install -y libgfortran python3-devel libstdc++ openssh-clients which zlib-devel && \
    dnf clean all -y && \
    groupadd demo && \
    useradd demo -d /home/demo -g demo && \
    ln -s /usr/lib64/libpthread.so.0 /usr/lib64/libpthread.so
RUN echo "demo    ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/demo
RUN mkdir /app && chown demo:demo /app
COPY container_startup.sh /etc/profile.d/
COPY --from=builder --chown=demo:demo /app /app
WORKDIR /app
USER demo
ENV COMPRESS_HOME=/app 
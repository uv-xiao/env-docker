# syntax = edrevo/dockerfile-plus

FROM ubuntu:22.04 AS builder
WORKDIR /root

# Language
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

SHELL [ "/bin/bash", "-c" ]

# Change apt source to local mirror
RUN sed -ri.bak -e 's/\/\/.*?(archive.ubuntu.com|mirrors.*?)\/ubuntu/\/\/mirrors.pku.edu.cn\/ubuntu/g' -e '/security.ubuntu.com\/ubuntu/d' /etc/apt/sources.list

# Install dependent packages
RUN \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    autoconf bison build-essential ccache flex help2man libfl2 libfl-dev libgoogle-perftools-dev \
    numactl perl perl-doc curl wget git sudo ca-certificates keyboard-configuration console-setup \
    libreadline-dev gawk tcl-dev libffi-dev graphviz xdot libboost-system-dev python3-pip \
    libboost-python-dev libboost-filesystem-dev zlib1g-dev time device-tree-compiler libelf-dev \
    bc unzip zlib1g zlib1g-dev libtcl8.6 iverilog pkg-config clang verilator vim ripgrep cmake openjdk-8-jre && \
    apt-get clean

# Set proxy
INCLUDE+ Dockerfile.proxy


# Install OpenROAD
RUN \
    git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts && \
    cd OpenROAD-flow-scripts && \
    sed '173,199 {s/^/#/}' ./etc/DependencyInstaller.sh > .tmp && mv .tmp ./etc/DependencyInstaller.sh && \
    chmod +x ./etc/DependencyInstaller.sh && \
    sudo ./setup.sh && \
    sudo ./build_openroad.sh --local

ENV OPENROAD_FLOW=/root/OpenROAD-flow-scripts/flow

# Install conda
RUN \
    wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh" && \
    printf '\nyes\n\n\n' | bash Miniforge3-$(uname)-$(uname -m).sh && \
    eval "$(/root/miniforge3/bin/conda shell.bash hook)" && \
    conda install -n base conda-libmamba-solver && \
    conda config --set solver libmamba && \
    conda install -n base conda-lock==1.4.0 

# Install Chipyard
RUN \
    eval "$(/root/miniforge3/bin/conda shell.bash hook)" && \
    conda activate base && \
    git clone https://github.com/ucb-bar/chipyard.git && \
    cd chipyard && \
    git checkout 1.12.3 && \
    ./build-setup.sh riscv-tools --skip-marshal  

RUN apt-get install -y zip

# Install Java and SBT
RUN \
    curl -s "https://get.sdkman.io" | bash && \
    source "/root/.sdkman/bin/sdkman-init.sh" && \
    sdk install java $(sdk list java | grep -o "\b8\.[0-9]*\.[0-9]*\-tem" | head -1) && \
    sdk install sbt

# Install rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install BSC
RUN \
    apt-get install -y ghc && \
    apt-get install -y libghc-regex-compat-dev libghc-syb-dev libghc-old-time-dev libghc-split-dev && \
    apt-get install -y ghc-prof libghc-regex-compat-prof libghc-syb-prof libghc-old-time-prof libghc-split-prof && \
    apt-get install -y tcl-dev build-essential pkg-config autoconf gperf flex bison iverilog dejagnu csh grep m4 make perl pkg-config time libsystemc-dev && \
    git clone --recursive https://github.com/B-Lang-org/bsc && \
    cd bsc && \
    make install-src && \
    BSC_VERSION=$(echo 'puts [lindex [Bluetcl::version] 0]' | inst/bin/bluetcl) && \
    mkdir -p /opt/tools/bsc && \
    cp -rf inst /opt/tools/bsc/bsc-${BSC_VERSION} && \
    cd /opt/tools/bsc && \
    ln -s bsc-${BSC_VERSION} latest

ENV PATH="/opt/tools/bsc/latest/bin:$PATH"

# # Install PDL
# RUN \
#     source "/root/.sdkman/bin/sdkman-init.sh" && \
#     cd /opt/tools && \
#     git clone https://github.com/apl-cornell/PDL.git && \
#     cd PDL && \
#     export MAKEFLAGS="-j $(nproc)" && \
#     export BLUESPECDIR="/root/bsc" && \
#     make
# ENV PATH="/opt/tools/PDL/bin:${PATH}"

# # Install Koika
# RUN \
#     apt-get install -y bubblewrap && \
#     printf '\n' | bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)" && \
#     opam init --auto-setup --yes && \
#     opam install --yes base=v0.13.1 coq=8.11.1 core=v0.13.0 dune=2.5.1 hashcons=1.3 parsexp=v0.13.0 stdio=v0.13.0 zarith=1.9.1
# RUN git clone https://github.com/mit-plv/koika.git /root/koika

# Install utils
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN pip3 install rich parse scipy seaborn matplotlib
RUN apt-get update && apt-get install -y cloc

CMD [ "/bin/bash", "-l" ]


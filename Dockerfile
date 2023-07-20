FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
 
RUN apt-get update && apt-get -y install gdb vim bash binutils libcap2 net-tools socat git 

# llvm-11
RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates gnupg2 && rm -rf /var/lib/apt/lists
RUN echo deb http://apt.llvm.org/focal/ llvm-toolchain-focal-11 main >> /etc/apt/sources.list
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - 

# Packages
##############
# by line:
#   build and afl
#   llvm-11 (for afl-clang-lto)
#   date challenge
#   libxml2 challenge
#   server/entrypoint
#   user tools
#   debugging tools
RUN apt-get update && apt-get install -y \
    git build-essential curl libssl-dev sudo libtool libtool-bin libglib2.0-dev bison flex automake python3 python3-dev python3-setuptools python-is-python3 libpixman-1-dev gcc-9-plugin-dev cgroup-tools \
    clang-11 clang-tools-11 libclang-cpp11 libclang-cpp11-dev liblld-11 liblld-11-dev liblldb-11 liblldb-11-dev libllvm11 libomp-11-dev libomp5-11 lld-11 lldb-11 python3-lldb-11 llvm-11 llvm-11-dev llvm-11-runtime llvm-11-tools \
    rsync autopoint bison gperf autoconf texinfo gettext \
    libtool pkg-config libz-dev python2.7-dev \
    awscli  ncat \
    emacs vim nano screen htop man manpages-posix-dev wget httpie bash-completion \
    gdb byobu \
    && rm -rf /var/lib/apt/lists
# Users & SSH
##############
RUN useradd --create-home --shell /bin/bash afl
# See the README - the password is set by the entry script

# passwordless sudo access for ASAN and installing extra tools:
RUN echo "afl ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# RUN usermod -aG sudo afl

# AFL
###########
RUN update-alternatives --install /usr/bin/clang clang $(which clang-11) 1 && \
    update-alternatives --install /usr/bin/clang++ clang++ $(which clang++-11) 1 && \
    update-alternatives --install /usr/bin/llvm-config llvm-config $(which llvm-config-11) 1 && \
    update-alternatives --install /usr/bin/llvm-symbolizer llvm-symbolizer $(which llvm-symbolizer-11) 1 && \
    update-alternatives --install /usr/bin/llvm-cov llvm-cov $(which llvm-cov-11) 1

# (environment variables won't be visible in the SSH session unless added to /etc/profile or similar)
USER afl
WORKDIR /home/afl
RUN git clone https://github.com/google/AFL
WORKDIR /home/afl/AFL
RUN make
RUN sudo make install
WORKDIR /home/afl
RUN wget https://raw.githubusercontent.com/ash1n2/fuzzing_101/main/unegg.tar.bz
RUN tar xjvf unegg.tar.bz
WORKDIR /home/afl/unegg/
RUN sed -i '291d' UnEgg.cpp
WORKDIR /home/afl/unegg/release-x64/
RUN grep "g++" * -rl | xargs sed -i 's/g++/afl-g++/g'
RUN grep "gcc" * -rl | xargs sed -i 's/gcc/afl-gcc/g'
RUN make clean
RUN make

# docker run --privileged --security-opt seccomp=unconfined -it -v $PWD/work:/work afl26
# docker build -t afl26 .
##############
#WORKDIR /work
CMD ["bash"]

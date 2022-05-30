# Install and prepare RISC-V environment

# Add new repositories

apt install software-properties-common --assume-yes
add-apt-repository ppa:ubuntu-toolchain-r/test --yes
add-apt-repository ppa:deadsnakes/ppa --yes

# Update & upgrade apt-get

apt-get update --assume-yes
apt-get upgrade --assume-yes

# Install dependences

apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev git device-tree-compiler pkg-config libexpat-dev zlib1g-dev libexpat1-dev --assume-yes
apt-get install python python3.11 --assume-yes

# Install and configure GCC11

apt install gcc-11 g++-11 --assume-yes

update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100 --slave /usr/bin/g++ g++ /usr/bin/g++-11 --slave /usr/bin/gcov gcov /usr/bin/gcov-11
update-alternatives --config gcc

# Create new binaries directories

mkdir /opt/riscv32i
chown $USER /opt/riscv32i
mkdir /opt/riscv32im
chown $USER /opt/riscv32im
mkdir /opt/riscv32ic
chown $USER /opt/riscv32ic
mkdir /opt/riscv32imc
chown $USER /opt/riscv32imc

# Clone toolchain git 

git clone https://github.com/riscv/riscv-gnu-toolchain riscv-gnu-toolchain-rv32i
cd riscv-gnu-toolchain-rv32i
git submodule update --init --recursive

# Install Cross-Compiler

mkdir build_i; cd build_i
../configure --prefix=/opt/riscv32i --with-arch=rv32i --with-abi=ilp32
make -j$(nproc)
cd ..

mkdir build_im; cd build_im
../configure --prefix=/opt/riscv32im --with-arch=rv32im --with-abi=ilp32
make -j$(nproc)
cd ..

mkdir build_ic; cd build_ic
../configure --prefix=/opt/riscv32ic --with-arch=rv32ic --with-abi=ilp32
make -j$(nproc)
cd ..

mkdir build_imc; cd build_imc
../configure --prefix=/opt/riscv32imc --with-arch=rv32imc --with-abi=ilp32
make -j$(nproc)
cd ..

# Remove temporal directories

cd ..
rm -rf riscv-gnu-toolchain-rv32i

# Add toolchain binaries at Global PATH permanently

export PATH=$PATH:/opt/riscv32i/bin/:/opt/riscv32ic/bin/:/opt/riscv32im/bin/:/opt/riscv32imc/bin/
echo 'export PATH=$PATH:/opt/riscv32i/bin/:/opt/riscv32ic/bin/:/opt/riscv32im/bin/:/opt/riscv32imc/bin/' >> ~/.profile
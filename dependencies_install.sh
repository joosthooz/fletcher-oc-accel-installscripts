#These dependencies have already been installed on the VM. If you need to install them again, run this script as root

WORKSPACE=/home/opencapi/workspace

yum -y install gcc gcc-c++ make java-1.8.0-openjdk libXrender-devel libXtst-devel xorg-x11-server-Xorg xorg-x11-xauth xorg-x11-apps wget \
    && yum clean all
yum -y install ncurses-devel xterm which gdb python3-pip python3-devel patch
yum -y install centos-release-scl devtoolset-9
pip3 install -U pip wheel 
pip3 install numpy pyarrow pyfletchgen pyfletcher vhdeps vhdmmio notebook

# Install a recent CMake
mkdir ${WORKSPACE}/cmake && cd ${WORKSPACE}/cmake \
    && wget https://github.com/Kitware/CMake/releases/download/v3.20.5/cmake-3.20.5-linux-x86_64.tar.gz \
    && tar -xzf cmake-3.20.5-linux-x86_64.tar.gz \
    && cp -r cmake-3.20.5-linux-x86_64/* /usr/local/

# Install Apache Arrow binary release #unfortunately we need to build Arrow from source using devtoolset-9 to fix errors on centos 7
#RUN yum install -y epel-release || sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(cut -d: -f5 /etc/system-release-cpe | cut -d. -f1).noarch.rpm \
#    && yum install -y https://apache.jfrog.io/artifactory/arrow/centos/$(cut -d: -f5 /etc/system-release-cpe | cut -d. -f1)/apache-arrow-release-latest.rpm \
#    && yum install -y --enablerepo=epel arrow-devel


# Install Apache Arrow from source
mkdir -p ${WORKSPACE}/arrow && cd ${WORKSPACE}/arrow && \
git clone https://github.com/apache/arrow.git && \
cd arrow && \
git checkout apache-arrow-5.0.0 && \
cd ${WORKSPACE}/arrow && mkdir build && cd build && \
scl enable devtoolset-9 'bash -c "CFLAGS=-D_GLIBCXX_USE_CXX11_ABI=0 CXXFLAGS=-D_GLIBCXX_USE_CXX11_ABI=0 LDFLAGS=-D_GLIBCXX_USE_CXX11_ABI=0  cmake -DARROW_PYTHON=ON -DARROW_DATASET=ON -DARROW_PARQUET=ON -DARROW_WITH_SNAPPY=ON ../arrow/cpp"' && \
scl enable devtoolset-9 'bash -c "make -j4 && make install"'
echo "/usr/local/lib64" >> /etc/ld.so.conf
ldconfig

# Perform debug build of Apache Arrow
#RUN cd ${WORKSPACE}/arrow && mkdir build_dbg && cd build_dbg && \
#scl enable devtoolset-9 'bash -c "CFLAGS=-D_GLIBCXX_USE_CXX11_ABI=0 CXXFLAGS=-D_GLIBCXX_USE_CXX11_ABI=0 LDFLAGS=-D_GLIBCXX_USE_CXX11_ABI=0 cmake -DARROW_PYTHON=ON -DARROW_DATASET=ON -DARROW_PARQUET=ON -DARROW_WITH_SNAPPY=ON -DCMAKE_BUILD_TYPE=Debug ../arrow/cpp"' && \
#scl enable devtoolset-9 'bash -c "make -j4"'


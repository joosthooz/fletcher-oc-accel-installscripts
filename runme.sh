
# Find out where the script is located
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

WORKSPACE=/home/opencapi/workspace
mkdir -p ${WORKSPACE}

VERSION=2019.1
VIVADO_INSTALLERNAME=Xilinx_Vivado_SDK_Web_2019.1_0524_1430_Lin64.bin
VIVADO_INSTALLFILE=/home/opencapi/Downloads/${VIVADO_INSTALLERNAME}

if [ -d /opt/Xilinx/Vivado/${VERSION} ]; then
  echo "Vivado seems to be installed already, skipping..."
else
  echo "Go to https://www.xilinx.com/member/forms/download/xef-vivado.html?filename=Xilinx_Vivado_SDK_Web_2019.1_0524_1430_Lin64.bin"
  echo "Create an account or sign in if you have one already."
  echo "Before you can download the file, you need to fill in the requested information for US export regulation."
  echo "(This is the reason we did not automate this for you.)"
  echo "If you want, you can use the address of your university and select \"student\" as your profession."
  echo "Save the file to the default Downloads directory and make sure it keeps its original name (${VIVADO_INSTALLFILE})"

  firefox https://www.xilinx.com/member/forms/download/xef-vivado.html?filename=${VIVADO_INSTALLERNAME} 2>/dev/null &
  echo "press enter to continue..."
  read
  if [ ! -f ${VIVADO_INSTALLFILE} ]; then
    echo "Could not find the vivado installation file in the expected location (${VIVADO_INSTALLFILE}). Please try again."
    exit -1
  fi
  echo "Running Vivado installer in Batch mode..."
  chmod +x ${VIVADO_INSTALLFILE}
  sudo bash ${scriptdir}/vivado_install.sh ${VIVADO_INSTALLFILE} ${scriptdir}/files/vivado_install_config.txt
  if [ $? != 0 ]; then
    echo "Something went wrong during Vivado installation, exiting"
    exit -1
  fi

  echo "source /opt/Xilinx/Vivado/${VERSION}/settings64.sh" >> ~/.bashrc
  # .bashrc is not sourced when starting an application by double-clicking it. We need a wrapper script and a modified desktop entry for that:
  if command -v jupyter-notebook; then
    cp ${scriptdir}/files/jupyter-notebook-with-env ~/.local/bin && chmod +x ~/.local/bin/jupyter-notebook-with-env
    cp ${scriptdir}/files/jupyter-notebook.desktop ~/.local/share/applications/
  fi
  echo "Vivado Installation finished. Continuing installing oc-accel and Fletcher..."
fi

# Install Fletcher and fletchgen from binary release (RPM)
#RUN cd ${WORKSPACE}/ \
#    && wget https://github.com/abs-tudelft/fletcher/releases/download/0.0.20/fletcher-0.0.20-1.el7.x86_64.rpm \
#    && rpm -i fletcher-0.0.19-1.el7.x86_64.rpm \
#    && rm fletcher-0.0.19-1.el7.x86_64.rpm

# Install Fletcher and fletchgen from binary release (wheels)
#RUN cd ${WORKSPACE} \
#    && wget https://github.com/abs-tudelft/fletcher/releases/download/0.0.20/pyfletchgen-0.0.20-cp36-cp36m-manylinux2014_x86_64.whl \
#    && pip install pyfletchgen-0.0.20-cp36-cp36m-manylinux2014_x86_64.whl --prefix /usr/local

#unfortunately we need to use a modified vhdmmio to fix errors on centos 7. We need centos 7 (and not 8) because it is officially supported by Vivado 2019.1.
# Install vhdmmio from source
if [ -d ${WORKSPACE}/vhdmmio ]; then
  echo "Custom vhdmmio seems to be installed already, skipping..."
else
  mkdir -p ${WORKSPACE}/vhdmmio && cd ${WORKSPACE}/vhdmmio \
  && git clone https://github.com/joosthooz/vhdmmio \
  && cd vhdmmio && git checkout force_utf8 \
  && pip install -e ./
  if [ $? != 0 ]; then
    echo "Something went wrong during vhdmmio installation, exiting"
  exit -1
  fi
fi

# Install Fletcher and fletchgen from source
if command -v fletchgen; then
  echo "Fletcher seems to be installed already, skipping..."
else
  cd ${WORKSPACE} && git clone https://github.com/abs-tudelft/fletcher
  cd fletcher && git pull && git submodule init && git submodule update \
  && mkdir -p ${WORKSPACE}/fletcher/build \
  && cd ${WORKSPACE}/fletcher/build \
  && scl enable devtoolset-9 'bash -c "cmake -DFLETCHER_BUILD_FLETCHGEN=On .."' \
  && scl enable devtoolset-9 'bash -c "make -j4"' \
  && sudo scl enable devtoolset-9 'bash -c "make install"'
  if [ $? != 0 ]; then
    echo "Something went wrong during Fletcher installation, exiting"
  exit -1
  fi
fi

# Install oc-accel and ocse
if [ -d ${WORKSPACE}/OpenCAPI/oc-accel ] && [ -d ${WORKSPACE}/OpenCAPI/ocse ]; then
  echo "oc-accel and ocse seem to be installed already, skipping..."
else
  mkdir -p ${WORKSPACE}/OpenCAPI/ && cd ${WORKSPACE}/OpenCAPI \
  && git clone https://github.com/OpenCAPI/ocse \
  && source /opt/Xilinx/Vivado/${VERSION}/settings64.sh \
  && pushd ocse && make && popd \
  && git clone https://github.com/OpenCAPI/oc-accel \
  && pushd oc-accel && git submodule init && git submodule update \
  && cp ${scriptdir}/files/customaction.defconfig ${WORKSPACE}/OpenCAPI/oc-accel/defconfig \
  && cp ${scriptdir}/files/sum_snap_env.sh ${WORKSPACE}/OpenCAPI/oc-accel/snap_env.sh \
  && make software && popd
  if [ $? != 0 ]; then
    echo "Something went wrong during oc-accel and ocse installation, exiting"
  exit -1
  fi
fi

# Install fletcher for the oc-accel platform
#if [ -d ${WORKSPACE}/OpenCAPI/fletcher-oc-accel ]; then
if ldconfig -p | grep fletcher_oc-accel; then
  echo "Fletcher-oc-accel seems to be installed already, skipping..."
else
  cd ${WORKSPACE}/OpenCAPI
  git clone https://github.com/abs-tudelft/fletcher-oc-accel
  pushd fletcher-oc-accel && git checkout realign && git pull && git submodule init && git submodule update && popd \
  && pushd fletcher-oc-accel/fletcher && git submodule init && git submodule update && popd \
  && mkdir -p ${WORKSPACE}/OpenCAPI/fletcher-oc-accel/runtime/build \
  && cd       ${WORKSPACE}/OpenCAPI/fletcher-oc-accel/runtime/build \
  && scl enable devtoolset-9 "SNAP_ROOT=${WORKSPACE}/OpenCAPI/oc-accel bash -c \"cmake ..\"" \
  && scl enable devtoolset-9 'bash -c "make -j4"' \
  && sudo scl enable devtoolset-9 'bash -c "make install"' \
  && sudo ldconfig
  if [ $? != 0 ]; then
    echo "Something went wrong during Fletcher-oc-accel installation, exiting"
  exit -1
  fi
fi

# Update action_root according to the location of our workspace, because ocaccel_workflow.py cannot handle the relative path (although it does for ocse)
sed -i "s|export ACTION_ROOT=.*|export ACTION_ROOT=${WORKSPACE}/OpenCAPI/fletcher-oc-accel/examples/sum|" ${WORKSPACE}/OpenCAPI/oc-accel/snap_env.sh

echo "Installation completed. To run a Fletcher OpenCAPI example application, press enter. Otherwise, exit with ctrl-c."
read

cd ${WORKSPACE}/OpenCAPI/oc-accel \
&& source /opt/Xilinx/Vivado/${VERSION}/settings64.sh \
&& make -s customaction.defconfig \
&& make model \
&& ./ocaccel_workflow.py --no_configure --no_make_model -t "${WORKSPACE}/OpenCAPI/fletcher-oc-accel/examples/sum/sw/run_ocxl_cosim_notebook.sh"




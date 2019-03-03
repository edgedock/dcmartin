#FROM aarch64/ubuntu
FROM arm64v8/ubuntu:xenial-20180123 as cuda-base

# Update packages, install some useful packages
RUN apt update && apt install -y \
	apt-utils \
	bzip2 \
	curl \
	sudo \
	unp \
  && apt-get clean && rm -rf /var/cache/apt

ARG ROOTFS=https://developer.nvidia.com/embedded/dlc/l4t-sample-root-filesystem-31-1-0
ARG DRIVER=https://developer.nvidia.com/embedded/dlc/l4t-jetson-xavier-driver-package-31-1-0

# Install drivers first
WORKDIR /tmp
RUN curl -sSL ${DRIVER} | tar xpfj - 
RUN cd ./Linux_for_Tegra/rootfs && curl -sSL ${ROOTFS} | tar xpfj - 
RUN ./Linux_for_Tegra/apply_binaries.sh -r ./Linux_for_Tegra/rootfs
RUN rm -fr \
	./Linux_for_Tegra/rootfs/var/cache/ \
	./Linux_for_Tegra/rootfs/usr/lib/libreoffice/ \
	./Linux_for_Tegra/rootfs/usr/lib/chromium-browser/ \
	./Linux_for_Tegra/rootfs/usr/lib/thunderbird/
RUN cd ./Linux_for_Tegra/rootfs && for d in bin boot dev home lib media mnt opt root run sbin srv tmp usr var; do tar cf - "${d}" | ( cd "/${d}" ; tar xpf - ); done
RUN rm -fr ./Linux_for_Tegra

WORKDIR /
ARG JETPACK_URL=https://developer.download.nvidia.com/devzone/devcenter/mobile/jetpack_l4t/3.3/lw.xd42/JetPackL4T_33_b39

# libcudnn
ARG LIB=libcudnn7_7.1.5.14-1+cuda9.0_arm64.deb
ARG URL=${JETPACK_URL}/${LIB}
RUN curl -sSL ${URL} -o ${LIB}
RUN dpkg --install ${LIB}

# libcudnn-dev
ARG LIB=libcudnn7-dev_7.1.5.14-1+cuda9.0_arm64.deb
ARG URL=${JETPACK_URL}/${LIB}
RUN curl -sSL ${URL} -o ${LIB}
RUN dpkg --install ${LIB}

# cuda-repo
ARG LIB=cuda-repo-l4t-9-0-local_9.0.252-1_arm64.deb
ARG URL=${JETPACK_URL}/${LIB}
RUN curl -sSL ${URL} -o ${LIB}
RUN dpkg --install ${LIB}

RUN apt-key add /var/cuda-repo-9-0-local/7fa2af80.pub
RUN apt-get update && apt-get install -y --allow-unauthenticated cuda-toolkit-9.0

RUN ln -sf /usr/lib/aarch64-linux-gnu/tegra/libGL.so /usr/lib/aarch64-linux-gnu/libGL.so
RUN ln -s /usr/lib/aarch64-linux-gnu/libcuda.so /usr/lib/aarch64-linux-gnu/libcuda.so.1

## Clean up (don't remove cuda libs... used by child containers)
RUN apt-get -y autoremove && apt-get -y autoclean
RUN rm -rf /var/cache/apt

###
### OPENCV
###

FROM cuda-base as opencv-base

RUN apt-get install -y \
	pkg-config \
	libavcodec-ffmpeg56 \
	libavformat-ffmpeg56 \
	libswscale-ffmpeg3 \
	libtbb2 \
	libcairo2 \
	libgdk-pixbuf2.0-0 \
	libglib2.0-0 \
	libgtk2.0-0 \
	libjasper1 \
	libjpeg8 \
	libtbb-dev

WORKDIR /
ARG JETPACK_URL=https://developer.download.nvidia.com/devzone/devcenter/mobile/jetpack_l4t/3.3/lw.xd42/JetPackL4T_33_b39

ARG LIB=libopencv_3.3.1_t186_arm64.deb
ARG URL=${JETPACK_URL}/${LIB}
RUN curl -sSL ${URL} -o ${LIB}
RUN dpkg --install ${LIB}

ARG LIB=libopencv-dev_3.3.1_t186_arm64.deb
ARG URL=${JETPACK_URL}/${LIB}
RUN curl -sSL ${URL} -o ${LIB}
RUN dpkg --install ${LIB}

ARG LIB=libopencv-python_3.3.1_t186_arm64.deb
ARG URL=${JETPACK_URL}/${LIB}
RUN curl -sSL ${URL} -o ${LIB}
RUN dpkg --install ${LIB}

## Clean up (don't remove cuda libs... used by child containers)
RUN apt-get -y autoremove && apt-get -y autoclean
RUN rm -rf /var/cache/apt

###
### DARKNET
###

FROM opencv-base as darknet-opencv-base

RUN apt install -y git

# configure darknet
ARG DARKNET=/darknet
ARG DARKNET_GIT="http://github.com/pjreddie/darknet"
ENV DARKNET=${DARKNET} DARKNET_GIT=${DARKNET_GIT}
ENV DARKNET_TINY_WEIGHTS="${DARKNET}/yolov2-tiny-voc.weights"
ENV DARKNET_TINY_WEIGHTS_URL="http://pjreddie.com/media/files/yolov2-tiny-voc.weights"
ENV DARKNET_V2_WEIGHTS="${DARKNET}/yolov2.weights"
ENV DARKNET_V2_WEIGHTS_URL="https://pjreddie.com/media/files/yolov2.weights"
ENV DARKNET_V3_WEIGHTS="${DARKNET}/yolov3.weights"
ENV DARKNET_V3_WEIGHTS_URL="https://pjreddie.com/media/files/yolov3.weights"

# Clone darknet
RUN mkdir -p ${DARKNET} 
RUN cd ${DARKNET} && git clone ${DARKNET_GIT} .

# Build darknet
RUN \
    cd ${DARKNET} \
    \
    && PATH=/usr/local/cuda/bin:$PATH \
    \
    && mkdir -p /usr/local/cuda \
    \
    && ln -s /usr/lib/aarch64-linux-gnu/tegra /usr/local/cuda/lib64 \
    \
    && make -j 4 GPU=1 CUDNN=1 OPENCV=0 OPENMP=0 DEBUG=0 LD_LIBRARY_PATH=$LD_LIBRARY_PATH:


FROM cuda-base as caffe-base

RUN apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
	build-essential \
	cmake \
	git \
	gfortran \
	libatlas-base-dev \
	libboost-all-dev \
	libgflags-dev \
	libfreetype6-dev \
	libpng12-dev \
	libgoogle-glog-dev \
	libhdf5-serial-dev \
	libleveldb-dev \
	liblmdb-dev \
	libprotobuf-dev \
	libsnappy-dev \
	protobuf-compiler \
	python-all-dev \
	python-dev \
	python-pip

# Pip for python stuff
RUN pip install --upgrade --no-cache-dir pip setuptools wheel
RUN pip install --no-cache-dir numpy
RUN pip install --no-cache-dir pillow matplotlib h5py protobuf scipy scikit-image scikit-learn

WORKDIR /
RUN git clone https://github.com/BVLC/caffe
WORKDIR /caffe
RUN apt-get install -y python-setuptools
WORKDIR /caffe/python
RUN for req in $(cat requirements.txt); do pip install --no-cache-dir $req; done
WORKDIR /caffe
RUN cp Makefile.config.example Makefile.config

# Prep make with correct Python include dirs
RUN sed -i "s/INCLUDE_DIRS := \$(PYTHON_INCLUDE) \/usr\/local\/include/INCLUDE_DIRS := \$(PYTHON_INCLUDE) \/usr\/local\/include \/usr\/local\/lib\/python2.7\/dist-packages\/numpy\/core\/include \/usr\/include\/hdf5\/serial/g" Makefile.config
RUN sed -i "s/# USE_CUDNN := 1/USE_CUDNN := 1/g" Makefile.config

# CUDA9.0 update: Comment out "compute_20" lines in makefile.config (this arch obsolete)
RUN sed -i "s/-gencode arch=compute_20,code=sm_20/#-gencode arch=compute_20,code=sm_20/g" Makefile.config
RUN sed -i "s/LIBRARIES += glog gflags protobuf boost_system boost_filesystem m hdf5_hl hdf5/LIBRARIES += glog gflags protobuf boost_system boost_filesystem m hdf5_serial_hl hdf5_serial opencv_core opencv_highgui opencv_imgproc opencv_imgcodecs/g" Makefile

# Build
RUN ldconfig
RUN make all -j4
RUN make pycaffe -j4
RUN make test -j4
RUN make distribute

# Clean up
RUN apt-get -y autoremove && apt-get -y autoclean

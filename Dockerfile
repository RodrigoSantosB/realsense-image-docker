# Use the Ubuntu 20.04 LTS base image
FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    sudo\
    libssl-dev \
    libusb-1.0-0-dev \
    libudev-dev \
    pkg-config \
    libgtk-3-dev \
    libglfw3-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Add a new user 'vision' and grant sudo privileges
RUN useradd -m -G sudo vision && \
    echo 'vision ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to the 'vision' user
USER vision

# Clone the librealsense repository
RUN mkdir /home/vision/librealsense && \
    git clone https://github.com/IntelRealSense/librealsense.git /home/vision/librealsense

# Set the working directory to the librealsense repository
WORKDIR /home/vision/librealsense

# Run the setup script for Intel Realsense permissions
RUN chmod +x ./scripts/setup_udev_rules.sh && \
    sudo ./scripts/setup_udev_rules.sh 

# Apply kernel patches for Ubuntu 20.04
RUN ./scripts/patch-realsense-ubuntu-lts-hwe.sh

# Install required Linux headers
USER root
RUN apt-get update && \
    apt-get install -y \
    linux-headers-$(uname -r) \
    && rm -rf /var/lib/apt/lists/*

# Add hid_sensor_custom to /etc/modules
RUN echo 'hid_sensor_custom' | tee -a /etc/modules

# Install gcc-5 and g++-5
RUN apt-get update && \
    apt-get install -y \
    software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test && \
    apt-get update && \
    apt-get install -y \
    gcc-5 \
    g++-5 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 60 --slave /usr/bin/g++ g++ /usr/bin/g++-5 && \
    update-alternatives --set gcc "/usr/bin/gcc-5" && \
    rm -rf /var/lib/apt/lists/*

# Create build directory and set as working directory
USER vision
WORKDIR /home/vision/librealsense/build

# Run CMake with specified options
RUN cmake ../ -DCMAKE_BUILD_TYPE=Release -DBUILD_EXAMPLES=true -DBUILD_GRAPHICAL_EXAMPLES=false

# Build librealsense2
RUN make -j$(nproc)

# Entrypoint command
CMD ["/bin/bash"]

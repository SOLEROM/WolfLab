Sure! Here's a step-by-step guide to create a demo that includes setting up a QEMU environment with a simple rootfs containing an old libc, a containerized build environment with crosstool-ng, and a process to compile and run a "Hello, World!" program on the QEMU target.

### Stage 1: Setting Up QEMU with a Simple RootFS

1. **Install QEMU**:
   ```bash
   sudo apt-get install qemu qemu-system qemu-user-static
   ```

2. **Create a Simple RootFS with an Old libc**:
   - You can use `buildroot` to create a minimal root filesystem with an old version of glibc.
   - Download and extract buildroot:
     ```bash
     wget https://buildroot.org/downloads/buildroot-2021.02.3.tar.gz
     tar -xvf buildroot-2021.02.3.tar.gz
     cd buildroot-2021.02.3
     ```

   - Configure buildroot for a simple ARM rootfs with an old glibc:
     ```bash
     make menuconfig
     ```
     In the configuration menu:
     - Set `Target architecture` to `ARM`.
     - Set `Target architecture variant` to `arm926t` (or another suitable variant).
     - In `Toolchain`, set `C library` to `glibc` and select an older version.

   - Build the rootfs:
     ```bash
     make
     ```

   - The output will be in `output/images`. Copy the root filesystem image:
     ```bash
     cp output/images/rootfs.ext2 /path/to/qemu-rootfs.ext2
     ```

3. **Run QEMU with the RootFS**:
   ```bash
   qemu-system-arm -M versatilepb -kernel output/images/zImage -drive file=/path/to/qemu-rootfs.ext2,format=raw -append "root=/dev/sda" -nographic
   ```
   This command boots the QEMU emulator with the specified kernel and rootfs.

### Stage 2: Setting Up the Build Environment with crosstool-ng in a Container

1. **Install Docker** (if not already installed):
   ```bash
   sudo apt-get install docker.io
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo usermod -aG docker $USER
   ```

2. **Create a Dockerfile for the Build Environment**:
   ```Dockerfile
   # Use a base image with necessary build tools
   FROM ubuntu:20.04

   # Install dependencies
   RUN apt-get update && apt-get install -y \
       build-essential \
       crosstool-ng \
       wget \
       git \
       vim \
       && apt-get clean

   # Add a non-root user
   RUN useradd -ms /bin/bash builduser
   USER builduser
   WORKDIR /home/builduser

   # Set up crosstool-ng environment
   RUN ct-ng arm-unknown-linux-gnueabi && \
       ct-ng menuconfig && \
       ct-ng build
   ```

3. **Build and Run the Docker Container**:
   ```bash
   docker build -t cross-build-env .
   docker run -it --name cross-build-env cross-build-env
   ```

### Stage 3: Compile and Transfer the "Hello, World!" Program

1. **Write the "Hello, World!" Program**:
   Create a file named `hello.c` with the following content:
   ```c
   #include <stdio.h>

   int main() {
       printf("Hello, World!\n");
       return 0;
   }
   ```

2. **Compile the Program Using the Cross-Compiler in the Container**:
   ```bash
   docker exec -it cross-build-env bash
   export PATH=/home/builduser/x-tools/arm-unknown-linux-gnueabi/bin:$PATH
   arm-unknown-linux-gnueabi-gcc -o hello hello.c
   ```

3. **Transfer the Compiled Program to the QEMU Environment**:
   - Exit the container and copy the compiled binary:
     ```bash
     docker cp cross-build-env:/home/builduser/hello .
     ```

   - Use a shared folder or network method to transfer `hello` to the QEMU rootfs. Alternatively, mount the rootfs image and copy the file directly:
     ```bash
     sudo mount -o loop /path/to/qemu-rootfs.ext2 /mnt
     sudo cp hello /mnt/
     sudo umount /mnt
     ```

### Stage 4: Run the "Hello, World!" Program on QEMU

1. **Boot QEMU with the Updated RootFS**:
   ```bash
   qemu-system-arm -M versatilepb -kernel output/images/zImage -drive file=/path/to/qemu-rootfs.ext2,format=raw -append "root=/dev/sda" -nographic
   ```

2. **Run the Program on the Target**:
   - Inside the QEMU shell:
     ```bash
     chmod +x /hello
     /hello
     ```

   You should see the output:
   ```
   Hello, World!
   ```

This setup demonstrates how to build an ELF binary using a cross-compiler configured with crosstool-ng, transfer it to a QEMU environment, and run it on a minimal rootfs with an old libc version.

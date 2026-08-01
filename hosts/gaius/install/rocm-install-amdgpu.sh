# https://rocmdocs.amd.com/en/latest/Installation_Guide/Installation-Guide.html

sudo apt-get install -y libnuma-dev  # amdgpu dependency

wget -q -O - https://repo.radeon.com/rocm/rocm.gpg.key | sudo apt-key add -
echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/debian/ xenial main' | sudo tee /etc/apt/sources.list.d/rocm.list

sudo apt install rocm-dkms

sudo usermod -a -G video $LOGNAME
sudo usermod -a -G render $LOGNAME

echo 'export PATH=$PATH:/opt/rocm/bin:/opt/rocm/rocprofiler/bin:/opt/rocm/opencl/bin' | sudo tee -a /etc/profile.d/rocm.sh

sudo reboot

# after reboot, run these and check if the GPU is listed in both of them:
rocminfo
clinfo

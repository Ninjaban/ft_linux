apt-get update
apt-get install bash binutils bison bzip2 coreutils diffutils findutils gawk gcc g++ grep gzip m4 make perl sed tar texinfo xz-utils

fdisk /dev/sda

mkfs -v -t ext4 /dev/sda3
export LFS=/mnt/lfs
mkdir -pv $LFS
mount -v -t ext4 /dev/sda3 $LFS

mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources

mkdir -v $LFS/tools
ln -sv $LFS/tools /

groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
passwd lfs
chown -v lfs $LFS/tools
chown -v lfs $LFS/sources

su - lfs

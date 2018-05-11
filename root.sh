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
chown -v lfs $LFS/tools
chown -v lfs $LFS/sources
passwd lfs
lfs

su - lfs

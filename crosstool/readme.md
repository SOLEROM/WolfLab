
## list
lxc storage list
sudo lxc list
lxc network list

## add pool
lxc storage create default dir
lxc profile device add default root disk path=/ pool=default

## add nework
sudo lxc network create lxdbr0
sudo lxc profile device add default eth0 nic name=eth0 network=lxdbr0

## build
sudo lxc launch ubuntu:20.04 test0

lxc launch ubuntu:20.04 test0 --config=user.user-data="$(cat cloud-init.yaml)"

## run
sudo lxc exec test0 -- /bin/bash

## clean
sudo lxc stop test0
sudo lxc delete test0

## share mount folder
sudo lxc config device remove test0 my-data
sudo lxc config device add test0 my-data2 disk source=/data/embd/wolfLabGIT/crosstool/local/ path=/mnt shift=true


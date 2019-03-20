export DEV=192.168.1.47
ssh-copy-id ${DEV} -l pi
ssh ${DEV} -l pi
sudo -s
apt-get update
apt-get upgrade -qq -y
wget -qO - get.docker.com | sudo bash
export REPO=updates
export APT=/etc/apt/sources.list.d/bluehorizon.list
export URL=http://pkg.bluehorizon.network
export KEY=${URL}/bluehorizon.network-public.key
wget -qO - "${KEY}" | apt-key add -
echo "deb [arch=armhf,arm64,amd64] ${URL}/linux/ubuntu xenial-${REPO} main" > "${APT}"
apt-get update -qq
apt-get install -qq -y bluehorizon horizon horizon-cli
passwd pi
export NAME=test-sdr-4 USERID=dcmartin
sed -i "s|raspberrypi|${NAME}|" /etc/hosts
sed -i "s|raspberrypi|${NAME}|" /etc/hostname
hostname ${NAME}
adduser ${USERID} 
addgroup ${USERID} sudo
addgroup ${USERID} docker
echo "${USERID} ALL=(ALL) NOPASSWD: ALL" >  /etc/sudoers.d/010_${USERID}-nopasswd
chmod 400  /etc/sudoers.d/010_${USERID}-nopasswd

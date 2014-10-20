echo '-----------------------'
cat /etc/apt/sources.list
echo 'deb ftp://carroll.aset.psu.edu/pub/linux/distributions/debian/ wheezy main contrib non-free' >>  /etc/apt/sources.list
apt-get update -qq
apt-get -y install python-software-properties
#add-apt-repository ppa:webupd8team/java
#apt-get update -qq
curl -sL https://deb.nodesource.com/setup | sudo bash -
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

apt-get -y -q install pkg-config git subversion make gcc g++ python binutils-gold
apt-get -y -q install libexpat1-dev libgtk2.0-dev libnss3-dev libssl-dev
apt-get -y -q install oracle-java7-installer

mkdir /var/libjingle; cd /var/libjingle
git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git

export JAVA_HOME=/usr/lib/jvm/jdk-7-oracle-armhf/
export PATH="$(pwd)/depot_tools:$PATH"
export GYP_GENERATORS="make"
export GYP_DEFINES="$GYP_DEFINES target_arch=arm arm_version=7"
export C_INCLUDE_PATH=/usr/include:/usr/include/arm-linux-gnueabihf
export CPLUS_INCLUDE_PATH=/usr/include:/usr/include/arm-linux-gnueabihf

gclient config --name=trunk http://webrtc.googlecode.com/svn/branches/3.52
gclient sync --force

cd trunk/talk; mkdir ipop-project; cd ipop-project
git clone --depth 1 https://github.com/ipop-project/ipop-tap.git
git clone --depth 1 https://github.com/ipop-project/ipop-tincan.git

cd ../../

rm -f DEPS all.gyp talk/libjingle.gyp talk/ipop-tincan.gyp
cp talk/ipop-project/ipop-tincan/build/ipop-tincan.gyp talk/
cp talk/ipop-project/ipop-tincan/build/libjingle.gyp talk/
cp talk/ipop-project/ipop-tincan/build/all.gyp .
cp talk/ipop-project/ipop-tincan/build/DEPS .

gclient sync --force

sed -i "s/'arm_float_abi%': 'soft',/'arm_float_abi%': 'hard',/g" build/common.gypi
sed -i "s/'arm_fpu%': '',/'arm_fpu%': 'vfp',/g" build/common.gypi

mv third_party/gold/gold32 third_party/gold/gold32.bak
ln -s /usr/bin/gold third_party/gold/gold32

gclient runhooks --force

make ipop-tincan BUILDTYPE=Release

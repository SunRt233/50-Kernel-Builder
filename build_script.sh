#!/bin/bash
# export SCRIPT=$(realpath ${BASH_SOURCE[0]})
# 获取当前路径
CURRENT_DIR=$(pwd)
export PATH="$CURRENT_DIR/akb/src:$PATH"
export REPO_DIR="$CURRENT_DIR"
KERNEL_SOURCE_DIR="$CURRENT_DIR/kernel_source"

prepare_akb() {
	if [ -d "$CURRENT_DIR/akb" ]; then
		echo "akb exists"
		return 0
	fi
	git clone https://git.yunzhu.host/SunRt233/AKB.git --depth=1 "$CURRENT_DIR/akb" || { echo "Failed to clone AKB repository"; return 1; }
}

prepare_kernel_source() {
	if [ -d "$KERNEL_SOURCE_DIR" ]; then
		echo "kernel source exists"
		return 0
	fi
	git clone --recursive --depth=1  https://github.com/ztc1997/android_gki_kernel_5.10_common.git "$KERNEL_SOURCE_DIR" || { echo "Failed to clone kernel source repository"; return 1; }
}

prepare() {
	prepare_akb || { echo "prepare_akb failed"; exit 1; }
	prepare_kernel_source || { echo "prepare_kernel_source failed"; exit 1; }
}

build() {
	START_SEC=$(date +%s)
	# 参数设定
	CC="clang"

	THREAD=$(nproc --all)
	ARCH=arm64
	OUT_DIR="$CURRENT_DIR/out/${TARGET_KERNEL}"

	# 使用 neutron-clang 无需使用 Triple
	CROSS_COMPILE=aarch64-linux-android-
	CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
	CC_ADDITION_FLAGS="AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip LLVM_IAS=1 LLVM=1"
	# export CLANG_TRIPLE=

	# 编译参数
	args="-j$THREAD \
		O=$OUT_DIR \
		ARCH=$ARCH \
		CROSS_COMPILE=$CROSS_COMPILE \
		CROSS_COMPILE_COMPAT=$CROSS_COMPILE_COMPAT \
		CLANG_TRIPLE=aarch64-linux-android- \
		$CC_ADDITION_FLAGS \
		CC=$CC"
	cd "$KERNEL_SOURCE_DIR"
	make ${args} gki_defconfig
	make ${args}

	END_SEC=$(date +%s)
	COST_SEC=$(($END_SEC - $START_SEC))
	echo "Kernel Build Costed $(($COST_SEC / 60))min $(($COST_SEC % 60))s"
}

main() {
	akb env run akb toolchains setup > /dev/null || { echo "akb toolchains setup failed"; exit $?;  }
	echo "注入PATH"
	echo "$(akb env expend_env)" | while read line; do
		echo "注入 $line"
		eval "export $line"
	done
	echo "PATH=$PATH"
	echo "开始构建"
	build
}
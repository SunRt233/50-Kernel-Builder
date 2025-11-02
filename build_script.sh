#!/bin/bash
export SCRIPT=$(realpath ${BASH_SOURCE[0]})
# 获取当前路径
CURRENT_DIR=$(pwd)
export PATH="$CURRENT_DIR/akb/src:$PATH"
export REPO_DIR="$CURRENT_DIR"
KENREL_SOURCE_DIR="$CURRENT_DIR/kernel_source"

prepare_akb() {
	git clone https://git.yunzhu.host/SunRt233/AKB.git "$CURRENT_DIR/akb"
}
prepare_kernel_source() {
	git clone https://github.com/ztc1997/android_gki_kernel_5.10_common.git "$KENREL_SOURCE_DIR"
}
prepare() {
	prepare_akb
	prepare_kernel_source
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
	cd "$KENREL_SOURCE_DIR"
	make ${args} gki_defconfig
	make ${args}

	END_SEC=$(date +%s)
	COST_SEC=$(($END_SEC - $START_SEC))
	echo "Kernel Build Costed $(($COST_SEC / 60))min $(($COST_SEC % 60))s"
}

main() {
	if [ ! "$ENV_SET" ]; then
		env $(akb env expend_env | grep -v '^\s*#\|^\s*$' ) bash -c "akb toolchains setup"
		akb env expend_env > "$CURRENT_DIR/.env"
		export ENV_SET=true
		(. $SCRIPT;main)
	else
		. "$CURRENT_DIR/.env"
		build
	fi
}
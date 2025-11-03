#!/bin/bash
# 获取当前路径
CURRENT_DIR=$(pwd)
AKB_PATH="$CURRENT_DIR/AKB"

export PATH="$AKB_PATH/src:$PATH"		# 添加AKB路径
export REPO_DIR="$CURRENT_DIR"			# AKB依赖此变量

# 定义常量
KERNEL_SOURCE_DIR="$CURRENT_DIR/KernelSource"
AKB_REPO_URL="https://git.yunzhu.host/SunRt233/AKB.git"
KERNEL_REPO_URL="https://github.com/ztc1997/android_gki_kernel_5.10_common.git"
AK3_REPO_URL="https://github.com/osm0sis/AnyKernel3.git"
ARCH="arm64"
CROSS_COMPILE="aarch64-linux-android-"
CROSS_COMPILE_COMPAT="arm-linux-gnueabi-"
CC="clang"
CC_ADDITION_FLAGS="AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip LLVM_IAS=1 LLVM=1"
ARTIFACTS_DIR="$CURRENT_DIR/artifacts"
OUT_DIR="$CURRENT_DIR/out"

AK3_CONFIG=$(cat <<'EOF'
### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=<KERNEL_STRING>
do.devicecheck=0
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=boot;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
dump_boot; # use split_boot to skip ramdisk unpack, e.g. for devices with init_boot ramdisk

write_boot; # use flash_boot to skip ramdisk repack, e.g. for devices with init_boot ramdisk
## end boot install
EOF
)

EXPORT_CMDS=("check_system" "prepare" "build" "packup")

check_system() {
    echo "🔧 系统配置与性能检查"
    echo "----------------------"
    
    # CPU信息
    echo "🖥️  CPU信息:"
    lscpu | grep -E "Model name|CPU\(s\)" | sed 's/^/   /'
    echo ""
    
    # 内存信息
    echo "🧠 内存信息:"
    free -h | grep "Mem" | awk '{print "   已用: " $3 ", 可用: " $7}'
    echo ""
    
    # 存储空间
    echo "📁 存储空间:"
    df -h "$CURRENT_DIR" | tail -1 | awk '{print "   可用空间: " $4 " / 总空间: " $2}' 
    echo ""
    
    # 检查必要工具
    echo "🛠️  必要工具检查:"
    for tool in git clang make; do
        if command -v $tool &> /dev/null; then
            version=$($tool --version 2>/dev/null | head -1 | cut -d' ' -f1-3)
            echo "   ✅ $tool: ${version:-版本未知}"
        else
            echo "   ❌ $tool: 未安装"
        fi
    done
    echo ""
    
    echo "✅ 系统检查完成!"
    echo ""
}

_prepare_akb() {
	if [ -d "$AKB_PATH" ]; then
		echo "akb exists"
		return 0
	fi
	git clone "$AKB_REPO_URL" --depth=1 "$AKB_PATH" || { echo "Failed to clone AKB repository"; return 1; }
}

_prepare_kernel_source() {
	if [ -d "$KERNEL_SOURCE_DIR" ]; then
		echo "kernel source exists"
		return 0
	fi
	git clone --recursive --depth=1 "$KERNEL_REPO_URL" "$KERNEL_SOURCE_DIR" || { echo "Failed to clone kernel source repository"; return 1; }
}

_prepare_ak3() {
	if [ -d "$ARTIFACTS_DIR/AnyKernel3" ]; then
		echo "ak3 exists"
		return 0
	fi
	git clone "$AK3_REPO_URL" --depth=1 "$ARTIFACTS_DIR/AnyKernel3" || { echo "Failed to clone AnyKernel3 repository"; return 1; }

	# 替换anykernel.sh
	echo "$AK3_CONFIG" > "$ARTIFACTS_DIR/AnyKernel3/anykernel.sh"
}

prepare() {
    echo "⚙️  准备工作环境"
    echo "-----------------"
    
	_prepare_akb || { echo "_prepare_akb failed"; exit 1; }
	_prepare_kernel_source || { echo "_prepare_kernel_source failed"; exit 1; }
	_prepare_ak3 || { echo "_prepare_ak3 failed"; exit 1; }
    
    echo "✅ 环境准备完成!"
    echo ""
}

_build() {
	START_SEC=$(date +%s)
    
    echo "🔨 开始内核编译"
    echo "----------------"
    
	THREAD=$(nproc --all)

	# 编译参数
	args="-j$THREAD \
		O=$OUT_DIR \
		ARCH=$ARCH \
		CROSS_COMPILE=$CROSS_COMPILE \
		CROSS_COMPILE_COMPAT=$CROSS_COMPILE_COMPAT \
		CLANG_TRIPLE=${CROSS_COMPILE} \
		$CC_ADDITION_FLAGS \
		CC=$CC"
        
    echo "📋 编译配置:"
    echo "   架构: $ARCH"
    echo "   线程数: $THREAD"
    echo "   输出目录: $OUT_DIR"
    echo ""
    
	cd "$KERNEL_SOURCE_DIR"
	make "${args}" gki_defconfig
	make "${args}"

	END_SEC=$(date +%s)
	COST_SEC=$((END_SEC - START_SEC))
	echo "⏱️  编译耗时: $((COST_SEC / 60))分$((COST_SEC % 60))秒"
    
    echo ""
}

build() {
    echo "⚙️  配置构建环境"
    echo "-----------------"
    
	_IGNORE=$(akb env run akb toolchains setup) || { exit_code=$?;echo "akb toolchains setup failed"; exit $exit_code; }
	echo "注入 ENV"
	INJECTED_ENV=$(akb env expand_env | while read -r line; do
		echo "export $line"
	done)
	eval "$INJECTED_ENV"
	env
	echo "开始构建"
	_build
}

packup() { 
	echo "📦 打包工件"
	echo "-----------------"
	# 复制 $OUT_DIR 下第一层的文件到 $ARTIFACTS_DIR/kernel 排除 .o 结尾的文件
	find "$OUT_DIR" -maxdepth 1 -type f ! -name "*.o" -exec cp {} "$ARTIFACTS_DIR/kernel" \;

	# 复制 $OUT_DIR/arch/$ARCH/boot/Image.gz 到 $ARTIFACTS_DIR/AnyKernel3/Image.gz
	cp "$OUT_DIR/arch/$ARCH/boot/Image.gz" "$ARTIFACTS_DIR/AnyKernel3/Image.gz"

	# 获取KernelSource仓库作者信息 格式"用户名 <邮件>"
	KERNEL_AUTHOR_INFO="$(git -C "$KERNEL_SOURCE_DIR" config user.name) <$(git -C "$KERNEL_SOURCE_DIR" config user.email)>"
	# 获取KernelSource仓库提交hash
	KERNEL_HASH="$(git -C "$KERNEL_SOURCE_DIR" rev-parse --short HEAD)"
	# 获取AKB仓库commit hash
	AKB_HASH="$(git -C "$AKB_PATH" rev-parse --short HEAD)"

	KERNEL_STRING="$(echo "$KERNEL_HASH by $KERNEL_AUTHOR_INFO. Build with akb $AKB_HASH" | sed 's/ /-/g')"

	# 配置AK3 kernel.string
	sed -i "s/<KERNEL_STRING>/$KERNEL_STRING/g" "$ARTIFACTS_DIR/AnyKernel3/anykernel.sh"

}

main() {
	# 没有参数时执行默认行为，有参数时执行对应参数的函数
	if [ $# -eq 0 ]; then
        check_system
		prepare
		build
	else
		if [[ "${EXPORT_CMDS[*]}" =~ $1 ]]; then
			"$1"
		else
			echo "Invalid argument: $1"
		fi
	fi
}

main "$@" 2>&1 | tee full.log
# K50 内核构建器

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status//build.yaml)

这是一个用于自动构建 K50 内核的项目，基于 GitHub Actions 实现自动化构建流程。

## 🎯 特性

- 自动化构建 Android GKI 内核
- 集成 AnyKernel3 用于刷机
- 自动检查系统配置和性能
- 完整的日志记录和错误处理
- 自动生成构建工件

## 🚀 使用方法

### 自动构建

项目通过 GitHub Actions 自动构建：
1. 当本仓库有代码推送时自动触发构建
2. 每天自动检查上游内核仓库更新并构建
3. 可手动触发构建流程

### 本地构建

```bash
# 克隆项目
git clone <repository-url>
cd K50-Kernel-Builder

# 添加执行权限
chmod +x build_script.sh

# 执行完整构建流程
./build_script.sh

# 或者分别执行各个步骤
./build_script.sh check_system  # 检查系统配置
./build_script.sh prepare       # 准备构建环境
./build_script.sh build         # 执行构建
./build_script.sh packup        # 打包工件
```

## 📁 项目结构

```
K50-Kernel-Builder/
├── build_script.sh     # 构建脚本
├── .github/workflows/  # GitHub Actions 工作流
├── out/               # 构建输出目录
├── artifacts/         # 打包工件目录
└── README.md          # 本文档
```

## 🛠️ 构建流程

1. **系统检查** - 检查 CPU、内存、磁盘空间和必要工具
2. **环境准备** - 克隆 AKB、内核源码和 AnyKernel3
3. **内核构建** - 配置并编译内核
4. **工件打包** - 生成可刷入的内核包

## 📦 输出工件

构建完成后会生成两个工件：
- `output` - 包含编译好的内核文件
- `full-log` - 完整的构建日志

## ⚖️ 许可证合规性

### 内核源码许可证
本项目构建的内核基于 [ztc1997/android_gki_kernel_5.10_common](https://github.com/ztc1997/android_gki_kernel_5.10_common) 项目，该内核源码遵循 [GPL-2.0](https://www.gnu.org/licenses/gpl-2.0.html) 许可证。

### 分发要求
根据 GPL-2.0 许可证要求：
- 如果您分发编译后的内核二进制文件，必须同时提供对应的源码或获取源码的方式
- 不得移除原始内核源码中的版权声明
- 必须在分发时保留原始许可证文件

### 本项目许可证
本项目（构建脚本和相关工具）遵循 [GPL-3.0](LICENSE) 许可证。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目。

## 📄 许可证

[GPL-3.0 License](LICENSE)
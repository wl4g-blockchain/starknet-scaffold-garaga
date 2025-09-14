# 使用 Ubuntu 24.04 LTS 作为基础镜像
FROM ubuntu:24.04

# 设置环境变量以避免交互式安装提示
ENV DEBIAN_FRONTEND=noninteractive

# 设置阿里云镜像源
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

# 安装系统级依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    build-essential \
    libssl-dev \
    pkg-config \
    llvm-dev \
    libclang-dev \
    clang \
    && rm -rf /var/lib/apt/lists/*

# 设置 Node.js 阿里云镜像并安装 Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    sed -i 's|https://deb.nodesource.com|https://mirrors.aliyun.com/nodesource|g' /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    npm config set registry https://registry.npmmirror.com && \
    npm install -g bun

# 安装特定版本的 Noir (nargo 1.0.0)
RUN curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash && \
    export PATH="$HOME/.noirup/bin:$PATH" && \
    noirup --version v1.0.0

# 将 Nargo 二进制目录加入 PATH
ENV PATH="/root/.noirup/bin:${PATH}"

# 安装特定版本的 Barretenberg (bb v0.86.0-starknet.1)
RUN git clone --depth=1 --branch v0.86.0-starknet.1 https://github.com/AztecProtocol/barretenberg.git && \
    cd barretenberg && \
    git submodule update --init --recursive && \
    ./bootstrap.sh && \
    cd cpp && \
    mkdir -p build && cd build && \
    cmake .. && \
    make -j$(nproc) bb && \
    cp bin/bb /usr/local/bin/ && \
    cd / && \
    rm -rf /barretenberg

# 安装 Garaga 0.18.1
# 根据 Garaga 的实际发布页面调整下载链接
RUN curl -L -o /usr/local/bin/garaga https://github.com/noir-lang/garaga/releases/download/v0.18.1/garaga-linux-x64 && \
    chmod +x /usr/local/bin/garaga

# 设置工作目录
WORKDIR /workspace

# 验证安装版本
RUN echo "Nargo version:" && nargo --version && \
    echo "Barretenberg version:" && bb --version && \
    echo "Garaga version:" && garaga --version && \
    echo "Node.js version:" && node --version && \
    echo "Bun version:" && bun --version

# 默认命令，启动一个 shell 以便交互使用
CMD ["/bin/bash"]

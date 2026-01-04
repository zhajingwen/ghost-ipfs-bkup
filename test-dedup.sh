#!/bin/bash
# 手动测试去重脚本是否能成功执行

echo "=========================================="
echo "测试去重脚本执行环境"
echo "=========================================="

# 1. 检查 node 命令是否可用
echo ""
echo "1. 检查 node 命令..."
echo "当前 PATH: $PATH"
echo ""

# 尝试不同的方式查找 node
echo "尝试查找 node 命令："
which node 2>/dev/null && echo "✓ 通过 which 找到 node: $(which node)" || echo "✗ which 找不到 node"

if [ -x "/usr/local/bin/node" ]; then
    echo "✓ /usr/local/bin/node 存在且可执行"
    /usr/local/bin/node --version
elif [ -x "/usr/bin/node" ]; then
    echo "✓ /usr/bin/node 存在且可执行"
    /usr/bin/node --version
else
    echo "✗ 常见路径中找不到 node"
fi

# 2. 检查去重脚本是否存在
echo ""
echo "2. 检查去重脚本..."
if [ -f "/usr/local/bin/dedup-posts.js" ]; then
    echo "✓ 去重脚本存在: /usr/local/bin/dedup-posts.js"
    ls -lh /usr/local/bin/dedup-posts.js
else
    echo "✗ 去重脚本不存在: /usr/local/bin/dedup-posts.js"
fi

# 3. 检查数据库文件
echo ""
echo "3. 检查数据库文件..."
DB_PATH="${GHOST_DB_PATH:-/var/lib/ghost/content/data/ghost.db}"
if [ -f "$DB_PATH" ]; then
    echo "✓ 数据库文件存在: $DB_PATH"
    ls -lh "$DB_PATH"
else
    echo "✗ 数据库文件不存在: $DB_PATH"
fi

# 4. 检查 NODE_PATH
echo ""
echo "4. 检查 NODE_PATH..."
NODE_PATH="/var/lib/ghost/node_modules"
if [ -d "$NODE_PATH" ]; then
    echo "✓ NODE_PATH 目录存在: $NODE_PATH"
    if [ -f "$NODE_PATH/better-sqlite3/package.json" ]; then
        echo "✓ better-sqlite3 已安装"
    else
        echo "✗ better-sqlite3 未找到"
    fi
else
    echo "✗ NODE_PATH 目录不存在: $NODE_PATH"
fi

# 5. 模拟 cron 环境测试（最小 PATH）
echo ""
echo "5. 模拟 cron 环境测试（最小 PATH）..."
export PATH="/usr/bin:/bin"
echo "模拟 cron PATH: $PATH"

# 尝试执行去重脚本
echo ""
echo "6. 尝试执行去重脚本..."
echo "执行命令: NODE_PATH=$NODE_PATH node /usr/local/bin/dedup-posts.js"

# 尝试不同的 node 路径
NODE_FOUND=0
for NODE_BIN in "/usr/local/bin/node" "/usr/bin/node" "$(which node 2>/dev/null)"; do
    if [ -n "$NODE_BIN" ] && [ -x "$NODE_BIN" ]; then
        echo ""
        echo "使用 node: $NODE_BIN"
        echo "版本: $($NODE_BIN --version 2>&1)"
        echo ""
        echo "开始执行去重脚本..."
        echo "----------------------------------------"
        NODE_PATH=$NODE_PATH $NODE_BIN /usr/local/bin/dedup-posts.js 2>&1
        EXIT_CODE=$?
        echo "----------------------------------------"
        if [ $EXIT_CODE -eq 0 ]; then
            echo "✓ 去重脚本执行成功！"
            NODE_FOUND=1
            break
        else
            echo "✗ 去重脚本执行失败，退出码: $EXIT_CODE"
        fi
    fi
done

if [ $NODE_FOUND -eq 0 ]; then
    echo ""
    echo "✗ 无法找到可用的 node 命令"
    echo ""
    echo "建议的修复方法："
    echo "1. 在 backup.sh 中设置完整的 PATH"
    echo "2. 使用完整路径调用 node"
    echo "3. 或者在 cron 任务中设置 PATH 环境变量"
fi

echo ""
echo "=========================================="
echo "测试完成"
echo "=========================================="


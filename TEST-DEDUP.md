# 手动测试去重脚本执行

## 方法一：在运行中的容器内测试

### 1. 进入容器
```bash
# 找到运行中的容器
docker ps | grep ghost

# 进入容器（替换 CONTAINER_ID 为实际容器ID）
docker exec -it <CONTAINER_ID> /bin/bash
```

### 2. 在容器内执行测试脚本
```bash
# 复制测试脚本到容器（如果还没有）
# 或者直接在容器内创建并执行

# 方法A：直接执行测试命令
bash /path/to/test-dedup.sh

# 方法B：手动逐步测试
```

### 3. 手动逐步测试

#### 步骤1：检查 node 是否可用
```bash
# 检查 PATH
echo $PATH

# 查找 node
which node
/usr/local/bin/node --version
/usr/bin/node --version

# 如果都找不到，查看 Ghost 安装目录
ls -la /var/lib/ghost/current/node_modules/.bin/node
```

#### 步骤2：检查去重脚本
```bash
# 检查脚本是否存在
ls -lh /usr/local/bin/dedup-posts.js

# 检查脚本内容
head -20 /usr/local/bin/dedup-posts.js
```

#### 步骤3：检查依赖
```bash
# 检查 better-sqlite3 是否安装
ls -la /var/lib/ghost/node_modules/better-sqlite3

# 检查数据库文件
ls -lh /var/lib/ghost/content/data/ghost.db
```

#### 步骤4：模拟 cron 环境测试
```bash
# cron 环境通常只有最小 PATH
export PATH="/usr/bin:/bin"

# 尝试执行
NODE_PATH=/var/lib/ghost/node_modules node /usr/local/bin/dedup-posts.js

# 如果失败，尝试使用完整路径
NODE_PATH=/var/lib/ghost/node_modules /usr/local/bin/node /usr/local/bin/dedup-posts.js
```

#### 步骤5：测试备份脚本中的去重部分
```bash
# 直接执行备份脚本中的去重命令
NODE_PATH=/var/lib/ghost/node_modules node /usr/local/bin/dedup-posts.js 2>&1 || true

# 查看输出，应该看到去重日志或错误信息
```

---

## 方法二：在本地测试（如果有 Ghost 环境）

### 1. 设置环境变量
```bash
export GHOST_DB_PATH="/path/to/ghost.db"
export NODE_PATH="/path/to/ghost/node_modules"
```

### 2. 执行测试脚本
```bash
./test-dedup.sh
```

---

## 方法三：测试 cron 环境

### 1. 创建测试 cron 任务
```bash
# 进入容器
docker exec -it <CONTAINER_ID> /bin/bash

# 编辑 crontab
crontab -e

# 添加测试任务（每分钟执行一次，方便观察）
* * * * * /usr/local/bin/test-dedup.sh >> /tmp/dedup-test.log 2>&1

# 或者直接测试去重命令
* * * * * NODE_PATH=/var/lib/ghost/node_modules node /usr/local/bin/dedup-posts.js >> /tmp/dedup-test.log 2>&1
```

### 2. 查看日志
```bash
# 等待1分钟后查看
tail -f /tmp/dedup-test.log
```

### 3. 清理测试任务
```bash
crontab -e
# 删除测试任务
```

---

## 预期结果

### ✅ 成功的情况
```
[DEDUP] Found X duplicate titles
[DEDUP] "文章标题": deleted 1 old version(s)
...
[DEDUP] Total deleted: X posts
```

### ❌ 失败的情况
```
node: command not found
```
或
```
Error: Cannot find module 'better-sqlite3'
```
或
```
[ERROR] Deduplication failed: ...
```

---

## 常见问题排查

### 问题1：node 命令找不到
**原因**：cron 环境的 PATH 不完整

**解决方案**：
1. 在脚本开头设置 PATH
2. 使用完整路径调用 node
3. 在 crontab 中设置 PATH

### 问题2：better-sqlite3 模块找不到
**原因**：NODE_PATH 设置不正确

**解决方案**：
```bash
# 确保 NODE_PATH 指向正确的目录
export NODE_PATH=/var/lib/ghost/node_modules
```

### 问题3：数据库文件找不到
**原因**：GHOST_DB_PATH 环境变量未设置或路径错误

**解决方案**：
```bash
# 检查数据库路径
export GHOST_DB_PATH=/var/lib/ghost/content/data/ghost.db
```

---

## 快速测试命令

```bash
# 一键测试（在容器内执行）
docker exec -it <CONTAINER_ID> bash -c "
  export PATH=\"/usr/local/bin:/usr/bin:/bin:\$PATH\"
  NODE_PATH=/var/lib/ghost/node_modules node /usr/local/bin/dedup-posts.js 2>&1
"
```


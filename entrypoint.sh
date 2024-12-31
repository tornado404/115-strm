#!/bin/sh

# 设置默认日志级别为 1（如果未传入 LOG_LEVEL 环境变量）
LOG_LEVEL=${LOG_LEVEL:-1}

# 启动 crond 并使用指定的日志级别
exec /sbin/tini -- sh -c "crond -f -l ${LOG_LEVEL}"
#!/bin/bash
# 颜色定义
GREEN="\e[32m"
RESET="\e[0m"

# GOST 常量定义
GOST_VERSION="3.0.0"
GOST_URL="https://github.com/go-gost/gost/releases/download/v${GOST_VERSION}/gost-linux-amd64-${GOST_VERSION}.gz"
GOST_BINARY="/usr/local/bin/gost"
GOST_CONFIG_FILE="/etc/gost-config.json"
GOST_SERVICE="/etc/systemd/system/gost.service"

# 检查是否是 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${GREEN}请以 root 用户运行此脚本。${RESET}"
    exit 1
fi

# 安装 GOST
install_gost() {
    echo -e "${GREEN}正在安装 GOST...${RESET}"
    apt update -y && apt install -y curl wget jq
    wget -qO gost.gz "$GOST_URL"
    gunzip gost.gz && chmod +x gost && mv gost "$GOST_BINARY"
    create_systemd_service
    initialize_gost_config
    echo -e "${GREEN}GOST 安装完成！${RESET}"
}

# 更新 GOST
update_gost() {
    echo -e "${GREEN}正在更新 GOST...${RESET}"
    if [ -f "$GOST_BINARY" ]; then
        wget -qO gost.gz "$GOST_URL"
        gunzip gost.gz && chmod +x gost && mv gost "$GOST_BINARY"
        systemctl restart gost
        echo -e "${GREEN}GOST 已更新到最新版本！${RESET}"
    else
        echo -e "${GREEN}未检测到 GOST，无法更新，请先安装！${RESET}"
    fi
}

# 卸载 GOST
uninstall_gost() {
    echo -e "${GREEN}正在卸载 GOST...${RESET}"
    systemctl stop gost
    systemctl disable gost
    rm -f "$GOST_BINARY"
    rm -f "$GOST_CONFIG_FILE"
    rm -f "$GOST_SERVICE"
    systemctl daemon-reload
    echo -e "${GREEN}GOST 卸载完成！${RESET}"
}

# 创建 Systemd 服务
create_systemd_service() {
    cat > "$GOST_SERVICE" <<EOF
[Unit]
Description=GOST v3 Service
After=network.target

[Service]
ExecStart=/usr/local/bin/gost -C $GOST_CONFIG_FILE
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable gost
}

# 初始化空配置文件
initialize_gost_config() {
    if [ ! -f "$GOST_CONFIG_FILE" ]; then
        echo -e "${GREEN}初始化 GOST 配置文件...${RESET}"
        echo '{}' > "$GOST_CONFIG_FILE"
    fi
}

# 启动 GOST
start_gost() {
    systemctl start gost
    echo -e "${GREEN}GOST 已启动！${RESET}"
}

# 停止 GOST
stop_gost() {
    systemctl stop gost
    echo -e "${GREEN}GOST 已停止！${RESET}"
}

# 重启 GOST
restart_gost() {
    systemctl restart gost
    echo -e "${GREEN}GOST 已重启！${RESET}"
}

# 新增 GOST WebSocket 配置
add_ws_config() {
    initialize_gost_config

    read -p "请输入本地监听端口: " LOCAL_PORT
    read -p "请输入目标 IP 和端口 (格式: IP:PORT): " TARGET_ADDR

    RULE="{\"name\":\"ws-${LOCAL_PORT}\",\"addr\":\":${LOCAL_PORT}\",\"handler\":{\"type\":\"forward\",\"target\":\"${TARGET_ADDR}\"},\"listener\":{\"type\":\"ws\"}}"
    
    jq ".services += [$RULE]" "$GOST_CONFIG_FILE" > /tmp/gost.json && mv /tmp/gost.json "$GOST_CONFIG_FILE"

    echo -e "${GREEN}WebSocket 转发规则已添加至配置文件！${RESET}"
    restart_gost
}

# 查看现有 GOST 配置
view_gost_config() {
    initialize_gost_config
    echo -e "${GREEN}当前 GOST 配置: ${RESET}"
    jq . "$GOST_CONFIG_FILE"
}

# 删除一则 GOST 配置
delete_gost_config() {
    initialize_gost_config
    echo -e "${GREEN}当前配置的服务列表：${RESET}"
    jq -c '.services[] | {name, addr}' "$GOST_CONFIG_FILE"

    read -p "请输入要删除的服务名称 (例如 ws-监听端口号): " SERVICE_NAME
    jq "del(.services[] | select(.name == \"$SERVICE_NAME\"))" "$GOST_CONFIG_FILE" > /tmp/gost.json && mv /tmp/gost.json "$GOST_CONFIG_FILE"

    echo -e "${GREEN}已删除服务规则！${RESET}"
    restart_gost
}

# 主菜单
main_menu() {
    while true; do
        echo -e "${GREEN}===== GOST v3 WebSocket 转发管理脚本 =====${RESET}"
        echo "1. 安装 GOST"
        echo "2. 更新 GOST"
        echo "3. 卸载 GOST"
        echo "————————————"
        echo "4. 启动 GOST"
        echo "5. 停止 GOST"
        echo "6. 重启 GOST"
        echo "————————————"
        echo "7. 新增 WebSocket 转发配置"
        echo "8. 查看现有配置"
        echo "9. 删除一则 WebSocket 配置"
        echo "10. 退出"
        read -p "请选择一个操作 [1-10]: " choice
        case "$choice" in
            1) install_gost ;;
            2) update_gost ;;
            3) uninstall_gost ;;
            4) start_gost ;;
            5) stop_gost ;;
            6) restart_gost ;;
            7) add_ws_config ;;
            8) view_gost_config ;;
            9) delete_gost_config ;;
            10) exit 0 ;;
            *) echo -e "${GREEN}请输入正确的选项！${RESET}" ;;
        esac
    done
}

main_menu

#!/bin/bash

# 颜色定义
GREEN="\e[32m"
RESET="\e[0m"

# 安装必要依赖
install_dependencies() {
    echo -e "${GREEN}正在安装必要依赖...${RESET}"
    apt update -y && apt install -y curl wget unzip
}

# 下载并安装 GOST v3
download_gost() {
    echo -e "${GREEN}正在下载 GOST v3...${RESET}"
    GOST_VERSION="3.0.0"
    GOST_URL="https://github.com/go-gost/gost/releases/download/v${GOST_VERSION}/gost-linux-amd64-${GOST_VERSION}.gz"
    wget -O gost.gz "$GOST_URL"
    gunzip gost.gz && chmod +x gost && mv gost /usr/local/bin/gost
}

# 生成 GOST 配置文件
generate_config() {
    read -p "请输入本地监听端口: " LOCAL_PORT
    read -p "请输入目标 IP: " TARGET_IP
    read -p "请输入目标端口: " TARGET_PORT

    cat > /etc/gost-config.json <<EOF
{
    "services": [
        {
            "name": "forward",
            "addr": ":$LOCAL_PORT",
            "handler": {
                "type": "forward",
                "target": "$TARGET_IP:$TARGET_PORT"
            },
            "listener": {
                "type": "ws"
            }
        }
    ]
}
EOF
    echo -e "${GREEN}GOST 配置已生成！${RESET}"
    systemctl restart gost
}

# 创建 systemd 服务
setup_systemd() {
    cat > /etc/systemd/system/gost.service <<EOF
[Unit]
Description=GOST v3 Service
After=network.target

[Service]
ExecStart=/usr/local/bin/gost -C /etc/gost-config.json
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable gost
    systemctl restart gost
    echo -e "${GREEN}GOST 已安装并开机自启！${RESET}"
}

# 查看当前 GOST 配置
view_config() {
    echo -e "${GREEN}当前 GOST 配置: ${RESET}"
    cat /etc/gost-config.json
}

# 卸载 GOST
uninstall_gost() {
    echo -e "${GREEN}正在卸载 GOST...${RESET}"
    systemctl stop gost
    systemctl disable gost
    rm -f /usr/local/bin/gost
    rm -f /etc/gost-config.json
    rm -f /etc/systemd/system/gost.service
    systemctl daemon-reload
    echo -e "${GREEN}GOST 已卸载！${RESET}"
}

# 菜单
main_menu() {
    while true; do
        echo -e "${GREEN}===== GOST v3 一键管理脚本 =====${RESET}"
        echo "1. 安装 GOST"
        echo "2. 查看当前 GOST 配置"
        echo "3. 修改 GOST 配置"
        echo "4. 卸载 GOST"
        echo "5. 退出"
        read -p "请选择一个操作 [1-5]: " choice

        case "$choice" in
            1) install_dependencies && download_gost && generate_config && setup_systemd ;;
            2) view_config ;;
            3) generate_config ;;
            4) uninstall_gost ;;
            5) exit 0 ;;
            *) echo -e "${GREEN}请输入正确的选项！${RESET}" ;;
        esac
    done
}

main_menu

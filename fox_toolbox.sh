#!/bin/bash
export LANG=en_US.UTF-8
# 定义颜色
re='\e[0m'
red='\e[1;91m'
white='\e[1;97m'
green='\e[1;32m'
yellow='\e[1;33m'
purple='\e[1;35m'
blue='\e[1;34m'
cyan='\e[1;36m'
skyblue='\e[1;96m'

# 检查是否为root下运行
[[ $EUID -ne 0 ]] && echo -e "${red}注意: 请在root用户下运行脚本${re}" && sleep 1 && exit 1

# 创建快捷指令
create_shortcut() {
    wrapper_content='#!/bin/bash
# 在线获取最新脚本并执行
SCRIPT_URL="https://raw.githubusercontent.com/netjan666/FoxToolBox/main/fox_toolbox.sh"
TEMP_SCRIPT="/tmp/fox_toolbox_latest.sh"

# 下载最新脚本（屏蔽输出）
if curl -fsSL "$SCRIPT_URL" -o "$TEMP_SCRIPT" >/dev/null 2>&1; then
    chmod +x "$TEMP_SCRIPT" >/dev/null 2>&1
    bash "$TEMP_SCRIPT" "$@"
    rm -f "$TEMP_SCRIPT" >/dev/null 2>&1
else
    echo "无法在线获取脚本，请检查网络连接"
    exit 1
fi'
    
    script_path="/usr/local/bin/fox_toolbox.sh"
    echo "$wrapper_content" > "$script_path"
    chmod +x "$script_path"
    link_names=("k" "K")
    
    for link_name in "${link_names[@]}"; do
        link_path="/usr/local/bin/$link_name"
        if [ ! -L "$link_path" ] || [ "$(readlink "$link_path")" != "$script_path" ]; then
            ln -sf "$script_path" "$link_path" >/dev/null 2>&1
        fi
    done
    hash -r >/dev/null 2>&1
}
create_shortcut

# 获取当前服务器ipv4和ipv6
ip_address() {
    ipv4_address=$(curl -s -m 2 ipv4.ip.sb)
    ipv6_address=$(curl -s -m 2 ipv6.ip.sb)
}

# 安装依赖包
install() {
    if [ $# -eq 0 ]; then
        echo -e "${red}未提供软件包参数!${re}"
        return 1
    fi

    for package in "$@"; do
        if command -v "$package" &>/dev/null; then
            echo -e "${green}${package}已经安装了！${re}"
            continue
        fi
        echo -e "${yellow}正在安装 ${package}...${re}"
        if command -v apt &>/dev/null; then
            DEBIAN_FRONTEND=noninteractive apt install -y "$package"
        elif command -v dnf &>/dev/null; then
            dnf install -y "$package"
        elif command -v yum &>/dev/null; then
            yum install -y "$package"
        elif command -v apk &>/dev/null; then
            apk add "$package"
        else
            echo -e"${red}暂不支持你的系统!${re}"
            return 1
        fi
    done

    return 0
}

# 卸载依赖包
remove() {
    if [ $# -eq 0 ]; then
        echo -e "${red}未提供软件包参数!${re}"
        return 1
    fi

    for package in "$@"; do
        if command -v apt &>/dev/null; then
            apt remove -y "$package" && apt autoremove -y
        elif command -v dnf &>/dev/null; then
            dnf remove -y "$package" && dnf autoremove -y
        elif command -v yum &>/dev/null; then
            yum remove -y "$package" && yum autoremove -y
        elif command -v apk &>/dev/null; then
            apk del "$package"
        else
            echo -e "${red}暂不支持你的系统!${re}"
            return 1
        fi
    done

    return 0
}

# 安装nodejs
install_nodejs(){
    if command -v node &>/dev/null; then
        # 获取当前已安装nodejs版本
        installed_version=$(node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        echo -e "${green}系统中已经安装Nodejs,版本:${red}${installed_version}${re}"
    else
        echo -e "${yellow}系统中未安装nodejs，正在为你安装...${re}"

        # 根据对应系统安装nodejs
        if command -v apt &>/dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && install nodejs
        elif command -v dnf &>/dev/null; then
            dnf install -y nodejs npm
        elif command -v yum &>/dev/null; then
            curl -fsSL https://rpm.nodesource.com/setup_21.x | sudo bash - && install nodejs
        elif command -v apk &>/dev/null; then
            apk add nodejs npm
        else
            echo -e "${red}暂不支持你的系统!${re}"
            return 1
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${green}nodejs安装成功!${re}"
            sleep 2
        else
            echo -e "${red}nodejs安装失败，尝试再次安装...${re}"
            install nodejs npm
            sleep 2
        fi
    fi 
}

# 安装java
install_java() {
    if command -v java &>/dev/null; then
        # 检查安装版本
        installed_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo -e "${green}系统已经安装Java${yellow}${installed_version}${re}"     

    else
        echo -e "${yellow}系统中未安装Java，正在为你安装...${re}"

        local install_status=0

        if command -v apt &>/dev/null; then
            apt install -y openjdk-17-jdk
        elif command -v yum &>/dev/null; then
            yum install -y java-17-openjdk
        elif command -v dnf &>/dev/null; then
            dnf install -y java-17-openjdk
        elif command -v apk &>/dev/null; then
            apk add openjdk17
        else
            echo -e "${red}暂不支持你的系统！${re}"
            exit 1
        fi

        if [ $install_status -eq 0 ]; then
            echo -e "${green}Java安装成功${re}"
            sleep 2
            break_end
        else                    
            echo -e "${red}Java安装失败，尝试为你再次安装...${re}"
            install java-17-openjdk
            sleep 2
            break_end
        fi
    fi   
}

# 初始安装依赖包
install_dependency() {
      clear
      install wget socat unzip tar
}

# 等待用户返回
break_end() {
    echo -e "${green}执行完成${re}"
    echo -e "${yellow}按任意键返回...${re}"
    read -n 1 -s -r -p ""
    echo ""
    clear
}
# 返回主菜单
main_menu() {
    cd ~
    k
    exit
}

check_port() {
    # 定义要检测的端口
    PORT=443

    # 检查端口占用情况
    result=$(ss -tulpn | grep ":$PORT")

    # 判断结果并输出相应信息
    if [ -n "$result" ]; then
        is_nginx_container=$(docker ps --format '{{.Names}}' | grep 'nginx')

        # 判断是否是Nginx容器占用端口
        if [ -n "$is_nginx_container" ]; then
            echo ""
        else
            clear
            echo -e "\e[1;31m端口 $PORT 已被占用，无法安装环境，卸载以下程序后重试！\e[0m"
            echo "$result"
            break_end
            ssh_tool
        fi
    else
        echo ""
    fi
}


# 定义安装 Docker 的函数
install_docker() {
    if ! command -v docker &>/dev/null; then
        curl -fsSL https://get.docker.com | sh && ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin
        systemctl start docker
        systemctl enable docker
    else
        echo "Docker 已经安装"
    fi
}

iptables_open() {
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
}

# ============ LDNMP 建站模块（提取自 kejilion，已适配 FoxToolBox） ============

# 兼容层：kejilion 统计与 kpanel 协议钩子（Fox 中为空操作，保留以维持函数体结构完整）
send_stats() { :; }
kpanel_web_progress() { :; }
kpanel_web_interactive() { return 1; }

ldnmp_v() {

	  # 获取nginx版本
	  local nginx_version=$(docker exec nginx nginx -v 2>&1)
	  local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "nginx : ${gl_huang}v$nginx_version${gl_bai}"

	  # 获取mysql版本
	  local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  local mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	  echo -n -e "            mysql : ${gl_huang}v$mysql_version${gl_bai}"

	  # 获取php版本
	  local php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "            php : ${gl_huang}v$php_version${gl_bai}"

	  # 获取redis版本
	  local redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
	  echo -e "            redis : ${gl_huang}v$redis_version${gl_bai}"

	  echo "------------------------"
	  echo ""

}



install_ldnmp_conf() {

  # 创建必要的目录和文件
  cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/stream.d web/redis web/log/nginx web/letsencrypt && touch web/docker-compose.yml
  wget -O /home/web/nginx.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default10.conf

  default_server_ssl

  # 下载 docker-compose.yml 文件并进行替换
  wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
  dbrootpasswd=$(openssl rand -base64 16) ; dbuse=$(openssl rand -hex 4) ; dbusepasswd=$(openssl rand -base64 8)

  # 在 docker-compose.yml 文件中进行替换
  sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml

}


update_docker_compose_with_db_creds() {

  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml

  if ! grep -q "letsencrypt" /home/web/docker-compose.yml; then
	wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml

  	dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')
  	dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')
  	dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')

	sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
	sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
	sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml
  fi

  if grep -q "kjlion/nginx:alpine" /home/web/docker-compose1.yml; then
  	sed -i 's|kjlion/nginx:alpine|nginx:alpine|g' /home/web/docker-compose.yml  > /dev/null 2>&1
	sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml  > /dev/null 2>&1
  fi

}





auto_optimize_dns() {
	# 获取国家代码（如 CN、US 等）
	local country=$(curl -s ipinfo.io/country)

	# 根据国家设置 DNS
	if [ "$country" = "CN" ]; then
		local dns1_ipv4="223.5.5.5"
		local dns2_ipv4="183.60.83.19"
		local dns1_ipv6="2400:3200::1"
		local dns2_ipv6="2400:da00::6666"
	else
		local dns1_ipv4="1.1.1.1"
		local dns2_ipv4="8.8.8.8"
		local dns1_ipv6="2606:4700:4700::1111"
		local dns2_ipv6="2001:4860:4860::8888"
	fi

	set_dns


}


prefer_ipv4() {
grep -q '^precedence ::ffff:0:0/96  100' /etc/gai.conf 2>/dev/null \
	|| echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf
echo "已切换为 IPv4 优先"
send_stats "已切换为 IPv4 优先"
}




install_ldnmp() {

	  update_docker_compose_with_db_creds

	  cd /home/web && docker compose up -d
	  sleep 1
  	  crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
  	  (crontab -l 2>/dev/null; echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf') | crontab -

	  fix_phpfpm_conf php
	  fix_phpfpm_conf php74

	  # mysql调优
	  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
	  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
	  rm -rf /home/custom_mysql_config.cnf



	  restart_ldnmp
	  sleep 2

	  clear
	  echo "LDNMP环境安装完毕"
	  echo "------------------------"
	  ldnmp_v

}


install_certbot() {

	cd ~
	curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/auto_cert_renewal.sh
	chmod +x auto_cert_renewal.sh

	check_crontab_installed
	local cron_job="0 0 * * * ~/auto_cert_renewal.sh"
	crontab -l 2>/dev/null | grep -vF "$cron_job" | crontab -
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	echo "续签任务已更新"
}


install_ssltls() {
	  docker stop nginx > /dev/null 2>&1
	  cd ~

	  local file_path="/etc/letsencrypt/live/$yuming/fullchain.pem"
	  if [ ! -f "$file_path" ]; then
		 	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
			local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'
			if [[ ($yuming =~ $ipv4_pattern || $yuming =~ $ipv6_pattern) ]]; then
				mkdir -p /etc/letsencrypt/live/$yuming/
				if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
					openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout /etc/letsencrypt/live/$yuming/privkey.pem -out /etc/letsencrypt/live/$yuming/fullchain.pem -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
				else
					openssl genpkey -algorithm Ed25519 -out /etc/letsencrypt/live/$yuming/privkey.pem
					openssl req -x509 -key /etc/letsencrypt/live/$yuming/privkey.pem -out /etc/letsencrypt/live/$yuming/fullchain.pem -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
				fi
			else
				docker run --rm -p 80:80 -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot certonly --standalone -d "$yuming" --email your@email.com --agree-tos --no-eff-email --force-renewal --key-type ecdsa
			fi
	  fi
	  mkdir -p /home/web/certs/
	  cp /etc/letsencrypt/live/$yuming/fullchain.pem /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1
	  cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem > /dev/null 2>&1

	  docker start nginx > /dev/null 2>&1
}



install_ssltls_text() {
	echo -e "${gl_huang}$yuming 公钥信息${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
	echo -e "${gl_huang}$yuming 私钥信息${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}证书存放路径${gl_bai}"
	echo "公钥: /etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "私钥: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo ""
}





add_ssl() {
echo -e "${gl_huang}快速申请SSL证书，过期前自动续签${gl_bai}"
yuming="${1:-}"
if [ -z "$yuming" ]; then
	add_yuming
fi
install_docker
install_certbot
docker run --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
install_ssltls
certs_status
install_ssltls_text
ssl_ps
}


ssl_ps() {
	echo -e "${gl_huang}已申请的证书到期情况${gl_bai}"
	echo "站点信息                      证书到期时间"
	echo "------------------------"
	for cert_dir in /etc/letsencrypt/live/*; do
	  local cert_file="$cert_dir/fullchain.pem"
	  if [ -f "$cert_file" ]; then
		local domain=$(basename "$cert_dir")
		local expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print $2}')
		local formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
		printf "%-30s%s\n" "$domain" "$formatted_date"
	  fi
	done
	echo ""
}




default_server_ssl() {
install openssl

if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
	openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout /home/web/certs/default_server.key -out /home/web/certs/default_server.crt -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
else
	openssl genpkey -algorithm Ed25519 -out /home/web/certs/default_server.key
	openssl req -x509 -key /home/web/certs/default_server.key -out /home/web/certs/default_server.crt -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
fi

openssl rand -out /home/web/certs/ticket12.key 48
openssl rand -out /home/web/certs/ticket13.key 80

}


certs_status() {

	sleep 1

	local file_path="/etc/letsencrypt/live/$yuming/fullchain.pem"
	if [ -f "$file_path" ]; then
		send_stats "域名证书申请成功"
	else
		send_stats "域名证书申请失败"
		if [ "${KJ_WEB_NONINTERACTIVE:-0}" = "1" ] &&
			! kpanel_web_interactive; then
			echo "KPANEL_PROGRESS 100 域名证书申请失败，请检查 DNS、80/443 端口和签发限额"
			return 1
		fi
		echo -e "${gl_hong}注意: ${gl_bai}证书申请失败，请检查以下可能原因并重试："
		echo -e "1. 域名拼写错误 ➠ 请检查域名输入是否正确"
		echo -e "2. DNS解析问题 ➠ 确认域名已正确解析到本服务器IP"
		echo -e "3. 网络配置问题 ➠ 如使用Cloudflare Warp等虚拟网络请暂时关闭"
		echo -e "4. 防火墙限制 ➠ 检查80/443端口是否开放，确保验证可访问"
		echo -e "5. 申请次数超限 ➠ Let's Encrypt有每周限额(5次/域名/周)"
		echo -e "6. 国内备案限制 ➠ 中国大陆环境请确认域名是否备案"
		echo "------------------------"
		echo "1. 重新申请        2. 导入已有证书        0. 退出"
		echo "------------------------"
		read -e -p "请输入你的选择: " sub_choice
		case $sub_choice in
	  	  1)
	  	  	send_stats "重新申请"
		  	echo "请再次尝试部署 $webname"
		  	add_yuming
		  	install_ssltls
		  	certs_status

	  		  ;;
	  	  2)
	  	  	send_stats "导入已有证书"

			# 定义文件路径
			local cert_file="/home/web/certs/${yuming}_cert.pem"
			local key_file="/home/web/certs/${yuming}_key.pem"

			mkdir -p /home/web/certs

			# 1. 输入证书 (ECC 和 RSA 证书开头都是 BEGIN CERTIFICATE)
			echo "请粘贴 证书 (CRT/PEM) 内容 (按两次回车结束)："
			local cert_content=""
			while IFS= read -r line; do
				[[ -z "$line" && "$cert_content" == *"-----BEGIN"* ]] && break
				cert_content+="${line}"$'\n'
			done

			# 2. 输入私钥 (兼容 RSA, ECC, PKCS#8)
			echo "请粘贴 证书私钥 (Private Key) 内容 (按两次回车结束)："
			local key_content=""
			while IFS= read -r line; do
				[[ -z "$line" && "$key_content" == *"-----BEGIN"* ]] && break
				key_content+="${line}"$'\n'
			done

			# 3. 智能校验
			# 只要包含 "BEGIN CERTIFICATE" 和 "PRIVATE KEY" 即可通过
			if [[ "$cert_content" == *"-----BEGIN CERTIFICATE-----"* && "$key_content" == *"PRIVATE KEY-----"* ]]; then
				echo -n "$cert_content" > "$cert_file"
				echo -n "$key_content" > "$key_file"

				chmod 644 "$cert_file"
				chmod 600 "$key_file"

				# 识别当前证书类型并显示
				if [[ "$key_content" == *"EC PRIVATE KEY"* ]]; then
					echo "检测到 ECC 证书已成功保存。"
				else
					echo "检测到 RSA 证书已成功保存。"
				fi
				auth_method="ssl_imported"
			else
				echo "错误：无效的证书或私钥格式！"
				certs_status
			fi
	  		  ;;
	  	  *)
		  	  exit
	  		  ;;
		esac
	fi

}


repeat_add_yuming() {
if [ -e /home/web/conf.d/$yuming.conf ]; then
  send_stats "域名重复使用"
  if [ "${KJ_WEB_NONINTERACTIVE:-0}" = "1" ]; then
	echo "KPANEL_PROGRESS 100 域名已存在，拒绝覆盖 kejilion.sh 或 KPanel 的现有产物"
	return 1
  fi
  web_del "${yuming}" > /dev/null 2>&1
fi

}


add_yuming() {
	  if [ "${KJ_WEB_NONINTERACTIVE:-0}" = "1" ]; then
		  yuming="${KJ_WEB_DOMAIN:-}"
		  if [ -z "$yuming" ] || [ ${#yuming} -gt 253 ] ||
			  ! printf '%s' "$yuming" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$'; then
			  echo "KPANEL_PROGRESS 100 KJ_WEB_DOMAIN 不是有效的域名"
			  return 1
		  fi
		  return 0
	  fi
	  ip_address
	  echo -e "先将域名解析到本机IP: ${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	  read -e -p "请输入你的IP或者解析过的域名: " yuming
}


check_ip_and_get_access_port() {
	local yuming="$1"

	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
	local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'

	if [[ "$yuming" =~ $ipv4_pattern || "$yuming" =~ $ipv6_pattern ]]; then
		read -e -p "请输入访问/监听端口，回车默认使用 80: " access_port
		access_port=${access_port:-80}
	fi
}



update_nginx_listen_port() {
	local yuming="$1"
	local access_port="$2"
	local conf="/home/web/conf.d/${yuming}.conf"

	# 如果 access_port 为空，则跳过
	[ -z "$access_port" ] && return 0

	# 删除所有 listen 行
	sed -i '/^[[:space:]]*listen[[:space:]]\+/d' "$conf"

	# 在 server { 后插入新的 listen
	sed -i "/server {/a\\
	listen ${access_port};\\
	listen [::]:${access_port};
" "$conf"
}



add_db() {
	  dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
	  dbname="${dbname}"

	  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"
}


ldnmp_web_root_base="/home/web/html"

ldnmp_site_domain_is_safe() {
	  local site_domain="${1:-}"
	  case "$site_domain" in
		  ""|"."|".."|*/*)
			  echo "无效的站点目录名称: $site_domain" >&2
			  return 1
			  ;;
	  esac
}

prepare_ldnmp_site_root() {
	  local site_domain="${1:-}"
	  ldnmp_site_domain_is_safe "$site_domain" || return 1
	  command mkdir -p -- "${ldnmp_web_root_base}/${site_domain}" &&
	  command chmod 0755 -- "$ldnmp_web_root_base" "${ldnmp_web_root_base}/${site_domain}"
}

normalize_ldnmp_site_permissions() {
	  local site_domain="${1:-}"
	  local site_root
	  ldnmp_site_domain_is_safe "$site_domain" || return 1
	  site_root="${ldnmp_web_root_base}/${site_domain}"
	  [ -d "$site_root" ] || {
		  echo "站点目录不存在: $site_root" >&2
		  return 1
	  }

	  find "$site_root" -type d -exec chmod u+rwx,go+rx,go-w {} + &&
	  find "$site_root" -type f -exec chmod u+rw,go+r,go-w {} +
}


restart_ldnmp() {
	  docker exec nginx chown -R nginx:nginx /var/www/html > /dev/null 2>&1
	  docker exec nginx mkdir -p /var/cache/nginx/proxy > /dev/null 2>&1
	  docker exec nginx mkdir -p /var/cache/nginx/fastcgi > /dev/null 2>&1
	  docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy > /dev/null 2>&1
	  docker exec nginx chown -R nginx:nginx /var/cache/nginx/fastcgi > /dev/null 2>&1
	  docker exec php chown -R www-data:www-data /var/www/html > /dev/null 2>&1
	  docker exec php74 chown -R www-data:www-data /var/www/html > /dev/null 2>&1
	  cd /home/web && docker compose restart


}

nginx_upgrade() {

  local ldnmp_pods="nginx"
  cd /home/web/
  docker rm -f $ldnmp_pods > /dev/null 2>&1
  docker images --filter=reference="kjlion/${ldnmp_pods}*" -q | xargs docker rmi > /dev/null 2>&1
  docker images --filter=reference="${ldnmp_pods}*" -q | xargs docker rmi > /dev/null 2>&1
  docker compose up -d --force-recreate $ldnmp_pods
  crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
  (crontab -l 2>/dev/null; echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf') | crontab -
  docker exec nginx chown -R nginx:nginx /var/www/html
  docker exec nginx mkdir -p /var/cache/nginx/proxy
  docker exec nginx mkdir -p /var/cache/nginx/fastcgi
  docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy
  docker exec nginx chown -R nginx:nginx /var/cache/nginx/fastcgi
  docker restart $ldnmp_pods > /dev/null 2>&1

  send_stats "更新$ldnmp_pods"
  echo "更新${ldnmp_pods}完成"

}

phpmyadmin_upgrade() {
  local ldnmp_pods="phpmyadmin"
  local local docker_port=8877
  local dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
  local dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

  cd /home/web/
  docker rm -f $ldnmp_pods > /dev/null 2>&1
  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/docker/refs/heads/main/docker-compose.phpmyadmin.yml
  docker compose -f docker-compose.phpmyadmin.yml up -d
  clear
  ip_address

  check_docker_app_ip
  echo "登录信息: "
  echo "用户名: $dbuse"
  echo "密码: $dbusepasswd"
  echo
  send_stats "启动$ldnmp_pods"
}


cf_purge_cache() {
  local CONFIG_FILE="/home/web/config/cf-purge-cache.txt"
  local API_TOKEN
  local EMAIL
  local ZONE_IDS

  # 检查配置文件是否存在
  if [ -f "$CONFIG_FILE" ]; then
	# 从配置文件读取 API_TOKEN 和 zone_id
	read API_TOKEN EMAIL ZONE_IDS < "$CONFIG_FILE"
	# 将 ZONE_IDS 转换为数组
	ZONE_IDS=($ZONE_IDS)
  else
	# 提示用户是否清理缓存
	read -e -p "需要清理 Cloudflare 的缓存吗？（y/n）: " answer
	if [[ "$answer" == "y" ]]; then
	  echo "CF信息保存在$CONFIG_FILE，可以后期修改CF信息"
	  read -e -p "请输入你的 API_TOKEN: " API_TOKEN
	  read -e -p "请输入你的CF用户名: " EMAIL
	  read -e -p "请输入 zone_id（多个用空格分隔）: " -a ZONE_IDS

	  mkdir -p /home/web/config/
	  echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" > "$CONFIG_FILE"
	fi
  fi

  # 循环遍历每个 zone_id 并执行清除缓存命令
  for ZONE_ID in "${ZONE_IDS[@]}"; do
	echo "正在清除缓存 for zone_id: $ZONE_ID"
	curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
	-H "X-Auth-Email: $EMAIL" \
	-H "X-Auth-Key: $API_TOKEN" \
	-H "Content-Type: application/json" \
	--data '{"purge_everything":true}'
  done

  echo "缓存清除请求已发送完毕。"
}



web_cache() {
  send_stats "清理站点缓存"
  cf_purge_cache
  cd /home/web && docker compose restart
}



web_del() {

	send_stats "删除站点数据"
	local -a yuming_list=()
	if [ "$#" -gt 0 ]; then
		yuming_list=("$@")
	else
		local yuming_input=""
		read -e -p "删除站点数据，请输入你的域名（多个域名用空格隔开）: " yuming_input
		if [[ -z "$yuming_input" ]]; then
			return
		fi
		read -r -a yuming_list <<< "$yuming_input"
	fi

	local action_status=0
	for yuming in "${yuming_list[@]}"; do
		if [ -z "$yuming" ] || [ "${#yuming}" -gt 253 ] ||
			! printf '%s' "$yuming" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$'; then
			echo "无效域名，拒绝删除: $yuming"
			action_status=1
			continue
		fi

		echo "正在删除域名: $yuming"
		rm -rf -- "/home/web/html/$yuming" > /dev/null 2>&1
		rm -f -- "/home/web/conf.d/$yuming.conf" > /dev/null 2>&1
		rm -f -- "/home/web/certs/${yuming}_key.pem" > /dev/null 2>&1
		rm -f -- "/home/web/certs/${yuming}_cert.pem" > /dev/null 2>&1

		# 将域名转换为数据库名
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		if [ -f /home/web/docker-compose.yml ] &&
			docker inspect mysql > /dev/null 2>&1; then
			dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
			echo "正在删除数据库: $dbname"
			if docker exec mysql mysql -u root -p"$dbrootpasswd" \
				-e "DROP DATABASE IF EXISTS \`${dbname}\`;" > /dev/null 2>&1; then
				echo "KPANEL_DELETE_DATABASE dropped $yuming"
			else
				echo "KPANEL_DELETE_DATABASE failed $yuming"
				action_status=1
			fi
		else
			echo "KPANEL_DELETE_DATABASE skipped $yuming"
		fi

		if [ -e "/home/web/html/$yuming" ] ||
			[ -e "/home/web/conf.d/$yuming.conf" ] ||
			[ -e "/home/web/certs/${yuming}_key.pem" ] ||
			[ -e "/home/web/certs/${yuming}_cert.pem" ]; then
			echo "站点产物删除不完整: $yuming"
			action_status=1
		else
			echo "KPANEL_DELETE_SITE deleted $yuming"
		fi
	done

	if docker inspect nginx > /dev/null 2>&1; then
		if ! docker exec nginx nginx -t > /dev/null 2>&1 ||
			! docker exec nginx nginx -s reload; then
			echo "Nginx 配置验证或重载失败"
			action_status=1
		fi
	else
		echo "KPANEL_DELETE_WARNING nginx_unavailable"
	fi

	return "$action_status"
}


nginx_waf() {
	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	# 根据 mode 参数来决定开启或关闭 WAF
	if [ "$mode" == "on" ]; then
		# 开启 WAF：去掉注释
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# 关闭 WAF：加上注释
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "无效的参数：使用 'on' 或 'off'"
		return 1
	fi

	# 检查 nginx 镜像并根据情况处理
	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		docker exec nginx nginx -s reload
	else
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml
		nginx_upgrade
	fi

}

check_waf_status() {
	if grep -q "^\s*#\s*modsecurity on;" /home/web/nginx.conf; then
		waf_status=""
	elif grep -q "modsecurity on;" /home/web/nginx.conf; then
		waf_status=" WAF已开启"
	else
		waf_status=""
	fi
}


check_cf_mode() {
	if [ -f "/etc/fail2ban/action.d/cloudflare-docker.conf" ]; then
		CFmessage=" cf模式已开启"
	else
		CFmessage=""
	fi
}


nginx_http_on() {

local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
local ipv6_pattern='^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))))$'
if [[ ($yuming =~ $ipv4_pattern || $yuming =~ $ipv6_pattern) ]]; then
	sed -i '/if (\$scheme = http) {/,/}/s/^/#/' /home/web/conf.d/${yuming}.conf
fi

}


patch_wp_memory_limit() {
  local MEMORY_LIMIT="${1:-256M}"      # 第一个参数，默认256M
  local MAX_MEMORY_LIMIT="${2:-256M}"  # 第二个参数，默认256M
  local TARGET_DIR="/home/web/html"    # 路径写死

  find "$TARGET_DIR" -type f -name "wp-config.php" | while read -r FILE; do
	# 删除旧定义
	sed -i "/define(['\"]WP_MEMORY_LIMIT['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_MAX_MEMORY_LIMIT['\"].*/d" "$FILE"

	# 插入新定义，放在含 "Happy publishing" 的行前
	awk -v insert="define('WP_MEMORY_LIMIT', '$MEMORY_LIMIT');\ndefine('WP_MAX_MEMORY_LIMIT', '$MAX_MEMORY_LIMIT');" \
	'
	  /Happy publishing/ {
		print insert
	  }
	  { print }
	' "$FILE" > "$FILE.tmp" && mv -f "$FILE.tmp" "$FILE"

	echo "[+] Replaced WP_MEMORY_LIMIT in $FILE"
  done
}




patch_wp_debug() {
  local DEBUG="${1:-false}"           # 第一个参数，默认false
  local DEBUG_DISPLAY="${2:-false}"   # 第二个参数，默认false
  local DEBUG_LOG="${3:-false}"       # 第三个参数，默认false
  local TARGET_DIR="/home/web/html"   # 路径写死

  find "$TARGET_DIR" -type f -name "wp-config.php" | while read -r FILE; do
	# 删除旧定义
	sed -i "/define(['\"]WP_DEBUG['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_DISPLAY['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_LOG['\"].*/d" "$FILE"

	# 插入新定义，放在含 "Happy publishing" 的行前
	awk -v insert="define('WP_DEBUG_DISPLAY', $DEBUG_DISPLAY);\ndefine('WP_DEBUG_LOG', $DEBUG_LOG);" \
	'
	  /Happy publishing/ {
		print insert
	  }
	  { print }
	' "$FILE" > "$FILE.tmp" && mv -f "$FILE.tmp" "$FILE"

	echo "[+] Replaced WP_DEBUG settings in $FILE"
  done
}




patch_wp_url() {
  local HOME_URL="$1"
  local SITE_URL="$2"
  local TARGET_DIR="/home/web/html"

  find "$TARGET_DIR" -type f -name "wp-config-sample.php" | while read -r FILE; do
	# 删除旧定义
	sed -i "/define(['\"]WP_HOME['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_SITEURL['\"].*/d" "$FILE"

	# 生成插入内容
	INSERT="
define('WP_HOME', '$HOME_URL');
define('WP_SITEURL', '$SITE_URL');
"

	# 插入到 “Happy publishing” 之前
	awk -v insert="$INSERT" '
	  /Happy publishing/ {
		print insert
	  }
	  { print }
	' "$FILE" > "$FILE.tmp" && mv -f "$FILE.tmp" "$FILE"

	echo "[+] Updated WP_HOME and WP_SITEURL in $FILE"
  done
}








nginx_br() {

	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	if [ "$mode" == "on" ]; then
		# 开启 Brotli：去掉注释
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|' /home/web/nginx.conf > /dev/null 2>&1

		sed -i 's|^\(\s*\)# brotli on;|\1brotli on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_static on;|\1brotli_static on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_comp_level \(.*\);|\1brotli_comp_level \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_buffers \(.*\);|\1brotli_buffers \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_min_length \(.*\);|\1brotli_min_length \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_window \(.*\);|\1brotli_window \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_types \(.*\);|\1brotli_types \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i '/brotli_types/,+6 s/^\(\s*\)#\s*/\1/' /home/web/nginx.conf

	elif [ "$mode" == "off" ]; then
		# 关闭 Brotli：加上注释
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|# load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|# load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|' /home/web/nginx.conf > /dev/null 2>&1

		sed -i 's|^\(\s*\)brotli on;|\1# brotli on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_static on;|\1# brotli_static on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_comp_level \(.*\);|\1# brotli_comp_level \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_buffers \(.*\);|\1# brotli_buffers \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_min_length \(.*\);|\1# brotli_min_length \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_window \(.*\);|\1# brotli_window \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_types \(.*\);|\1# brotli_types \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i '/brotli_types/,+6 {
			/^[[:space:]]*[^#[:space:]]/ s/^\(\s*\)/\1# /
		}' /home/web/nginx.conf

	else
		echo "无效的参数：使用 'on' 或 'off'"
		return 1
	fi

	# 检查 nginx 镜像并根据情况处理
	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		docker exec nginx nginx -s reload
	else
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml
		nginx_upgrade
	fi


}



nginx_zstd() {

	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	if [ "$mode" == "on" ]; then
		# 开启 Zstd：去掉注释
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|' /home/web/nginx.conf > /dev/null 2>&1

		sed -i 's|^\(\s*\)# zstd on;|\1zstd on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_static on;|\1zstd_static on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_comp_level \(.*\);|\1zstd_comp_level \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_buffers \(.*\);|\1zstd_buffers \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_min_length \(.*\);|\1zstd_min_length \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_types \(.*\);|\1zstd_types \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i '/zstd_types/,+6 s/^\(\s*\)#\s*/\1/' /home/web/nginx.conf



	elif [ "$mode" == "off" ]; then
		# 关闭 Zstd：加上注释
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|# load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|# load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|' /home/web/nginx.conf > /dev/null 2>&1

		sed -i 's|^\(\s*\)zstd on;|\1# zstd on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_static on;|\1# zstd_static on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_comp_level \(.*\);|\1# zstd_comp_level \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_buffers \(.*\);|\1# zstd_buffers \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_min_length \(.*\);|\1# zstd_min_length \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_types \(.*\);|\1# zstd_types \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i '/zstd_types/,+6 {
			/^[[:space:]]*[^#[:space:]]/ s/^\(\s*\)/\1# /
		}' /home/web/nginx.conf


	else
		echo "无效的参数：使用 'on' 或 'off'"
		return 1
	fi

	# 检查 nginx 镜像并根据情况处理
	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		docker exec nginx nginx -s reload
	else
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml
		nginx_upgrade
	fi



}








nginx_gzip() {

	local mode=$1
	if [ "$mode" == "on" ]; then
		sed -i 's|^\(\s*\)# gzip on;|\1gzip on;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		sed -i 's|^\(\s*\)gzip on;|\1# gzip on;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "无效的参数：使用 'on' 或 'off'"
		return 1
	fi

	docker exec nginx nginx -s reload

}






web_security() {
	  send_stats "LDNMP环境防御"
	  while true; do
		check_f2b_status
		check_waf_status
		check_cf_mode
			  clear
			  echo -e "服务器网站防御程序 ${check_f2b_status}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. 安装防御程序"
			  echo "------------------------"
			  echo "5. 查看SSH拦截记录                6. 查看网站拦截记录"
			  echo "7. 查看防御规则列表               8. 查看日志实时监控"
			  echo "------------------------"
			  echo "11. 配置拦截参数                  12. 清除所有拉黑的IP"
			  echo "------------------------"
			  echo "21. cloudflare模式                22. 高负载开启5秒盾"
			  echo "------------------------"
			  echo "31. 开启WAF                       32. 关闭WAF"
			  echo "33. 开启DDOS防御                  34. 关闭DDOS防御"
			  echo "------------------------"
			  echo "9. 卸载防御程序"
			  echo "------------------------"
			  echo "0. 返回上一级选单"
			  echo "------------------------"
			  read -e -p "请输入你的选择: " sub_choice
			  case $sub_choice in
				  1)
					  f2b_install_sshd
					  cd /etc/fail2ban/filter.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/fail2ban-nginx-cc.conf
					  wget ${gh_proxy}raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-418.conf
					  wget ${gh_proxy}raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-deny.conf
					  wget ${gh_proxy}raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-unauthorized.conf
					  wget ${gh_proxy}raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-bad-request.conf

					  cd /etc/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf
					  sed -i "/cloudflare/d" /etc/fail2ban/jail.d/nginx-docker-cc.conf
					  f2b_status
					  ;;
				  5)
					  echo "------------------------"
					  f2b_sshd
					  echo "------------------------"
					  ;;
				  6)

					  echo "------------------------"
					  local xxx="fail2ban-nginx-cc"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-418"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-bad-request"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-badbots"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-botsearch"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-deny"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-http-auth"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-unauthorized"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="php-url-fopen"
					  f2b_status_xxx
					  echo "------------------------"

					  ;;

				  7)
					  fail2ban-client status
					  ;;
				  8)
					  tail -f /var/log/fail2ban.log

					  ;;
				  9)
					  remove fail2ban
					  rm -rf /etc/fail2ban
					  crontab -l | grep -v "CF-Under-Attack.sh" | crontab - 2>/dev/null
					  echo "Fail2Ban防御程序已卸载"
					  break
					  ;;

				  11)
					  install nano
					  nano /etc/fail2ban/jail.d/nginx-docker-cc.conf
					  f2b_status
					  break
					  ;;

				  12)
					  fail2ban-client unban --all
					  ;;

				  21)
					  send_stats "cloudflare模式"
					  echo "到cf后台右上角我的个人资料，选择左侧API令牌，获取Global API Key"
					  echo "https://dash.cloudflare.com/login"
					  read -e -p "输入CF的账号: " cfuser
					  read -e -p "输入CF的Global API Key: " cftoken

					  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
					  docker exec nginx nginx -s reload

					  cd /etc/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

					  cd /etc/fail2ban/action.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

					  sed -i "s/kejilion@outlook.com/$cfuser/g" /etc/fail2ban/action.d/cloudflare-docker.conf
					  sed -i "s/APIKEY00000/$cftoken/g" /etc/fail2ban/action.d/cloudflare-docker.conf
					  f2b_status

					  echo "已配置cloudflare模式，可在cf后台，站点-安全性-事件中查看拦截记录"
					  ;;

				  22)
					  send_stats "高负载开启5秒盾"
					  echo -e "${gl_huang}网站每5分钟自动检测，当达检测到高负载会自动开盾，低负载也会自动关闭5秒盾。${gl_bai}"
					  echo "--------------"
					  echo "获取CF参数: "
					  echo -e "到cf后台右上角我的个人资料，选择左侧API令牌，获取${gl_huang}Global API Key${gl_bai}"
					  echo -e "到cf后台域名概要页面右下方获取${gl_huang}区域ID${gl_bai}"
					  echo "https://dash.cloudflare.com/login"
					  echo "--------------"
					  read -e -p "输入CF的账号: " cfuser
					  read -e -p "输入CF的Global API Key: " cftoken
					  read -e -p "输入CF中域名的区域ID: " cfzonID

					  cd ~
					  install jq bc
					  check_crontab_installed
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/CF-Under-Attack.sh
					  chmod +x CF-Under-Attack.sh
					  sed -i "s/AAAA/$cfuser/g" ~/CF-Under-Attack.sh
					  sed -i "s/BBBB/$cftoken/g" ~/CF-Under-Attack.sh
					  sed -i "s/CCCC/$cfzonID/g" ~/CF-Under-Attack.sh

					  local cron_job="*/5 * * * * ~/CF-Under-Attack.sh"

					  local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

					  if [ -z "$existing_cron" ]; then
						  (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
						  echo "高负载自动开盾脚本已添加"
					  else
						  echo "自动开盾脚本已存在，无需添加"
					  fi

					  ;;

				  31)
					  nginx_waf on
					  echo "站点WAF已开启"
					  send_stats "站点WAF已开启"
					  ;;

				  32)
				  	  nginx_waf off
					  echo "站点WAF已关闭"
					  send_stats "站点WAF已关闭"
					  ;;

				  33)
					  enable_ddos_defense
					  ;;

				  34)
					  disable_ddos_defense
					  ;;

				  *)
					  break
					  ;;
			  esac
	  break_end
	  done
}



check_ldnmp_mode() {

	local MYSQL_CONTAINER="mysql"
	local MYSQL_CONF="/etc/mysql/conf.d/custom_mysql_config.cnf"

	# 检查 MySQL 配置文件中是否包含 4096M
	if docker exec "$MYSQL_CONTAINER" grep -q "4096M" "$MYSQL_CONF" 2>/dev/null; then
		mode_info=" 高性能模式"
	else
		mode_info=" 标准模式"
	fi



}


check_nginx_compression() {

	local CONFIG_FILE="/home/web/nginx.conf"

	# 检查 zstd 是否开启且未被注释（整行以 zstd on; 开头）
	if grep -qE '^\s*zstd\s+on;' "$CONFIG_FILE"; then
		zstd_status=" zstd压缩已开启"
	else
		zstd_status=""
	fi

	# 检查 brotli 是否开启且未被注释
	if grep -qE '^\s*brotli\s+on;' "$CONFIG_FILE"; then
		br_status=" br压缩已开启"
	else
		br_status=""
	fi

	# 检查 gzip 是否开启且未被注释
	if grep -qE '^\s*gzip\s+on;' "$CONFIG_FILE"; then
		gzip_status=" gzip压缩已开启"
	else
		gzip_status=""
	fi
}

ldnmp_optimization_mode() {
	local mode="${1:-}"
	local cpu_cores connections connections_per_core php_fpm_source mysql_source
	case "$mode" in
		standard)
			connections_per_core=1024
			php_fpm_source="www-1.conf"
			mysql_source="custom_mysql_config-1.cnf"
			;;
		high)
			connections_per_core=2048
			php_fpm_source="www.conf"
			mysql_source="custom_mysql_config.cnf"
			;;
		*)
			echo "不支持的 LDNMP 优化模式" >&2
			return 2
			;;
	esac

	cpu_cores=$(nproc)
	connections=$((connections_per_core * cpu_cores))
	sed -i "s/worker_processes.*/worker_processes ${cpu_cores};/" /home/web/nginx.conf
	sed -i "s/worker_connections.*/worker_connections ${connections};/" /home/web/nginx.conf

	wget -O /home/optimized_php.ini "${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini" &&
		docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
	docker inspect php74 >/dev/null 2>&1 &&
		docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
	rm -f /home/optimized_php.ini

	wget -O /home/www.conf "${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/${php_fpm_source}" &&
		docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
	docker inspect php74 >/dev/null 2>&1 &&
		docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
	rm -f /home/www.conf

	if [ "$mode" = high ]; then
		patch_wp_memory_limit 512M 512M
	else
		patch_wp_memory_limit
	fi
	patch_wp_debug
	fix_phpfpm_conf php
	docker inspect php74 >/dev/null 2>&1 && fix_phpfpm_conf php74

	wget -O /home/custom_mysql_config.cnf \
		"${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/${mysql_source}" &&
		docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
	rm -f /home/custom_mysql_config.cnf

	cd /home/web && docker compose restart || return 1
	if [ "$mode" = high ]; then
		optimize_web_server
		echo "LDNMP环境已设置成 高性能模式"
	else
		optimize_balanced
		echo "LDNMP环境已设置成 标准模式"
	fi
}

web_optimization() {
		  while true; do
		  	  check_ldnmp_mode
			  check_nginx_compression
			  clear
			  send_stats "优化LDNMP环境"
			  echo -e "优化LDNMP环境${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. 标准模式              2. 高性能模式 (推荐2H4G以上)"
			  echo "------------------------"
			  echo "3. 开启gzip压缩          4. 关闭gzip压缩"
			  echo "5. 开启br压缩            6. 关闭br压缩"
			  echo "7. 开启zstd压缩          8. 关闭zstd压缩"
			  echo "------------------------"
			  echo "0. 返回上一级选单"
			  echo "------------------------"
			  read -e -p "请输入你的选择: " sub_choice
			  case $sub_choice in
				  1)
				  send_stats "站点标准模式"
				  ldnmp_optimization_mode standard
					  ;;
				  2)
				  send_stats "站点高性能模式"
				  ldnmp_optimization_mode high
					  ;;
				  3)
				  send_stats "nginx_gzip on"
				  nginx_gzip on
					  ;;
				  4)
				  send_stats "nginx_gzip off"
				  nginx_gzip off
					  ;;
				  5)
				  send_stats "nginx_br on"
				  nginx_br on
					  ;;
				  6)
				  send_stats "nginx_br off"
				  nginx_br off
					  ;;
				  7)
				  send_stats "nginx_zstd on"
				  nginx_zstd on
					  ;;
				  8)
				  send_stats "nginx_zstd off"
				  nginx_zstd off
					  ;;
				  *)
					  break
					  ;;
			  esac
			  break_end

		  done


}
# --- [B] ---
ldnmp_install_status_one() {

   if docker inspect "php" &>/dev/null; then
	clear
	send_stats "无法再次安装LDNMP环境"
	echo -e "${gl_huang}提示: ${gl_bai}建站环境已安装。无需再次安装！"
	break_end
	linux_ldnmp
   fi

}


ldnmp_install_all() {
cd ~
send_stats "安装LDNMP环境"
root_use
clear
echo -e "${gl_huang}LDNMP环境未安装，开始安装LDNMP环境...${gl_bai}"
check_disk_space 3 /home
install_dependency
install_docker
install_certbot
install_ldnmp_conf
install_ldnmp

}


nginx_install_all() {
cd ~
send_stats "安装nginx环境"
root_use
clear
echo -e "${gl_huang}nginx未安装，开始安装nginx环境...${gl_bai}"
install_dependency
install_docker
install_certbot
install_ldnmp_conf
nginx_upgrade
clear
local nginx_version=$(docker exec nginx nginx -v 2>&1)
local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
echo "nginx已安装完成"
echo -e "当前版本: ${gl_huang}v$nginx_version${gl_bai}"
echo ""

}




ldnmp_install_status() {

	if ! docker inspect "php" &>/dev/null; then
		send_stats "请先安装LDNMP环境"
		ldnmp_install_all
	fi

}


nginx_install_status() {

	if ! docker inspect "nginx" &>/dev/null; then
		send_stats "请先安装nginx环境"
		nginx_install_all
	fi

}




ldnmp_web_on() {
	  clear
	  echo "您的 $webname 搭建好了！"
	  echo "https://$yuming"
	  echo "------------------------"
	  echo "$webname 安装信息如下: "

}

nginx_web_on() {
	clear

	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
	local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'

	echo "您的 $webname 搭建好了！"

	if [[ "$yuming" =~ $ipv4_pattern || "$yuming" =~ $ipv6_pattern ]]; then
		mv /home/web/conf.d/"$yuming".conf /home/web/conf.d/"${yuming}_${access_port}".conf
		echo "http://$yuming:$access_port"
	elif grep -q '^[[:space:]]*#.*if (\$scheme = http)' "/home/web/conf.d/"$yuming".conf"; then
		echo "http://$yuming"
	else
		echo "https://$yuming"
	fi
}



ldnmp_wp() {
  clear
  # wordpress
  webname="WordPress"
  yuming="${1:-}"
  kpanel_web_progress 10 "正在校验 WordPress 域名与现有站点"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  if [ -z "$yuming" ]; then
	add_yuming
  fi
  repeat_add_yuming
  kpanel_web_progress 20 "正在准备 kejilion.sh LDNMP 环境"
  ldnmp_install_status


  kpanel_web_progress 35 "正在签发并配置站点证书"
  install_ssltls
  certs_status
  kpanel_web_progress 50 "正在创建 WordPress 数据库与账号"
  add_db

  kpanel_web_progress 60 "正在获取 kejilion.sh WordPress Nginx 配置"
  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/wordpress.com.conf
  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
  nginx_http_on


  kpanel_web_progress 75 "正在获取并配置 kejilion.sh WordPress 源码"
  cd /home/web/html
  prepare_ldnmp_site_root "$yuming" || return 1
  cd $yuming
  wget -O latest.zip ${gh_proxy}github.com/kejilion/Website_source_code/raw/refs/heads/main/wp-latest.zip
  unzip latest.zip
  rm latest.zip
  echo "define('FS_METHOD', 'direct'); define('WP_REDIS_HOST', 'redis'); define('WP_REDIS_PORT', '6379'); define('WP_REDIS_MAXTTL', 86400); define('WP_CACHE_KEY_SALT', '${yuming}_');" >> /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|database_name_here|$dbname|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|username_here|$dbuse|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|password_here|$dbusepasswd|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|localhost|mysql|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  patch_wp_url "https://$yuming" "https://$yuming"
  cp /home/web/html/$yuming/wordpress/wp-config-sample.php /home/web/html/$yuming/wordpress/wp-config.php


  kpanel_web_progress 90 "正在重启 LDNMP 并核验 WordPress 站点"
  normalize_ldnmp_site_permissions "$yuming" || return 1
  chmod 0640 "/home/web/html/$yuming/wordpress/wp-config.php" || return 1
  restart_ldnmp
  nginx_web_on

}



ldnmp_Proxy() {
	clear
	webname="反向代理-IP+端口"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	kpanel_web_progress 10 "正在校验反向代理域名与上游地址"
	send_stats "安装$webname"
	echo "开始部署 $webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	check_ip_and_get_access_port "$yuming"

	if [ -z "$reverseproxy" ]; then
		read -e -p "请输入你的反代IP (回车默认本机IP 127.0.0.1): " reverseproxy
		reverseproxy=${reverseproxy:-127.0.0.1}
	fi

	if [ -z "$port" ]; then
		read -e -p "请输入你的反代端口: " port
	fi
	kpanel_web_progress 25 "正在准备 kejilion.sh Nginx 环境"
	nginx_install_status


	kpanel_web_progress 40 "正在签发并配置反向代理证书"
	install_ssltls
	certs_status

	kpanel_web_progress 60 "正在获取 kejilion.sh 反向代理配置"
	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/backend_$backend/g" /home/web/conf.d/"$yuming".conf


	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	reverseproxy_port="$reverseproxy:$port"
	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	sed -i "s/# 动态添加/$upstream_servers/g" /home/web/conf.d/$yuming.conf
	sed -i '/remote_addr/d' /home/web/conf.d/$yuming.conf

	update_nginx_listen_port "$yuming" "$access_port"

	kpanel_web_progress 85 "正在校验并重载反向代理配置"
	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
}



ldnmp_Proxy_backend() {
	clear
	webname="反向代理-负载均衡"

	send_stats "安装$webname"
	echo "开始部署 $webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	check_ip_and_get_access_port "$yuming"

	if [ -z "$reverseproxy_port" ]; then
		read -e -p "请输入你的多个反代IP+端口用空格隔开（例如 127.0.0.1:3000 127.0.0.1:3002）： " reverseproxy_port
	fi

	nginx_install_status

	install_ssltls
	certs_status

	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/backend_$backend/g" /home/web/conf.d/"$yuming".conf


	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	sed -i "s/# 动态添加/$upstream_servers/g" /home/web/conf.d/$yuming.conf


	update_nginx_listen_port "$yuming" "$access_port"

	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
}






list_stream_services() {

	STREAM_DIR="/home/web/stream.d"
	printf "%-25s %-18s %-25s %-20s\n" "服务名" "通信类型" "本机地址" "后端地址"

	if [ -z "$(ls -A "$STREAM_DIR")" ]; then
		return
	fi

	for conf in "$STREAM_DIR"/*; do
		# 服务名取文件名
		service_name=$(basename "$conf" .conf)

		# 获取 upstream 块中的 server 后端 IP:端口
		backend=$(grep -Po '(?<=server )[^;]+' "$conf" | head -n1)

		# 获取 listen 端口
		listen_port=$(grep -Po '(?<=listen )[^;]+' "$conf" | head -n1)

		# 默认本地 IP
		ip_address
		local_ip="$ipv4_address"

		# 获取通信类型，优先从文件名后缀或内容判断
		if grep -qi 'udp;' "$conf"; then
			proto="udp"
		else
			proto="tcp"
		fi

		# 拼接监听 IP:端口
		local_addr="$local_ip:$listen_port"

		printf "%-22s %-14s %-21s %-20s\n" "$service_name" "$proto" "$local_addr" "$backend"
	done
}









stream_panel() {
	send_stats "Stream四层代理"
	local app_id="104"
	local docker_name="nginx"

	while true; do
		clear
		check_docker_app
		check_docker_image_update $docker_name
		echo -e "Stream四层代理转发工具 $check_docker $update_status"
		echo "NGINX Stream 是 NGINX 的 TCP/UDP 代理模块，用于实现高性能的 传输层流量转发和负载均衡。"
		echo "------------------------"
		if [ -d "/home/web/stream.d" ]; then
			list_stream_services
		fi
		echo ""
		echo "------------------------"
		echo "1. 安装               2. 更新               3. 卸载"
		echo "------------------------"
		echo "4. 添加转发服务       5. 修改转发服务       6. 删除转发服务"
		echo "------------------------"
		echo "0. 返回上一级选单"
		echo "------------------------"
		read -e -p "输入你的选择: " choice
		case $choice in
			1)
				nginx_install_status
				add_app_id
				send_stats "安装Stream四层代理"
				;;
			2)
				update_docker_compose_with_db_creds
				nginx_upgrade
				add_app_id
				send_stats "更新Stream四层代理"
				;;
			3)
				read -e -p "确定要删除 nginx 容器吗？这可能会影响网站功能！(y/N): " confirm
				if [[ "$confirm" =~ ^[Yy]$ ]]; then
					docker rm -f nginx
					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					send_stats "更新Stream四层代理"
					echo "nginx 容器已删除。"
				else
					echo "操作已取消。"
				fi

				;;

			4)
				ldnmp_Proxy_backend_stream
				add_app_id
				send_stats "添加四层代理"
				;;
			5)
				send_stats "编辑转发配置"
				read -e -p "请输入你要编辑的服务名: " stream_name
				install nano
				nano /home/web/stream.d/$stream_name.conf
				docker restart nginx
				send_stats "修改四层代理"
				;;
			6)
				send_stats "删除转发配置"
				read -e -p "请输入你要删除的服务名: " stream_name
				rm /home/web/stream.d/$stream_name.conf > /dev/null 2>&1
				docker restart nginx
				send_stats "删除四层代理"
				;;
			*)
				break
				;;
		esac
		break_end
	done
}



ldnmp_Proxy_backend_stream() {
	clear
	webname="Stream四层代理-负载均衡"

	send_stats "安装$webname"
	echo "开始部署 $webname"

	# 获取代理名称
	read -erp "请输入代理转发名称 (如 mysql_proxy): " proxy_name
	if [ -z "$proxy_name" ]; then
		echo "名称不能为空"; return 1
	fi

	# 获取监听端口
	read -erp "请输入本机监听端口 (如 3306): " listen_port
	if ! [[ "$listen_port" =~ ^[0-9]+$ ]]; then
		echo "端口必须是数字"; return 1
	fi

	echo "请选择协议类型："
	echo "1. TCP    2. UDP"
	read -erp "请输入序号 [1-2]: " proto_choice

	case "$proto_choice" in
		1) proto="tcp"; listen_suffix="" ;;
		2) proto="udp"; listen_suffix=" udp" ;;
		*) echo "无效选择"; return 1 ;;
	esac

	read -e -p "请输入你的一个或者多个后端IP+端口用空格隔开（例如 10.13.0.2:3306 10.13.0.3:3306）： " reverseproxy_port

	nginx_install_status
	cd /home && mkdir -p web/stream.d
	grep -q '^[[:space:]]*stream[[:space:]]*{' /home/web/nginx.conf || echo -e '\nstream {\n    include /etc/nginx/stream.d/*.conf;\n}' | tee -a /home/web/nginx.conf
	wget -O /home/web/stream.d/$proxy_name.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend-stream.conf

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/${proxy_name}_${backend}/g" /home/web/stream.d/"$proxy_name".conf
	sed -i "s|listen 80|listen $listen_port $listen_suffix|g" /home/web/stream.d/$proxy_name.conf
	sed -i "s|listen \[::\]:|listen [::]:${listen_port} ${listen_suffix}|g" "/home/web/stream.d/${proxy_name}.conf"

	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	sed -i "s/# 动态添加/$upstream_servers/g" /home/web/stream.d/$proxy_name.conf

	docker exec nginx nginx -s reload
	clear
	echo "您的 $webname 搭建好了！"
	echo "------------------------"
	echo "访问地址:"
	ip_address
	if [ -n "$ipv4_address" ]; then
		echo "$ipv4_address:${listen_port}"
	fi
	if [ -n "$ipv6_address" ]; then
		echo "$ipv6_address:${listen_port}"
	fi
	echo ""
}





find_container_by_host_port() {
	port="$1"
	docker_name=$(docker ps --format '{{.ID}} {{.Names}}' | while read id name; do
		if docker port "$id" | grep -q ":$port"; then
			echo "$name"
			break
		fi
	done)
}




ldnmp_web_status() {
	root_use
	while true; do
		local cert_count=$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l)
		local output="${gl_lv}${cert_count}${gl_bai}"

		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
		local db_output="${gl_lv}${db_count}${gl_bai}"

		clear
		send_stats "LDNMP站点管理"
		echo "LDNMP环境"
		echo "------------------------"
		ldnmp_v

		echo -e "站点: ${output}                      证书到期时间"
		echo -e "------------------------"
		for cert_file in /home/web/certs/*_cert.pem; do
		  local domain=$(basename "$cert_file" | sed 's/_cert.pem//')
		  if [ -n "$domain" ]; then
			local expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print $2}')
			local formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
			printf "%-30s%s\n" "$domain" "$formatted_date"
		  fi
		done

		for conf_file in /home/web/conf.d/*_*.conf; do
		  [ -e "$conf_file" ] || continue
		  basename "$conf_file" .conf
		done

		for conf_file in /home/web/conf.d/*.conf; do
		  [ -e "$conf_file" ] || continue

		  filename=$(basename "$conf_file")

		  if [ "$filename" = "map.conf" ] || [ "$filename" = "default.conf" ]; then
			continue
		  fi

		  if ! grep -q "ssl_certificate" "$conf_file"; then
			basename "$conf_file" .conf
		  fi
		done

		echo "------------------------"
		echo ""
		echo -e "数据库: ${db_output}"
		echo -e "------------------------"
		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys"

		echo "------------------------"
		echo ""
		echo "站点目录"
		echo "------------------------"
		echo -e "数据 ${gl_hui}/home/web/html${gl_bai}     证书 ${gl_hui}/home/web/certs${gl_bai}     配置 ${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo ""
		echo "操作"
		echo "------------------------"
		echo "1.  申请/更新域名证书               2.  克隆站点域名"
		echo "3.  清理站点缓存                    4.  创建关联站点"
		echo "5.  查看访问日志                    6.  查看错误日志"
		echo "7.  编辑全局配置                    8.  编辑站点配置"
		echo "9.  管理站点数据库                  10. 查看站点分析报告"
		echo "------------------------"
		echo "20. 删除指定站点数据"
		echo "------------------------"
		echo "0. 返回上一级选单"
		echo "------------------------"
		read -e -p "请输入你的选择: " sub_choice
		case $sub_choice in
			1)
				send_stats "申请域名证书"
				read -e -p "请输入你的域名: " yuming
				install_certbot
				docker run --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
				install_ssltls
				certs_status

				;;

			2)
				send_stats "克隆站点域名"
				read -e -p "请输入旧域名: " oddyuming
				read -e -p "请输入新域名: " yuming
				install_certbot
				install_ssltls
				certs_status


				add_db
				local odd_dbname=$(echo "$oddyuming" | sed -e 's/[^A-Za-z0-9]/_/g')
				local odd_dbname="${odd_dbname}"

				docker exec mysql mysqldump -u root -p"$dbrootpasswd" $odd_dbname | docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname

				local tables=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "SHOW TABLES;" | awk '{ if (NR>1) print $1 }')
				for table in $tables; do
					columns=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "SHOW COLUMNS FROM $table;" | awk '{ if (NR>1) print $1 }')
					for column in $columns; do
						docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "UPDATE $table SET $column = REPLACE($column, '$oddyuming', '$yuming') WHERE $column LIKE '%$oddyuming%';"
					done
				done

				# 网站目录替换
				cp -r /home/web/html/$oddyuming /home/web/html/$yuming

				find /home/web/html/$yuming -type f -exec sed -i "s/$odd_dbname/$dbname/g" {} +
				find /home/web/html/$yuming -type f -exec sed -i "s/$oddyuming/$yuming/g" {} +

				cp /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
				sed -i "s/$oddyuming/$yuming/g" /home/web/conf.d/$yuming.conf

				cd /home/web && docker compose restart

				;;


			3)
				web_cache
				;;
			4)
				send_stats "创建关联站点"
				echo -e "为现有的站点再关联一个新域名用于访问"
				read -e -p "请输入现有的域名: " oddyuming
				read -e -p "请输入新域名: " yuming
				install_certbot
				install_ssltls
				certs_status

				cp /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
				sed -i "s|server_name $oddyuming|server_name $yuming|g" /home/web/conf.d/$yuming.conf
				sed -i "s|/etc/nginx/certs/${oddyuming}_cert.pem|/etc/nginx/certs/${yuming}_cert.pem|g" /home/web/conf.d/$yuming.conf
				sed -i "s|/etc/nginx/certs/${oddyuming}_key.pem|/etc/nginx/certs/${yuming}_key.pem|g" /home/web/conf.d/$yuming.conf

				docker exec nginx nginx -s reload

				;;
			5)
				send_stats "查看访问日志"
				tail -n 200 /home/web/log/nginx/access.log
				break_end
				;;
			6)
				send_stats "查看错误日志"
				tail -n 200 /home/web/log/nginx/error.log
				break_end
				;;
			7)
				send_stats "编辑全局配置"
				install nano
				nano /home/web/nginx.conf
				docker exec nginx nginx -s reload
				;;

			8)
				send_stats "编辑站点配置"
				read -e -p "编辑站点配置，请输入你要编辑的域名: " yuming
				install nano
				nano /home/web/conf.d/$yuming.conf
				docker exec nginx nginx -s reload
				;;
			9)
				phpmyadmin_upgrade
				break_end
				;;
			10)
				send_stats "查看站点数据"
				install goaccess
				goaccess --log-format=COMBINED /home/web/log/nginx/access.log
				;;

			20)
				web_del
				docker run --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null

				;;
			*)
				break  # 跳出循环，退出菜单
				;;
		esac
	done


}
# --- [C] ---
ldnmp_tato() {
local cert_count=$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l)
local output="${gl_lv}${cert_count}${gl_bai}"

local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')
if [ -n "$dbrootpasswd" ]; then
	local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
fi

local db_output="${gl_lv}${db_count}${gl_bai}"


if command -v docker &>/dev/null; then
	if docker ps --filter "name=nginx" --filter "status=running" | grep -q nginx; then
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_lv}环境已安装${gl_bai}  站点: $output  数据库: $db_output"
	fi
fi

}


fix_phpfpm_conf() {
	local container_name=$1
	docker exec "$container_name" sh -c "mkdir -p /run/$container_name && chmod 777 /run/$container_name"
	docker exec "$container_name" sh -c "sed -i '1i [global]\\ndaemonize = no' /usr/local/etc/php-fpm.d/www.conf"
	docker exec "$container_name" sh -c "sed -i '/^listen =/d' /usr/local/etc/php-fpm.d/www.conf"
	docker exec "$container_name" sh -c "echo -e '\nlisten = /run/$container_name/php-fpm.sock\nlisten.owner = www-data\nlisten.group = www-data\nlisten.mode = 0777' >> /usr/local/etc/php-fpm.d/www.conf"
	docker exec "$container_name" sh -c "rm -f /usr/local/etc/php-fpm.d/zz-docker.conf"

	find /home/web/conf.d/ -type f -name "*.conf" -exec sed -i "s#fastcgi_pass ${container_name}:9000;#fastcgi_pass unix:/run/${container_name}/php-fpm.sock;#g" {} \;

}






kpanel_run_web_recipe_cli() {
	local selector="${1:-}"
	local domain="${2:-}"
	if [ "$#" -ne 2 ]; then
		echo "用法: k <建站命令> <域名>"
		return 64
	fi
	KJ_WEB_NONINTERACTIVE=1
	KJ_WEB_RECIPE="$selector"
	KJ_WEB_DOMAIN="$domain"
	mkdir -p /run/lock
	local lock_fd rc
	exec {lock_fd}>/run/lock/kejilion-web-environment.lock
	if ! flock -n "$lock_fd"; then
		echo "已有网站或 LDNMP 环境任务正在执行" >&2
		exec {lock_fd}>&-
		return 75
	fi
	linux_ldnmp
	rc=$?
	flock -u "$lock_fd"
	exec {lock_fd}>&-
	return "$rc"
}

kpanel_web_recipe_requires_document_root() {
	case "${1:-}" in
		2|3|4|5|6|7|8|9|20|25|26|27|30) return 0 ;;
		*) return 1 ;;
	esac
}

kpanel_ldnmp_escape() {
	local value="${1:-}"
	value=${value//\\/\\\\}; value=${value//\"/\\\"}
	value=${value//$'\n'/\\n}; value=${value//$'\r'/}
	printf '%s' "$value"
}

kpanel_ldnmp_event() {
	printf 'KPANEL_LDNMP_EVENT {"stage":"%s","progress":%s,"message":"%s"}\n' \
		"$(kpanel_ldnmp_escape "$1")" "$2" "$(kpanel_ldnmp_escape "$3")"
}

kpanel_ldnmp_result() {
	local payload
	payload=$(printf '{"status":"%s","action":"%s","message":"%s","finishedAt":"%s"}' \
		"$1" "$2" "$(kpanel_ldnmp_escape "$3")" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')")
	printf 'KPANEL_LDNMP_RESULT %s\n' "$payload"
	case "${KJ_LDNMP_RECEIPT:-}" in
		/var/lib/kejilion-panel/environment-jobs/*.receipt)
			umask 077
			printf '%s\n' "$payload" > "${KJ_LDNMP_RECEIPT}.tmp.$$" &&
				mv -f "${KJ_LDNMP_RECEIPT}.tmp.$$" "$KJ_LDNMP_RECEIPT"
			;;
	esac
}

kpanel_ldnmp_component() {
	local name="$1" required="$2" exists=false running=false state=absent image="" version="" digest=""
	if docker inspect "$name" >/dev/null 2>&1; then
		exists=true
		state=$(docker inspect -f '{{.State.Status}}' "$name" 2>/dev/null)
		image=$(docker inspect -f '{{.Config.Image}}' "$name" 2>/dev/null)
		digest=$(docker image inspect -f '{{index .RepoDigests 0}}' "$image" 2>/dev/null)
		[ "$state" = running ] && running=true
		case "$name" in
			nginx) version=$(docker exec nginx nginx -v 2>&1 | sed -n 's#.*nginx/##p' | head -1) ;;
			php|php74) version=$(docker exec "$name" php -r 'echo PHP_VERSION;' 2>/dev/null) ;;
			redis) version=$(docker exec redis redis-server -v 2>/dev/null | sed -n 's/.*v=\([^ ]*\).*/\1/p') ;;
			mysql)
				local password
				password=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')
				[ -n "$password" ] && version=$(docker exec mysql mysql -u root -p"$password" -Nse 'SELECT VERSION();' 2>/dev/null)
				;;
		esac
	fi
	printf '{"name":"%s","required":%s,"exists":%s,"running":%s,"state":"%s","image":"%s","version":"%s","repoDigest":"%s","updateStatus":"unknown","updateReason":"Registry 状态仅在更新任务中实时确认"}' \
		"$name" "$required" "$exists" "$running" "$(kpanel_ldnmp_escape "$state")" \
		"$(kpanel_ldnmp_escape "$image")" "$(kpanel_ldnmp_escape "$version")" "$(kpanel_ldnmp_escape "$digest")"
}

ldnmp_environment_status() {
	local count=0 running=0 state=absent profile=none health=unknown
	for name in nginx mysql php redis; do
		docker inspect "$name" >/dev/null 2>&1 && count=$((count + 1))
		[ "$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null)" = true ] && running=$((running + 1))
	done
	if [ "$count" -eq 4 ]; then state=installed; profile=full
	elif [ "$count" -eq 1 ] && docker inspect nginx >/dev/null 2>&1; then state=installed; profile=nginx
	elif [ "$count" -gt 0 ] || [ -d /home/web ]; then state=partial; profile=custom
	fi
	if { [ "$profile" = full ] && [ "$running" -eq 4 ]; } ||
		{ [ "$profile" = nginx ] && [ "$running" -eq 1 ]; }; then health=healthy
	elif [ "$state" != absent ]; then health=degraded
	fi

	local compose=false nginx_ok=false sites=0 databases=0 certificates=0 bytes=0
	[ -f /home/web/docker-compose.yml ] &&
		docker compose -f /home/web/docker-compose.yml config -q >/dev/null 2>&1 && compose=true
	docker exec nginx nginx -t >/dev/null 2>&1 && nginx_ok=true
	[ -d /home/web/conf.d ] && sites=$(find /home/web/conf.d -maxdepth 1 -type f -name '*.conf' ! -name default.conf ! -name map.conf 2>/dev/null | wc -l)
	[ -d /home/web/certs ] && certificates=$(find /home/web/certs -maxdepth 1 -type f -name '*_cert.pem' 2>/dev/null | wc -l)
	if docker inspect mysql >/dev/null 2>&1; then
		local password
		password=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')
		[ -n "$password" ] && databases=$(docker exec mysql mysql -u root -p"$password" -Nse 'SHOW DATABASES;' 2>/dev/null |
			grep -Ev '^(information_schema|mysql|performance_schema|sys)$' | wc -l)
	fi
	[ -d /home/web ] && bytes=$(du -sb /home/web 2>/dev/null | awk '{print $1}')
	local resource=""
	command -v sha256sum >/dev/null 2>&1 && resource=$(
		{ [ -f /home/web/docker-compose.yml ] && sha256sum /home/web/docker-compose.yml
		  [ -f /home/web/nginx.conf ] && sha256sum /home/web/nginx.conf
		  docker inspect -f '{{.Id}} {{.Image}} {{.State.Status}}' nginx mysql php php74 redis 2>/dev/null; } |
			sha256sum | awk '{print $1}'
	)
	local fail2ban=false waf=false cloudflare=false ddos=false mode=custom gzip=false brotli=false zstd=false
	command -v fail2ban-client >/dev/null 2>&1 && fail2ban=true
	grep -qE '^[[:space:]]*modsecurity on;' /home/web/nginx.conf 2>/dev/null && waf=true
	[ -f /etc/fail2ban/action.d/cloudflare-docker.conf ] && cloudflare=true
	iptables -C INPUT -p tcp --syn -j DROP >/dev/null 2>&1 && ddos=true
	docker exec mysql grep -q 4096M /etc/mysql/conf.d/custom_mysql_config.cnf 2>/dev/null && mode=high
	[ "$mode" = custom ] && docker exec mysql test -f /etc/mysql/conf.d/custom_mysql_config.cnf >/dev/null 2>&1 && mode=standard
	grep -qE '^[[:space:]]*gzip[[:space:]]+on;' /home/web/nginx.conf 2>/dev/null && gzip=true
	grep -qE '^[[:space:]]*brotli[[:space:]]+on;' /home/web/nginx.conf 2>/dev/null && brotli=true
	grep -qE '^[[:space:]]*zstd[[:space:]]+on;' /home/web/nginx.conf 2>/dev/null && zstd=true
	local latest=""
	latest=$(find /home -maxdepth 1 -type f -name 'web_*.tar.gz' -printf '%f\n' 2>/dev/null | sort -r | head -1)
	local port_conflicts="" separator="" port listener
	for port in 80 443; do
		listener=$(ss -ltnp 2>/dev/null | awk -v suffix=":${port}" '$4 ~ suffix"$" {print; exit}')
		if [ -n "$listener" ]; then
			port_conflicts="${port_conflicts}${separator}\"$(kpanel_ldnmp_escape "$listener")\""
			separator=","
		fi
	done
	printf '{"protocolVersion":"1","state":"%s","profile":"%s","health":"%s","webRoot":"/home/web","diskBytes":%s,"siteCount":%s,"databaseCount":%s,"certificateCount":%s,"composeValid":%s,"nginxValid":%s,"resourceVersion":"%s","scriptVersion":"%s","latestBackup":"%s","portConflicts":[%s],"components":[' \
		"$state" "$profile" "$health" "${bytes:-0}" "${sites:-0}" "${databases:-0}" "${certificates:-0}" \
		"$compose" "$nginx_ok" "$resource" "$sh_v" "$(kpanel_ldnmp_escape "$latest")" "$port_conflicts"
	kpanel_ldnmp_component nginx true; printf ','; kpanel_ldnmp_component mysql true; printf ','
	kpanel_ldnmp_component php true; printf ','; kpanel_ldnmp_component php74 false; printf ','
	kpanel_ldnmp_component redis true
	printf '],"protection":{"fail2ban":%s,"waf":%s,"cloudflare":%s,"ddos":%s},"optimization":{"mode":"%s","gzip":%s,"brotli":%s,"zstd":%s},"observedAt":"%s"}\n' \
		"$fail2ban" "$waf" "$cloudflare" "$ddos" "$mode" "$gzip" "$brotli" "$zstd" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}

ldnmp_environment_catalog() {
	printf '%s\n' '{"protocolVersion":"1","installProfiles":[{"id":"full","label":"完整 LDNMP"},{"id":"nginx","label":"仅 Nginx"}],"protectionActions":["fail2ban-install","fail2ban-uninstall","unban-all","waf-on","waf-off","ddos-on","ddos-off","cloudflare-fail2ban","cloudflare-shield"],"optimizationActions":["standard","high","gzip-on","gzip-off","brotli-on","brotli-off","zstd-on","zstd-off"],"updateComponents":[{"id":"nginx","versions":["latest"]},{"id":"mysql","versions":["latest","8.0","8.3","8.4","9.0"]},{"id":"php","versions":["7.4","8.0","8.1","8.2","8.3"]},{"id":"redis","versions":["latest"]},{"id":"all","versions":["latest"]}]}'
}

ldnmp_environment_install() {
	local profile="${1:-full}" states
	kpanel_ldnmp_event preflight 5 "正在检查安装条件"
	case "$profile" in
		full) kpanel_ldnmp_event install 15 "正在安装完整 LDNMP"; ldnmp_install_all ;;
		nginx) kpanel_ldnmp_event install 15 "正在安装 Nginx"; nginx_install_all ;;
		*) echo "不支持的安装形态" >&2; return 2 ;;
	esac
	kpanel_ldnmp_event verify 90 "正在验证环境"
	docker exec nginx nginx -t >/dev/null 2>&1 || return 1
	docker compose -f /home/web/docker-compose.yml config -q || return 1
	if [ "$profile" = full ]; then
		states=$(docker inspect -f '{{.State.Running}}' nginx mysql php redis 2>/dev/null)
		[ "$(printf '%s\n' "$states" | sed '/^$/d' | wc -l)" -eq 4 ] || return 1
		printf '%s\n' "$states" | grep -qv true && return 1
	fi
}

ldnmp_protection_action_apply() {
	local cfuser="" cftoken="" cfzone="" secret_content=""
	case "$1" in
		fail2ban-install)
			f2b_install_sshd
			mkdir -p /etc/fail2ban/filter.d /etc/fail2ban/jail.d
			curl -sS -o /etc/fail2ban/filter.d/fail2ban-nginx-cc.conf "${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/fail2ban-nginx-cc.conf"
			curl -sS -o /etc/fail2ban/jail.d/nginx-docker-cc.conf "${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf"
			sed -i '/cloudflare/d' /etc/fail2ban/jail.d/nginx-docker-cc.conf
			fail2ban-client reload ;;
		fail2ban-uninstall) remove fail2ban; rm -rf /etc/fail2ban ;;
		unban-all) fail2ban-client unban --all ;;
		waf-on) nginx_waf on ;; waf-off) nginx_waf off ;;
		ddos-on) enable_ddos_defense ;; ddos-off) disable_ddos_defense ;;
		cloudflare-fail2ban|cloudflare-shield)
			case "${KJ_LDNMP_SECRET_FILE:-}" in
				/var/lib/kejilion-panel/environment-jobs/*.secret) ;;
				*) echo "Cloudflare 凭据通道无效" >&2; return 2 ;;
			esac
			[ -f "$KJ_LDNMP_SECRET_FILE" ] && [ ! -L "$KJ_LDNMP_SECRET_FILE" ] || return 2
			IFS= read -r cfuser < "$KJ_LDNMP_SECRET_FILE"
			cftoken=$(sed -n '2p' "$KJ_LDNMP_SECRET_FILE")
			cfzone=$(sed -n '3p' "$KJ_LDNMP_SECRET_FILE")
			rm -f -- "$KJ_LDNMP_SECRET_FILE"
			[ -n "$cfuser" ] && [ -n "$cftoken" ] || return 2
			if [ "$1" = cloudflare-fail2ban ]; then
				wget -O /home/web/conf.d/default.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf"
				docker exec nginx nginx -s reload
				mkdir -p /etc/fail2ban/jail.d /etc/fail2ban/action.d
				curl -sS -o /etc/fail2ban/jail.d/nginx-docker-cc.conf \
					"${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf"
				curl -sS -o /etc/fail2ban/action.d/cloudflare-docker.conf \
					"${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf"
				secret_content=$(< /etc/fail2ban/action.d/cloudflare-docker.conf)
				secret_content=${secret_content//kejilion@outlook.com/$cfuser}
				secret_content=${secret_content//APIKEY00000/$cftoken}
				printf '%s\n' "$secret_content" > /etc/fail2ban/action.d/cloudflare-docker.conf
				chmod 600 /etc/fail2ban/action.d/cloudflare-docker.conf
				f2b_status
			else
				[ -n "$cfzone" ] || return 2
				cd /root || return 1
				install jq bc
				check_crontab_installed
				curl -sS -o CF-Under-Attack.sh "${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/CF-Under-Attack.sh"
				chmod 700 CF-Under-Attack.sh
				secret_content=$(< CF-Under-Attack.sh)
				secret_content=${secret_content//AAAA/$cfuser}
				secret_content=${secret_content//BBBB/$cftoken}
				secret_content=${secret_content//CCCC/$cfzone}
				printf '%s\n' "$secret_content" > CF-Under-Attack.sh
				local cron_job="*/5 * * * * /root/CF-Under-Attack.sh"
				(crontab -l 2>/dev/null | grep -Fv "/root/CF-Under-Attack.sh"; echo "$cron_job") | crontab -
			fi
			;;
		*) echo "不支持的防护动作" >&2; return 2 ;;
	esac
}

ldnmp_protection_action() {
	local action="$1" snapshot rc=0 fail2ban_existed=false
	snapshot=$(mktemp -d /home/.kpanel-ldnmp-protection.XXXXXX) || return 1
	if [ -d /etc/fail2ban ]; then
		cp -a /etc/fail2ban "$snapshot/fail2ban"
		fail2ban_existed=true
	fi
	cp -a /home/web/nginx.conf "$snapshot/nginx.conf" 2>/dev/null || true
	cp -a /home/web/conf.d/default.conf "$snapshot/default.conf" 2>/dev/null || true
	crontab -l > "$snapshot/crontab" 2>/dev/null || true
	iptables-save > "$snapshot/iptables.rules" 2>/dev/null || true

	ldnmp_protection_action_apply "$@"
	rc=$?
	case "$action" in
		fail2ban-install|cloudflare-fail2ban)
			fail2ban-client ping >/dev/null 2>&1 || rc=1
			;;
		waf-on|waf-off)
			docker exec nginx nginx -t >/dev/null 2>&1 || rc=1
			;;
		cloudflare-shield)
			crontab -l 2>/dev/null | grep -Fq "/root/CF-Under-Attack.sh" || rc=1
			;;
	esac
	if [ "$rc" -eq 0 ]; then
		rm -rf "$snapshot"
		return 0
	fi

	kpanel_ldnmp_event rollback 85 "防护配置验证失败，正在恢复原配置"
	rm -rf /etc/fail2ban
	[ "$fail2ban_existed" = true ] && cp -a "$snapshot/fail2ban" /etc/fail2ban
	[ -f "$snapshot/nginx.conf" ] && cp -a "$snapshot/nginx.conf" /home/web/nginx.conf
	[ -f "$snapshot/default.conf" ] && cp -a "$snapshot/default.conf" /home/web/conf.d/default.conf
	if [ -s "$snapshot/crontab" ]; then crontab "$snapshot/crontab"; else crontab -r 2>/dev/null; fi
	[ -s "$snapshot/iptables.rules" ] && iptables-restore < "$snapshot/iptables.rules"
	docker exec nginx nginx -t >/dev/null 2>&1 && docker exec nginx nginx -s reload >/dev/null 2>&1
	systemctl restart fail2ban >/dev/null 2>&1 || true
	rm -rf "$snapshot"
	return "$rc"
}

ldnmp_optimization_action() {
	local action="$1" snapshot rc=0 sysctl_existed=false
	snapshot=$(mktemp -d /home/.kpanel-ldnmp-optimize.XXXXXX) || return 1
	cp -a /home/web/nginx.conf "$snapshot/nginx.conf" 2>/dev/null || true
	docker cp php:/usr/local/etc/php/conf.d/optimized_php.ini "$snapshot/php.ini" 2>/dev/null || true
	docker cp php:/usr/local/etc/php-fpm.d/www.conf "$snapshot/php-www.conf" 2>/dev/null || true
	docker cp php74:/usr/local/etc/php/conf.d/optimized_php.ini "$snapshot/php74.ini" 2>/dev/null || true
	docker cp php74:/usr/local/etc/php-fpm.d/www.conf "$snapshot/php74-www.conf" 2>/dev/null || true
	docker cp mysql:/etc/mysql/conf.d/custom_mysql_config.cnf "$snapshot/mysql.cnf" 2>/dev/null || true
	if [ -f /etc/sysctl.d/99-kejilion-optimize.conf ]; then
		cp -a /etc/sysctl.d/99-kejilion-optimize.conf "$snapshot/sysctl.conf"
		sysctl_existed=true
	fi
	case "$1" in
		standard) ldnmp_optimization_mode standard ;;
		high) ldnmp_optimization_mode high ;;
		gzip-on) nginx_gzip on ;; gzip-off) nginx_gzip off ;;
		brotli-on) nginx_br on ;; brotli-off) nginx_br off ;;
		zstd-on) nginx_zstd on ;; zstd-off) nginx_zstd off ;;
		*) rm -rf "$snapshot"; echo "当前协议不支持该优化动作" >&2; return 2 ;;
	esac
	rc=$?
	docker exec nginx nginx -t >/dev/null 2>&1 || rc=1
	if [ "$action" = standard ] || [ "$action" = high ]; then
		local component_states
		component_states=$(docker inspect -f '{{.State.Running}}' nginx php mysql redis 2>/dev/null)
		[ "$(printf '%s\n' "$component_states" | sed '/^$/d' | wc -l)" -eq 4 ] || rc=1
		printf '%s\n' "$component_states" | grep -qv true && rc=1
	fi
	if [ "$rc" -eq 0 ]; then
		rm -rf "$snapshot"
		return 0
	fi
	kpanel_ldnmp_event rollback 85 "优化验证失败，正在恢复原配置"
	[ -f "$snapshot/nginx.conf" ] && cp -a "$snapshot/nginx.conf" /home/web/nginx.conf
	[ -f "$snapshot/php.ini" ] && docker cp "$snapshot/php.ini" php:/usr/local/etc/php/conf.d/optimized_php.ini
	[ -f "$snapshot/php-www.conf" ] && docker cp "$snapshot/php-www.conf" php:/usr/local/etc/php-fpm.d/www.conf
	[ -f "$snapshot/php74.ini" ] && docker cp "$snapshot/php74.ini" php74:/usr/local/etc/php/conf.d/optimized_php.ini
	[ -f "$snapshot/php74-www.conf" ] && docker cp "$snapshot/php74-www.conf" php74:/usr/local/etc/php-fpm.d/www.conf
	[ -f "$snapshot/mysql.cnf" ] && docker cp "$snapshot/mysql.cnf" mysql:/etc/mysql/conf.d/custom_mysql_config.cnf
	if [ "$sysctl_existed" = true ]; then
		cp -a "$snapshot/sysctl.conf" /etc/sysctl.d/99-kejilion-optimize.conf
	else
		rm -f /etc/sysctl.d/99-kejilion-optimize.conf
	fi
	sysctl --system >/dev/null 2>&1
	cd /home/web && docker compose restart >/dev/null 2>&1
	rm -rf "$snapshot"
	return "$rc"
}

ldnmp_update_action() {
	local component="$1" version="${2:-latest}" backup_before="${3:-false}" rc
	if [ "$backup_before" = true ]; then
		kpanel_ldnmp_event update_backup 5 "正在创建更新前冷备"
		ldnmp_backup_action || return 1
	fi
	case "$component" in
		nginx) nginx_upgrade ;;
		redis) cd /home/web && docker compose pull redis && docker compose up -d --force-recreate redis ;;
		mysql)
			printf '%s' "$version" | grep -Eq '^(latest|8\.0|8\.3|8\.4|9\.0)$' || return 2
			cd /home/web || return 1; cp docker-compose.yml docker-compose.yml.kpanel-update
			sed -E -i "s#image:[[:space:]]*mysql([^[:space:]]*)#image: mysql:${version}#" docker-compose.yml
			if docker compose pull mysql && docker compose up -d --force-recreate mysql; then
				rm -f docker-compose.yml.kpanel-update
				return 0
			else
				rc=$?
			fi
			mv -f docker-compose.yml.kpanel-update docker-compose.yml
			docker compose up -d --force-recreate mysql >/dev/null 2>&1 || return 86
			return "$rc" ;;
		php)
			printf '%s' "$version" | grep -Eq '^(7\.4|8\.0|8\.1|8\.2|8\.3)$' || return 2
			cd /home/web || return 1; cp docker-compose.yml docker-compose.yml.kpanel-update
			sed -E -i "s#image:[[:space:]]*(kjlion/)?php:fpm-alpine#image: php:${version}-fpm-alpine#" docker-compose.yml
			if docker compose pull php && docker compose up -d --force-recreate php; then
				rm -f docker-compose.yml.kpanel-update
				fix_phpfpm_conf php
				return 0
			else
				rc=$?
			fi
			mv -f docker-compose.yml.kpanel-update docker-compose.yml
			docker compose up -d --force-recreate php >/dev/null 2>&1 || return 86
			return "$rc" ;;
		all)
			cd /home/web || return 1
			docker compose pull && docker compose up -d --force-recreate || return 86
			;;
		*) echo "不支持的更新组件" >&2; return 2 ;;
	esac
}

ldnmp_backup_action() {
	[ -d /home/web ] || return 1
	local stamp archive tmp checksum source_bytes free_bytes running_services
	stamp=$(date '+%Y%m%d%H%M%S'); archive="/home/web_${stamp}.tar.gz"; tmp="${archive}.tmp.$$"
	source_bytes=$(du -sb /home/web 2>/dev/null | awk '{print $1}')
	free_bytes=$(df -PB1 /home | awk 'NR==2 {print $4}')
	[ "${source_bytes:-0}" -le $((free_bytes * 8 / 10)) ] || return 1
	kpanel_ldnmp_event backup_stop 15 "正在短暂停止 LDNMP"
	cd /home/web || return 1
	running_services=$(docker compose ps --services --filter status=running 2>/dev/null | tr '\n' ' ')
	docker compose stop || return 1
	kpanel_ldnmp_event backup_archive 45 "正在归档 /home/web"
	if ! tar -C /home -czf "$tmp" web; then
		[ -n "$running_services" ] && docker compose start $running_services >/dev/null 2>&1
		rm -f "$tmp"
		return 1
	fi
	chmod 600 "$tmp"; checksum=$(sha256sum "$tmp" | awk '{print $1}'); mv -f "$tmp" "$archive"
	umask 077
	printf '{"format":"kejilion-ldnmp-v1","file":"%s","sha256":"%s","createdAt":"%s","scriptVersion":"%s"}\n' \
		"$(basename "$archive")" "$checksum" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$sh_v" > "${archive}.kpanel.json"
	kpanel_ldnmp_event backup_start 80 "正在恢复 LDNMP"
	[ -z "$running_services" ] || docker compose start $running_services
	printf 'KPANEL_LDNMP_BACKUP %s\n' "$(basename "$archive")"
}

ldnmp_backup_delete_action() {
	local name archive
	name=$(basename "${1:-}")
	printf '%s' "$name" | grep -Eq '^web_[0-9]{14}\.tar\.gz$' || return 2
	archive="/home/$name"
	[ -f "$archive" ] && [ ! -L "$archive" ] || return 1
	rm -f -- "$archive" "${archive}.kpanel.json"
}

ldnmp_restore_action() {
	local name archive stage rollback expected actual entry_count unpacked_bytes free_bytes old_running_services
	name=$(basename "${1:-}"); printf '%s' "$name" | grep -Eq '^web_[0-9]{14}\.tar\.gz$' || return 2
	archive="/home/$name"; [ -f "$archive" ] || return 1
	gzip -t "$archive" || return 1
	if [ -f "${archive}.kpanel.json" ]; then
		expected=$(sed -n 's/.*"sha256":"\([a-f0-9]\{64\}\)".*/\1/p' "${archive}.kpanel.json")
		actual=$(sha256sum "$archive" | awk '{print $1}')
		[ -n "$expected" ] && [ "$expected" = "$actual" ] || return 1
	fi
	kpanel_ldnmp_event restore_scan 15 "正在扫描备份归档"
	entry_count=$(tar -tzf "$archive" | wc -l)
	[ "$entry_count" -le 200000 ] || return 1
	unpacked_bytes=$(tar -tvzf "$archive" | awk '{total += $3} END {printf "%.0f", total}')
	free_bytes=$(df -PB1 /home | awk 'NR==2 {print $4}')
	[ "${unpacked_bytes:-0}" -le $((free_bytes * 8 / 10)) ] || return 1
	tar -tzf "$archive" | grep -Ev '^web(/|$)' | grep -q . && return 1
	tar -tzf "$archive" | grep -Eq '(^/|(^|/)\.\.(/|$))' && return 1
	tar -tvzf "$archive" | awk '$1 ~ /^[lhbcp]/ { exit 0 } END { exit 1 }' && return 1
	stage=$(mktemp -d /home/.kpanel-ldnmp-restore.XXXXXX) || return 1
	rollback="/home/.kpanel-ldnmp-rollback.$(date '+%Y%m%d%H%M%S')"
	kpanel_ldnmp_event restore_extract 35 "正在解压到安全暂存目录"
	tar -xzf "$archive" -C "$stage" || { rm -rf "$stage"; return 1; }
	docker compose -f "$stage/web/docker-compose.yml" config -q || { rm -rf "$stage"; return 1; }
	kpanel_ldnmp_event restore_switch 60 "正在原子切换 /home/web"
	if [ -d /home/web ]; then
		cd /home/web || return 1
		old_running_services=$(docker compose ps --services --filter status=running 2>/dev/null | tr '\n' ' ')
		docker compose down
		mv /home/web "$rollback"
	fi
	if ! mv "$stage/web" /home/web; then
		[ -d "$rollback" ] && mv "$rollback" /home/web
		if [ -d /home/web ] && [ -n "$old_running_services" ]; then
			cd /home/web && docker compose up -d $old_running_services >/dev/null 2>&1
		fi
		return 1
	fi
	rm -rf "$stage"; cd /home/web || return 1
	if docker compose up -d && docker exec nginx nginx -t >/dev/null 2>&1; then rm -rf "$rollback"; return 0; fi
	docker compose down >/dev/null 2>&1; rm -rf /home/web
	[ -d "$rollback" ] && mv "$rollback" /home/web
	cd /home/web || return 1
	if [ -n "$old_running_services" ]; then
		docker compose up -d $old_running_services >/dev/null 2>&1 || return 86
	fi
	return 1
}

ldnmp_uninstall_action() {
	[ "${1:-false}" = true ] && ldnmp_backup_action
	if [ -d /home/web ]; then
		cd /home/web || return 1
		docker compose down --rmi all
		[ -f docker-compose.phpmyadmin.yml ] && docker compose -f docker-compose.phpmyadmin.yml down --rmi all >/dev/null 2>&1
		rm -rf /home/web
	fi
}

kpanel_ldnmp_run() {
	local action="$1" function_name="$2"; shift 2
	mkdir -p /run/lock
	local lock_fd rc
	exec {lock_fd}>/run/lock/kejilion-web-environment.lock
	if ! flock -n "$lock_fd"; then
		kpanel_ldnmp_result failed "$action" "已有网站或 LDNMP 环境任务正在执行"
		exec {lock_fd}>&-
		return 75
	fi
	kpanel_ldnmp_event start 1 "LDNMP 环境任务已启动"
	if "$function_name" "$@"; then
		kpanel_ldnmp_event complete 100 "LDNMP 环境任务已完成"
		kpanel_ldnmp_result succeeded "$action" "任务执行成功"
		rc=0
	else
		rc=$?
		kpanel_ldnmp_event failed 100 "LDNMP 环境任务执行失败"
		if [ "$rc" -eq 86 ]; then
			kpanel_ldnmp_result needs_attention "$action" "任务失败且无法确认安全回滚，需要人工处理"
		else
			kpanel_ldnmp_result failed "$action" "任务执行失败"
		fi
	fi
	flock -u "$lock_fd"
	exec {lock_fd}>&-
	return "$rc"
}

ldnmp_environment_menu() {
	while true; do
		clear
		echo "LDNMP 环境管理"
		echo "------------------------"
		echo "1. 查看环境状态"
		echo "2. 安装完整 LDNMP"
		echo "3. 仅安装 Nginx"
		echo "4. 防护管理"
		echo "5. 优化管理"
		echo "6. 更新环境"
		echo "7. 创建冷备"
		echo "8. 还原备份"
		echo "9. 卸载环境"
		echo "0. 返回"
		echo "------------------------"
		read -e -p "请输入你的选择: " choice
		case "$choice" in
			1)
				ldnmp_tato
				docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null
				;;
			2) ldnmp_environment_install full ;;
			3) ldnmp_environment_install nginx ;;
			4) web_security ;;
			5) web_optimization ;;
			6)
				read -e -p "更新组件 (nginx/mysql/php/redis/all): " component
				read -e -p "目标版本（默认 latest）: " version
				ldnmp_update_action "$component" "${version:-latest}" false
				;;
			7) ldnmp_backup_action ;;
			8)
				find /home -maxdepth 1 -type f -name 'web_*.tar.gz' -printf '%f\n' 2>/dev/null | sort -r
				read -e -p "输入要还原的备份文件名: " backup_name
				ldnmp_restore_action "$backup_name"
				;;
			9)
				read -e -p "输入 DELETE 确认卸载 LDNMP 环境: " confirmation
				[ "$confirmation" = DELETE ] && ldnmp_uninstall_action true
				;;
			0) return 0 ;;
			*) echo "无效的输入" ;;
		esac
		break_end
	done
}

kpanel_ldnmp_dispatch() {
	local command="${1:-}"; shift || true
	if [ -z "$command" ] && [ "${KJ_LDNMP_NONINTERACTIVE:-0}" != "1" ] &&
		[ "${KJ_LDNMP_PROTOCOL:-0}" != "1" ]; then
		ldnmp_environment_menu
		return
	fi
	printf 'KPANEL_LDNMP_PROTOCOL 1\n'
	case "$command" in
		status) ldnmp_environment_status ;;
		catalog) ldnmp_environment_catalog ;;
		install) kpanel_ldnmp_run install ldnmp_environment_install "$@" ;;
		protect) kpanel_ldnmp_run protect ldnmp_protection_action "$@" ;;
		optimize) kpanel_ldnmp_run optimize ldnmp_optimization_action "$@" ;;
		update) kpanel_ldnmp_run update ldnmp_update_action "$@" ;;
		backup)
			if [ "${1:-create}" = delete ]; then
				shift
				kpanel_ldnmp_run backup.delete ldnmp_backup_delete_action "$@"
			else
				kpanel_ldnmp_run backup.create ldnmp_backup_action "$@"
			fi
			;;
		restore) kpanel_ldnmp_run restore ldnmp_restore_action "$@" ;;
		uninstall) kpanel_ldnmp_run uninstall ldnmp_uninstall_action "$@" ;;
		*) echo "不支持的 LDNMP 环境命令" >&2; return 2 ;;
	esac
}


linux_ldnmp() {
  while true; do

	if [ "${KJ_WEB_NONINTERACTIVE:-0}" != "1" ]; then
	clear
	# send_stats "LDNMP建站"
	echo -e "${gl_huang}LDNMP建站"
	ldnmp_tato
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}1.   ${gl_bai}安装LDNMP环境 ${gl_huang}★${gl_bai}                   ${gl_huang}2.   ${gl_bai}安装WordPress ${gl_huang}★${gl_bai}"
	echo -e "${gl_huang}3.   ${gl_bai}安装Discuz论坛                    ${gl_huang}4.   ${gl_bai}安装可道云桌面"
	echo -e "${gl_huang}5.   ${gl_bai}安装苹果CMS影视站                 ${gl_huang}6.   ${gl_bai}安装独角数发卡网"
	echo -e "${gl_huang}7.   ${gl_bai}安装flarum论坛网站                ${gl_huang}8.   ${gl_bai}安装typecho轻量博客网站"
	echo -e "${gl_huang}9.   ${gl_bai}安装LinkStack共享链接平台         ${gl_huang}20.  ${gl_bai}自定义动态站点"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}21.  ${gl_bai}仅安装nginx ${gl_huang}★${gl_bai}                     ${gl_huang}22.  ${gl_bai}站点重定向"
	echo -e "${gl_huang}23.  ${gl_bai}站点反向代理-IP+端口 ${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}站点反向代理-域名"
	echo -e "${gl_huang}25.  ${gl_bai}安装Bitwarden密码管理平台         ${gl_huang}26.  ${gl_bai}安装Halo博客网站"
	echo -e "${gl_huang}27.  ${gl_bai}安装AI绘画提示词生成器            ${gl_huang}28.  ${gl_bai}站点反向代理-负载均衡"
	echo -e "${gl_huang}29.  ${gl_bai}Stream四层代理转发                ${gl_huang}30.  ${gl_bai}自定义静态站点"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}31.  ${gl_bai}站点数据管理 ${gl_huang}★${gl_bai}                    ${gl_huang}32.  ${gl_bai}备份全站数据"
	echo -e "${gl_huang}33.  ${gl_bai}定时远程备份                      ${gl_huang}34.  ${gl_bai}还原全站数据"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}35.  ${gl_bai}防护LDNMP环境                     ${gl_huang}36.  ${gl_bai}优化LDNMP环境"
	echo -e "${gl_huang}37.  ${gl_bai}更新LDNMP环境                     ${gl_huang}38.  ${gl_bai}卸载LDNMP环境"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}0.   ${gl_bai}返回主菜单"
	echo -e "${gl_huang}------------------------${gl_bai}"
	fi
	if [ "${KJ_WEB_NONINTERACTIVE:-0}" = "1" ]; then
		sub_choice="${KJ_WEB_RECIPE:-}"
		case "$sub_choice" in
			2|3|4|5|6|7|8|9|20|22|23|24|25|26|27|28|30) ;;
			*)
				echo "KPANEL_PROGRESS 100 不支持的 KJ_WEB_RECIPE"
				return 1
				;;
		esac
		if [ -z "${KJ_WEB_DOMAIN:-}" ] || [ ${#KJ_WEB_DOMAIN} -gt 253 ] ||
			! printf '%s' "$KJ_WEB_DOMAIN" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$'; then
			echo "KPANEL_PROGRESS 100 KJ_WEB_DOMAIN 不是有效的域名"
			return 1
		fi
		if [ -e "/home/web/conf.d/${KJ_WEB_DOMAIN}.conf" ] ||
			[ -e "/home/web/html/${KJ_WEB_DOMAIN}" ]; then
			echo "KPANEL_PROGRESS 100 域名已存在，拒绝覆盖现有产物"
			return 1
		fi
		if [ "$sub_choice" = "23" ]; then
			if [ -z "${KJ_WEB_PROXY_HOST:-}" ] ||
				! printf '%s' "$KJ_WEB_PROXY_HOST" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$'; then
				echo "KPANEL_PROGRESS 100 KJ_WEB_PROXY_HOST 不是有效的 IP 或主机名"
				return 1
			fi
			if ! printf '%s' "${KJ_WEB_PROXY_PORT:-}" | grep -Eq '^[0-9]{1,5}$' ||
				[ "$KJ_WEB_PROXY_PORT" -lt 1 ] || [ "$KJ_WEB_PROXY_PORT" -gt 65535 ]; then
				echo "KPANEL_PROGRESS 100 KJ_WEB_PROXY_PORT 不是有效端口"
				return 1
			fi
		fi
		echo "KPANEL_PROGRESS 5 正在启动 kejilion.sh 原生一键建站流程"
	else
		read -e -p "请输入你的选择: " sub_choice
	fi


	case $sub_choice in
	  1)
	  ldnmp_install_status_one
	  ldnmp_install_all
		;;
	  2)
	  ldnmp_wp "${KJ_WEB_DOMAIN:-}"
		;;

	  3)
	  clear
	  # Discuz论坛
	  webname="Discuz论坛"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status


	  install_ssltls
	  certs_status
	  add_db


	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/discuz.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  nginx_http_on

	  cd /home/web/html
	  prepare_ldnmp_site_root "$yuming" || return 1
	  cd $yuming
	  LATEST_URL=$(curl -s https://api.gitee.com/api/v5/repos/Discuz/DiscuzX/releases/latest | grep -o 'https://[^"]*Discuz_X[^"]*SC_UTF8[^"]*\.zip' | head -n 1)
	  wget -O latest.zip ${LATEST_URL}
	  unzip -q latest.zip
	  mv upload/* .
	  rm -rf upload readme readme.html utility.html LICENSE qqqun.png
	  rm latest.zip

	  normalize_ldnmp_site_permissions "$yuming" || return 1
	  restart_ldnmp


	  ldnmp_web_on
	  echo "数据库地址: mysql"
	  echo "数据库名: $dbname"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
	  echo "表前缀: discuz_"


		;;

	  4)
	  clear
	  # 可道云桌面
	  webname="可道云桌面"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status

	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/kdy.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  nginx_http_on

	  cd /home/web/html
	  prepare_ldnmp_site_root "$yuming" || return 1
	  cd $yuming
	  LATEST_VERSION=$(curl -s https://api.github.com/repos/kalcaddle/kodbox/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
	  wget -O latest.zip ${gh_proxy}github.com/kalcaddle/kodbox/archive/refs/tags/${LATEST_VERSION}.zip
	  unzip -o latest.zip
	  rm latest.zip
	  mv /home/web/html/$yuming/kodbox* /home/web/html/$yuming/kodbox
	  normalize_ldnmp_site_permissions "$yuming" || return 1
	  restart_ldnmp

	  ldnmp_web_on
	  echo "数据库地址: mysql"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
	  echo "数据库名: $dbname"
	  echo "redis主机: redis"

		;;

	  5)
	  clear
	  # 苹果CMS
	  webname="苹果CMS"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status



	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/maccms.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  nginx_http_on

	  cd /home/web/html
	  prepare_ldnmp_site_root "$yuming" || return 1
	  cd $yuming
	  # wget ${gh_proxy}github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && rm maccms10.zip
	  wget ${gh_proxy}github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && mv maccms10-*/* . && rm -r maccms10-* && rm maccms10.zip
	  cd /home/web/html/$yuming/template/ && wget ${gh_proxy}github.com/kejilion/Website_source_code/raw/main/DYXS2.zip && unzip DYXS2.zip && rm /home/web/html/$yuming/template/DYXS2.zip
	  cp /home/web/html/$yuming/template/DYXS2/asset/admin/Dyxs2.php /home/web/html/$yuming/application/admin/controller
	  cp /home/web/html/$yuming/template/DYXS2/asset/admin/dycms.html /home/web/html/$yuming/application/admin/view/system
	  mv /home/web/html/$yuming/admin.php /home/web/html/$yuming/vip.php && wget -O /home/web/html/$yuming/application/extra/maccms.php ${gh_proxy}raw.githubusercontent.com/kejilion/Website_source_code/main/maccms.php

	  normalize_ldnmp_site_permissions "$yuming" || return 1
	  restart_ldnmp


	  ldnmp_web_on
	  echo "数据库地址: mysql"
	  echo "数据库端口: 3306"
	  echo "数据库名: $dbname"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
	  echo "数据库前缀: mac_"
	  echo "------------------------"
	  echo "安装成功后登录后台地址"
	  echo "https://$yuming/vip.php"

		;;

	  6)
	  clear
	  # 独脚数卡
	  webname="独脚数卡"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status



	  install_ssltls
	  certs_status
	  add_db


	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/dujiaoka.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  nginx_http_on

	  cd /home/web/html
	  prepare_ldnmp_site_root "$yuming" || return 1
	  cd $yuming
	  wget ${gh_proxy}github.com/assimon/dujiaoka/releases/download/2.0.6/2.0.6-antibody.tar.gz && tar -zxvf 2.0.6-antibody.tar.gz && rm 2.0.6-antibody.tar.gz

	  normalize_ldnmp_site_permissions "$yuming" || return 1
	  restart_ldnmp


	  ldnmp_web_on
	  echo "数据库地址: mysql"
	  echo "数据库端口: 3306"
	  echo "数据库名: $dbname"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
	  echo ""
	  echo "redis地址: redis"
	  echo "redis密码: 默认不填写"
	  echo "redis端口: 6379"
	  echo ""
	  echo "网站url: https://$yuming"
	  echo "后台登录路径: /admin"
	  echo "------------------------"
	  echo "用户名: admin"
	  echo "密码: admin"
	  echo "------------------------"
	  echo "登录时右上角如果出现红色error0请使用如下命令: "
	  echo "我也很气愤独角数卡为啥这么麻烦，会有这样的问题！"
	  echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

		;;

	  7)
	  clear
	  # flarum论坛
	  webname="flarum论坛"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status



	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/flarum.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf


	  nginx_http_on

	  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

	  cd /home/web/html
	  prepare_ldnmp_site_root "$yuming" || return 1
	  cd $yuming

	  docker exec php sh -c "php -r \"copy('https://getcomposer.org/installer', 'composer-setup.php');\""
	  docker exec php sh -c "php composer-setup.php"
	  docker exec php sh -c "php -r \"unlink('composer-setup.php');\""
	  docker exec php sh -c "mv composer.phar /usr/local/bin/composer"

	  docker exec php composer create-project flarum/flarum /var/www/html/$yuming
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require flarum-lang/chinese-simplified"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require flarum/extension-manager:*"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/polls"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/sitemap"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/oauth"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/best-answer:*"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/upload"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/gamification"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/byobu:*"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require v17development/flarum-seo"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require clarkwinkelmann/flarum-ext-emojionearea"


	  normalize_ldnmp_site_permissions "$yuming" || return 1
	  restart_ldnmp


	  ldnmp_web_on
	  echo "数据库地址: mysql"
	  echo "数据库名: $dbname"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
	  echo "表前缀: flarum_"
	  echo "管理员信息自行设置"

		;;

	  8)
	  clear
	  # typecho
	  webname="typecho"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status




	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/typecho.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  nginx_http_on

	  cd /home/web/html
	  prepare_ldnmp_site_root "$yuming" || return 1
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/typecho/typecho/releases/latest/download/typecho.zip
	  unzip latest.zip
	  rm latest.zip

	  normalize_ldnmp_site_permissions "$yuming" || return 1
	  restart_ldnmp


	  clear
	  ldnmp_web_on
	  echo "数据库前缀: typecho_"
	  echo "数据库地址: mysql"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
	  echo "数据库名: $dbname"

		;;


	  9)
	  clear
	  # LinkStack
	  webname="LinkStack"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status


	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/refs/heads/main/index_php.conf
	  sed -i "s|/var/www/html/yuming.com/|/var/www/html/yuming.com/linkstack|g" /home/web/conf.d/$yuming.conf
	  sed -i "s|yuming.com|$yuming|g" /home/web/conf.d/$yuming.conf

	  nginx_http_on

	  cd /home/web/html
	  prepare_ldnmp_site_root "$yuming" || return 1
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/linkstackorg/linkstack/releases/latest/download/linkstack.zip
	  unzip latest.zip
	  rm latest.zip

	  normalize_ldnmp_site_permissions "$yuming" || return 1
	  restart_ldnmp


	  clear
	  ldnmp_web_on
	  echo "数据库地址: mysql"
	  echo "数据库端口: 3306"
	  echo "数据库名: $dbname"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
		;;

	  20)
	  clear
	  webname="PHP动态站点"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status

	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/index_php.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  nginx_http_on

	  cd /home/web/html
	  prepare_ldnmp_site_root "$yuming" || return 1
	  cd $yuming

	  clear
	  echo -e "[${gl_huang}1/6${gl_bai}] 上传PHP源码"
	  echo "-------------"
	  echo "目前只允许上传zip格式的源码包，请将源码包放到/home/web/html/${yuming}目录下"
	  read -e -p "也可以输入下载链接，远程下载源码包，直接回车将跳过远程下载： " url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/6${gl_bai}] index.php所在路径"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.php" -print
	  find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

	  read -e -p "请输入index.php的路径，类似（/home/web/html/$yuming/wordpress/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  clear
	  echo -e "[${gl_huang}3/6${gl_bai}] 请选择PHP版本"
	  echo "-------------"
	  read -e -p "1. php最新版 | 2. php7.4 : " pho_v
	  case "$pho_v" in
		1)
		  sed -i "s#php:9000#php:9000#g" /home/web/conf.d/$yuming.conf
		  local PHP_Version="php"
		  ;;
		2)
		  sed -i "s#php:9000#php74:9000#g" /home/web/conf.d/$yuming.conf
		  local PHP_Version="php74"
		  ;;
		*)
		  echo "无效的选择，请重新输入。"
		  ;;
	  esac


	  clear
	  echo -e "[${gl_huang}4/6${gl_bai}] 安装指定扩展"
	  echo "-------------"
	  echo "已经安装的扩展"
	  docker exec php php -m

	  read -e -p "$(echo -e "输入需要安装的扩展名称，如 ${gl_huang}SourceGuardian imap ftp${gl_bai} 等等。直接回车将跳过安装 ： ")" php_extensions
	  if [ -n "$php_extensions" ]; then
		  docker exec $PHP_Version install-php-extensions $php_extensions
	  fi


	  clear
	  echo -e "[${gl_huang}5/6${gl_bai}] 编辑站点配置"
	  echo "-------------"
	  echo "按任意键继续，可以详细设置站点配置，如伪静态等内容"
	  read -n 1 -s -r -p ""
	  install nano
	  nano /home/web/conf.d/$yuming.conf


	  clear
	  echo -e "[${gl_huang}6/6${gl_bai}] 数据库管理"
	  echo "-------------"
	  read -e -p "1. 我搭建新站        2. 我搭建老站有数据库备份： " use_db
	  case $use_db in
		  1)
			  echo
			  ;;
		  2)
			  echo "数据库备份必须是.gz结尾的压缩包。请放到/home/目录下，支持宝塔/1panel备份数据导入。"
			  read -e -p "也可以输入下载链接，远程下载备份数据，直接回车将跳过远程下载： " url_download_db

			  cd /home/
			  if [ -n "$url_download_db" ]; then
				  wget "$url_download_db"
			  fi
			  gunzip $(ls -t *.gz | head -n 1)
			  latest_sql=$(ls -t *.sql | head -n 1)
			  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname < "/home/$latest_sql"
			  echo "数据库导入的表数据"
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
			  rm -f *.sql
			  echo "数据库导入完成"
			  ;;
		  *)
			  echo
			  ;;
	  esac

	  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

	  normalize_ldnmp_site_permissions "$yuming" || return 1
	  restart_ldnmp
	  ldnmp_web_on
	  prefix="web$(shuf -i 10-99 -n 1)_"
	  echo "数据库地址: mysql"
	  echo "数据库名: $dbname"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
	  echo "表前缀: $prefix"
	  echo "管理员登录信息自行设置"

		;;


	  21)
	  ldnmp_install_status_one
	  nginx_install_all
		;;

	  22)
	  clear
	  webname="站点重定向"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  read -e -p "请输入跳转域名: " reverseproxy
	  nginx_install_status



	  install_ssltls
	  certs_status


	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/rewrite.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s/baidu.com/$reverseproxy/g" /home/web/conf.d/$yuming.conf

	  nginx_http_on

	  docker exec nginx nginx -s reload

	  nginx_web_on


		;;

	  23)
	  ldnmp_Proxy "${KJ_WEB_DOMAIN:-}" "${KJ_WEB_PROXY_HOST:-}" "${KJ_WEB_PROXY_PORT:-}"
	  find_container_by_host_port "$port"
	  if [ -z "$docker_name" ]; then
		close_port "$port"
		echo "已阻止IP+端口访问该服务"
	  else
	  	ip_address
		close_port "$port"
		block_container_port "$docker_name" "$ipv4_address"
	  fi

		;;

	  24)
	  clear
	  webname="反向代理-域名"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  echo -e "域名格式: ${gl_huang}google.com${gl_bai}"
	  read -e -p "请输入你的反代域名: " fandai_yuming
	  nginx_install_status

	  install_ssltls
	  certs_status


	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-domain.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s|fandaicom|$fandai_yuming|g" /home/web/conf.d/$yuming.conf


	  nginx_http_on

	  docker exec nginx nginx -s reload

	  nginx_web_on

		;;


	  25)
	  clear
	  webname="Bitwarden"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming

	  docker run -d \
		--name bitwarden \
		--restart=always \
		-p 3280:80 \
		-v /home/web/html/$yuming/bitwarden/data:/data \
		vaultwarden/server

	  duankou=3280
	  ldnmp_Proxy ${yuming} 127.0.0.1 $duankou


		;;

	  26)
	  clear
	  webname="halo"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming

	  docker run -d --name halo --restart=always -p 8010:8090 -v /home/web/html/$yuming/.halo2:/root/.halo2 halohub/halo:2

	  duankou=8010
	  ldnmp_Proxy ${yuming} 127.0.0.1 $duankou

		;;

	  27)
	  clear
	  webname="AI绘画提示词生成器"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  nginx_install_status


	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/html.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  nginx_http_on

	  cd /home/web/html
	  prepare_ldnmp_site_root "$yuming" || return 1
	  cd $yuming

	  wget ${gh_proxy}github.com/kejilion/Website_source_code/raw/refs/heads/main/ai_prompt_generator.zip
	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  normalize_ldnmp_site_permissions "$yuming" || return 1
	  docker exec nginx nginx -s reload

	  nginx_web_on

		;;

	  28)
	  ldnmp_Proxy_backend
		;;


	  29)
	  stream_panel
		;;

	  30)
	  clear
	  webname="静态站点"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  nginx_install_status


	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/html.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  nginx_http_on

	  cd /home/web/html
	  prepare_ldnmp_site_root "$yuming" || return 1
	  cd $yuming


	  clear
	  echo -e "[${gl_huang}1/2${gl_bai}] 上传静态源码"
	  echo "-------------"
	  echo "目前只允许上传zip格式的源码包，请将源码包放到/home/web/html/${yuming}目录下"
	  read -e -p "也可以输入下载链接，远程下载源码包，直接回车将跳过远程下载： " url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/2${gl_bai}] index.html所在路径"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.html" -print
	  find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

	  read -e -p "请输入index.html的路径，类似（/home/web/html/$yuming/index/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  normalize_ldnmp_site_permissions "$yuming" || return 1
	  docker exec nginx nginx -s reload

	  nginx_web_on

		;;







	31)
	  ldnmp_web_status
	  ;;


	32)
	  clear
	  send_stats "LDNMP环境备份"

	  local backup_filename="web_$(date +"%Y%m%d%H%M%S").tar.gz"
	  echo -e "${gl_kjlan}正在备份 $backup_filename ...${gl_bai}"
	  cd /home/ && tar czvf "$backup_filename" web

	  while true; do
		clear
		echo "备份文件已创建: /home/$backup_filename"
		read -e -p "要传送备份数据到远程服务器吗？(Y/N): " choice
		case "$choice" in
		  [Yy])
			kj_ssh_read_host_port "请输入远端服务器IP:  " "目标服务器SSH端口 [默认22]: " "22"
			local remote_ip="$KJ_SSH_HOST"
			local TARGET_PORT="$KJ_SSH_PORT"
			local latest_tar=$(ls -t /home/*.tar.gz | head -1)
			if [ -n "$latest_tar" ]; then
			  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			  sleep 2  # 添加等待时间
			  scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
			  echo "文件已传送至远程服务器home目录。"
			else
			  echo "未找到要传送的文件。"
			fi
			break
			;;
		  [Nn])
			break
			;;
		  *)
			echo "无效的选择，请输入 Y 或 N。"
			;;
		esac
	  done
	  ;;

	33)
	  clear
	  send_stats "定时远程备份"
	  read -e -p "输入远程服务器IP: " useip
	  read -e -p "输入远程服务器密码: " usepasswd

	  cd ~
	  wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
	  chmod +x ${useip}_beifen.sh

	  sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
	  sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

	  echo "------------------------"
	  echo "1. 每周备份                 2. 每天备份"
	  read -e -p "请输入你的选择: " dingshi

	  case $dingshi in
		  1)
			  check_crontab_installed
			  read -e -p "选择每周备份的星期几 (0-6，0代表星期日): " weekday
			  (crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  2)
			  check_crontab_installed
			  read -e -p "选择每天备份的时间（小时，0-23）: " hour
			  (crontab -l ; echo "0 $hour * * * ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  *)
			  break  # 跳出
			  ;;
	  esac

	  install sshpass

	  ;;

	34)
	  root_use
	  send_stats "LDNMP环境还原"
	  echo "可用的站点备份"
	  echo "-------------------------"
	  ls -lt /home/*.gz | awk '{print $NF}'
	  echo ""
	  read -e -p  "回车键还原最新的备份，输入备份文件名还原指定的备份，输入0退出：" filename

	  if [ "$filename" == "0" ]; then
		  break_end
		  linux_ldnmp
	  fi

	  # 如果用户没有输入文件名，使用最新的压缩包
	  if [ -z "$filename" ]; then
		  local filename=$(ls -t /home/*.tar.gz | head -1)
	  fi

	  if [ -n "$filename" ]; then
		  cd /home/web/ > /dev/null 2>&1
		  docker compose down > /dev/null 2>&1
		  rm -rf /home/web > /dev/null 2>&1

		  echo -e "${gl_kjlan}正在解压 $filename ...${gl_bai}"
		  cd /home/ && tar -xzf "$filename"

		  install_dependency
		  install_docker
		  install_certbot
		  install_ldnmp
	  else
		  echo "没有找到压缩包。"
	  fi

	  ;;

	35)
		web_security
		;;

	36)
		web_optimization
		;;


	37)
	  root_use
	  while true; do
		  clear
		  send_stats "更新LDNMP环境"
		  echo "更新LDNMP环境"
		  echo "------------------------"
		  ldnmp_v
		  echo "发现新版本的组件"
		  echo "------------------------"
		  check_docker_image_update nginx
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}nginx $update_status${gl_bai}"
		  fi
		  check_docker_image_update php
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}php $update_status${gl_bai}"
		  fi
		  check_docker_image_update mysql
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}mysql $update_status${gl_bai}"
		  fi
		  check_docker_image_update redis
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}redis $update_status${gl_bai}"
		  fi
		  echo "------------------------"
		  echo
		  echo "1. 更新nginx               2. 更新mysql              3. 更新php              4. 更新redis"
		  echo "------------------------"
		  echo "5. 更新完整环境"
		  echo "------------------------"
		  echo "0. 返回上一级选单"
		  echo "------------------------"
		  read -e -p "请输入你的选择: " sub_choice
		  case $sub_choice in
			  1)
			  nginx_upgrade

				  ;;

			  2)
			  local ldnmp_pods="mysql"
			  read -e -p "请输入${ldnmp_pods}版本号 （如: 8.0 8.3 8.4 9.0）（回车获取最新版）: " version
			  local version=${version:-latest}

			  cd /home/web/
			  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
			  sed -i "s/image: mysql/image: mysql:${version}/" /home/web/docker-compose.yml
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "更新$ldnmp_pods"
			  echo "更新${ldnmp_pods}完成"

				  ;;
			  3)
			  local ldnmp_pods="php"
			  read -e -p "请输入${ldnmp_pods}版本号 （如: 7.4 8.0 8.1 8.2 8.3）（回车获取最新版）: " version
			  local version=${version:-8.3}
			  cd /home/web/
			  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
			  sed -i "s/kjlion\///g" /home/web/docker-compose.yml > /dev/null 2>&1
			  sed -i "s/image: php:fpm-alpine/image: php:${version}-fpm-alpine/" /home/web/docker-compose.yml
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
  			  docker images --filter=reference="kjlion/${ldnmp_pods}*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker exec php chown -R www-data:www-data /var/www/html

			  run_command docker exec php sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories > /dev/null 2>&1

			  docker exec php apk update
			  curl -sL ${gh_proxy}github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions
			  docker exec php mkdir -p /usr/local/bin/
			  docker cp /usr/local/bin/install-php-extensions php:/usr/local/bin/
			  docker exec php chmod +x /usr/local/bin/install-php-extensions
			  docker exec php install-php-extensions mysqli pdo_mysql gd intl zip exif bcmath opcache redis imagick soap


			  docker exec php sh -c 'echo "upload_max_filesize=50M " > /usr/local/etc/php/conf.d/uploads.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "post_max_size=50M " > /usr/local/etc/php/conf.d/post.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "memory_limit=512M" > /usr/local/etc/php/conf.d/memory.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_execution_time=1200" > /usr/local/etc/php/conf.d/max_execution_time.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_input_time=600" > /usr/local/etc/php/conf.d/max_input_time.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_input_vars=5000" > /usr/local/etc/php/conf.d/max_input_vars.ini' > /dev/null 2>&1

			  fix_phpfpm_con $ldnmp_pods

			  docker restart $ldnmp_pods > /dev/null 2>&1
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "更新$ldnmp_pods"
			  echo "更新${ldnmp_pods}完成"

				  ;;
			  4)
			  local ldnmp_pods="redis"
			  cd /home/web/
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods > /dev/null 2>&1
			  send_stats "更新$ldnmp_pods"
			  echo "更新${ldnmp_pods}完成"

				  ;;
			  5)
				read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}长时间不更新环境的用户，请慎重更新LDNMP环境，会有数据库更新失败的风险。确定更新LDNMP环境吗？(Y/N): ")" choice
				case "$choice" in
				  [Yy])
					send_stats "完整更新LDNMP环境"
					cd /home/web/
					docker compose down --rmi all

					install_dependency
					install_docker
					install_certbot
					install_ldnmp
					;;
				  *)
					;;
				esac
				  ;;
			  *)
				  break
				  ;;
		  esac
		  break_end
	  done


	  ;;

	38)
		root_use
		send_stats "卸载LDNMP环境"
		read -e -p "$(echo -e "${gl_hong}强烈建议：${gl_bai}先备份全部网站数据，再卸载LDNMP环境。确定删除所有网站数据吗？(Y/N): ")" choice
		case "$choice" in
		  [Yy])
			cd /home/web/
			docker compose down --rmi all
			docker compose -f docker-compose.phpmyadmin.yml down > /dev/null 2>&1
			docker compose -f docker-compose.phpmyadmin.yml down --rmi all > /dev/null 2>&1
			rm -rf /home/web
			;;
		  [Nn])

			;;
		  *)
			echo "无效的选择，请输入 Y 或 N。"
			;;
		esac
		;;

	0)
		break
	  ;;

	*)
		echo "无效的输入!"
	esac
	if [ "${KJ_WEB_NONINTERACTIVE:-0}" = "1" ]; then
		if [ ! -f "/home/web/conf.d/${KJ_WEB_DOMAIN}.conf" ]; then
			echo "KPANEL_PROGRESS 100 kejilion.sh 建站产物不完整"
			return 1
		fi
		if kpanel_web_recipe_requires_document_root "$sub_choice" &&
			[ ! -d "/home/web/html/${KJ_WEB_DOMAIN}" ]; then
			echo "KPANEL_PROGRESS 100 kejilion.sh 建站产物不完整"
			return 1
		fi
		if ! docker exec nginx nginx -t >/dev/null 2>&1; then
			echo "KPANEL_PROGRESS 100 Nginx 配置校验失败"
			return 1
		fi
		echo "KPANEL_PROGRESS 100 kejilion.sh 原生建站产物已完成"
		return 0
	fi
	break_end

  done

}
# --- [helpers] ---
check_disk_space() {
	local required_gb=$1
	local path=${2:-/}

	mkdir -p "$path"

	local required_space_mb=$((required_gb * 1024))
	local available_space_mb=$(df -m "$path" | awk 'NR==2 {print $4}')

	if [ "$available_space_mb" -lt "$required_space_mb" ]; then
		echo -e "${gl_huang}提示: ${gl_bai}磁盘空间不足！"
		echo "当前可用空间: $((available_space_mb/1024))G"
		echo "最小需求空间: ${required_gb}G"
		echo "无法继续安装，请清理磁盘空间后重试。"
		send_stats "磁盘空间不足"
		break_end
		break
	fi
}

check_crontab_installed() {
	if ! command -v crontab >/dev/null 2>&1; then
		install_crontab
	fi
}

install_crontab() {

	if [ -f /etc/os-release ]; then
		. /etc/os-release
		case "$ID" in
			ubuntu|debian|kali)
				apt update
				apt install -y cron
				systemctl enable cron
				systemctl start cron
				;;
			centos|rhel|almalinux|rocky|fedora)
				yum install -y cronie
				systemctl enable crond
				systemctl start crond
				;;
			alpine)
				apk add --no-cache cronie
				rc-update add crond
				rc-service crond start
				;;
			arch|manjaro)
				pacman -S --noconfirm cronie
				systemctl enable cronie
				systemctl start cronie
				;;
			opensuse|suse|opensuse-tumbleweed)
				zypper install -y cron
				systemctl enable cron
				systemctl start cron
				;;
			iStoreOS|openwrt|ImmortalWrt|lede)
				opkg update
				opkg install cron
				/etc/init.d/cron enable
				/etc/init.d/cron start
				;;
			FreeBSD)
				pkg install -y cronie
				sysrc cron_enable="YES"
				service cron start
				;;
			*)
				echo "不支持的发行版: $ID"
				return
				;;
		esac
	else
		echo "无法确定操作系统。"
		return
	fi

	echo -e "${gl_lv}crontab 已安装且 cron 服务正在运行。${gl_bai}"
}

save_iptables_rules() {
	mkdir -p /etc/iptables
	touch /etc/iptables/rules.v4
	iptables-save > /etc/iptables/rules.v4
	check_crontab_installed
	crontab -l | grep -v 'iptables-restore' | crontab - > /dev/null 2>&1
	(crontab -l ; echo '@reboot iptables-restore < /etc/iptables/rules.v4') | crontab - > /dev/null 2>&1

}


open_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "请提供至少一个端口号"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 删除已存在的关闭规则
		iptables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

		# 添加打开规则
		if ! iptables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j ACCEPT
		fi

		if ! iptables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j ACCEPT
			echo "已打开端口 $port"
		fi
	done

	save_iptables_rules
	send_stats "已打开端口"
}

close_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "请提供至少一个端口号"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 删除已存在的打开规则
		iptables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null

		# 添加关闭规则
		if ! iptables -C INPUT -p tcp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j DROP
		fi

		if ! iptables -C INPUT -p udp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j DROP
			echo "已关闭端口 $port"
		fi
	done

	# 删除已存在的规则（如果有）
	iptables -D INPUT -i lo -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i lo -j ACCEPT 2>/dev/null

	# 插入新规则到第一条
	iptables -I INPUT 1 -i lo -j ACCEPT
	iptables -I FORWARD 1 -i lo -j ACCEPT

	save_iptables_rules
	send_stats "已关闭端口"
}

allow_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "请提供至少一个IP地址或IP段"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的阻止规则
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 添加允许规则
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "已放行IP $ip"
		fi
	done

	save_iptables_rules
	send_stats "已放行IP"
}

block_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "请提供至少一个IP地址或IP段"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的允许规则
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# 添加阻止规则
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "已阻止IP $ip"
		fi
	done

	save_iptables_rules
	send_stats "已阻止IP"
}

enable_ddos_defense() {
	# 开启防御 DDoS
	iptables -A DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A DOCKER-USER -p tcp --syn -j DROP
	iptables -A DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A DOCKER-USER -p udp -j DROP
	iptables -A INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A INPUT -p tcp --syn -j DROP
	iptables -A INPUT -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A INPUT -p udp -j DROP

	send_stats "开启DDoS防御"
}

disable_ddos_defense() {
	# 关闭防御 DDoS
	iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
	iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null
	iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
	iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D INPUT -p udp -j DROP 2>/dev/null

	send_stats "关闭DDoS防御"
}

manage_country_rules() {
	local action="$1"
	shift  # 去掉第一个参数，剩下的全是国家代码

	install ipset

	for country_code in "$@"; do
		local ipset_name="${country_code,,}_block"
		local download_url="http://www.ipdeny.com/ipblocks/data/countries/${country_code,,}.zone"

		case "$action" in
			block)
				if ! ipset list "$ipset_name" &> /dev/null; then
					ipset create "$ipset_name" hash:net
				fi

				if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
					echo "错误：下载 $country_code 的 IP 区域文件失败"
					continue
				fi

				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"

				iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP

				echo "已成功阻止 $country_code 的 IP 地址"
				rm "${country_code,,}.zone"
				;;

			allow)
				if ! ipset list "$ipset_name" &> /dev/null; then
					ipset create "$ipset_name" hash:net
				fi

				if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
					echo "错误：下载 $country_code 的 IP 区域文件失败"
					continue
				fi

				ipset flush "$ipset_name"
				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"


				iptables -P INPUT DROP
				iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT

				echo "已成功允许 $country_code 的 IP 地址"
				rm "${country_code,,}.zone"
				;;

			unblock)
				iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null

				if ipset list "$ipset_name" &> /dev/null; then
					ipset destroy "$ipset_name"
				fi

				echo "已成功解除 $country_code 的 IP 地址限制"
				;;

			*)
				echo "用法: manage_country_rules {block|allow|unblock} <country_code...>"
				;;
		esac
	done
}

check_docker_app() {
	if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name" ; then
		check_docker="${gl_lv}已安装${gl_bai}"
	else
		check_docker="${gl_hui}未安装${gl_bai}"
	fi
}

check_docker_app_ip() {
echo "------------------------"
echo "访问地址:"
ip_address



if [ -n "$ipv4_address" ]; then
	echo "http://$ipv4_address:${docker_port}"
fi

if [ -n "$ipv6_address" ]; then
	echo "http://[$ipv6_address]:${docker_port}"
fi

local search_pattern1="$ipv4_address:${docker_port}"
local search_pattern2="127.0.0.1:${docker_port}"

for file in /home/web/conf.d/*; do
	if [ -f "$file" ]; then
		if grep -q "$search_pattern1" "$file" 2>/dev/null || grep -q "$search_pattern2" "$file" 2>/dev/null; then
			echo "https://$(basename "$file" | sed 's/\.conf$//')"
		fi
	fi
done


}

check_docker_image_update() {
	local container_name=$1
	update_status=""

	# 1. 获取容器及本地镜像信息。更新检测不再按地区跳过。
	local container_info
	container_info=$(docker inspect --format='{{.Created}},{{.Config.Image}},{{.Image}}' "$container_name" 2>/dev/null)
	[[ -z "$container_info" ]] && return

	local container_created full_image_name container_image_id container_created_ts
	container_created=$(echo "$container_info" | cut -d',' -f1)
	full_image_name=$(echo "$container_info" | cut -d',' -f2)
	container_image_id=$(echo "$container_info" | cut -d',' -f3)
	container_created_ts=$(date -d "$container_created" +%s 2>/dev/null)

	# 2. 智能路由判断
	if [[ "$full_image_name" == ghcr.io* ]]; then
		# --- 场景 A: 镜像在 GitHub (ghcr.io) ---
		# 提取仓库路径，例如 ghcr.io/onexru/oneimg -> onexru/oneimg
		local repo_path=$(echo "$full_image_name" | sed 's/ghcr.io\///' | cut -d':' -f1)
		# 注意：ghcr.io 的 API 比较复杂，通常最快的方法是查 GitHub Repo 的 Release
		local api_url="https://api.github.com/repos/$repo_path/releases/latest"
		local remote_date=$(curl -s "$api_url" | jq -r '.published_at' 2>/dev/null)

	elif [[ "$full_image_name" == *"oneimg"* ]]; then
		# --- 场景 B: 特殊指定 (即便在 Docker Hub，也想通过 GitHub Release 判断) ---
		local api_url="https://api.github.com/repos/onexru/oneimg/releases/latest"
		local remote_date=$(curl -s "$api_url" | jq -r '.published_at' 2>/dev/null)

	else
		# --- 场景 C: 标准 Docker Hub ---
		local docker_ref image_repo image_tag api_payload remote_digest local_digest
		docker_ref=${full_image_name#docker.io/}
		docker_ref=${docker_ref#index.docker.io/}
		docker_ref=${docker_ref#registry-1.docker.io/}
		if [[ "$docker_ref" == *@* ]]; then
			image_repo=${docker_ref%@*}
			image_tag="latest"
		elif [[ "${docker_ref##*/}" == *:* ]]; then
			image_repo=${docker_ref%:*}
			image_tag=${docker_ref##*:}
		else
			image_repo=$docker_ref
			image_tag="latest"
		fi
		[[ "$image_repo" != */* ]] && image_repo="library/$image_repo"

		local api_url="https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag"
		api_payload=$(curl -fsSL --max-time 8 "$api_url" 2>/dev/null)
		remote_digest=$(printf '%s' "$api_payload" | jq -r '.digest // empty' 2>/dev/null)
		local remote_date
		remote_date=$(printf '%s' "$api_payload" | jq -r '.last_updated // empty' 2>/dev/null)
		local_digest=$(
			docker image inspect --format='{{range .RepoDigests}}{{println .}}{{end}}' "$container_image_id" 2>/dev/null |
				sed -n 's/^.*@\(sha256:[a-f0-9]\{64\}\)$/\1/p' |
				head -n 1
		)
		if [[ "$remote_digest" =~ ^sha256:[a-f0-9]{64}$ && "$local_digest" =~ ^sha256:[a-f0-9]{64}$ ]]; then
			if [[ "$remote_digest" != "$local_digest" ]]; then
				update_status="${gl_huang}发现新版本!${gl_bai}"
			fi
			return
		fi
	fi

	# 3. Registry 未提供可比较摘要时，兼容使用发布时间判断。
	if [[ -n "$remote_date" && "$remote_date" != "null" ]]; then
		local remote_ts=$(date -d "$remote_date" +%s 2>/dev/null)
		if [[ "$container_created_ts" =~ ^[0-9]+$ && "$remote_ts" =~ ^[0-9]+$ ]] &&
			[[ $container_created_ts -lt $remote_ts ]]; then
			update_status="${gl_huang}发现新版本!${gl_bai}"
		fi
	fi
}

get_container_ipv4_addresses() {
	local container_name_or_id=$1
	local container_ips

	container_ips=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{if .IPAddress}}{{println .IPAddress}}{{end}}{{end}}' "$container_name_or_id" 2>/dev/null) || return 1
	printf '%s\n' "$container_ips" | awk 'NF && !seen[$0]++'
}

ensure_docker_user_rule() {
	if ! iptables -C DOCKER-USER "$@" &>/dev/null; then
		iptables -I DOCKER-USER "$@"
	fi
}

remove_docker_user_rule() {
	if iptables -C DOCKER-USER "$@" &>/dev/null; then
		iptables -D DOCKER-USER "$@"
	fi
}

block_container_port() {
	local container_name_or_id=$1
	local allowed_ip=$2
	local container_ips
	local container_ip

	# 获取容器在所有 Docker 网络中的 IPv4 地址，逐个应用规则。
	container_ips=$(get_container_ipv4_addresses "$container_name_or_id")
	if [ -z "$container_ips" ]; then
		echo "错误：无法获取容器 ${container_name_or_id} 的 IPv4 地址。" >&2
		return 1
	fi

	install iptables

	while IFS= read -r container_ip; do
		ensure_docker_user_rule -p tcp -d "$container_ip" -j DROP || return 1
		ensure_docker_user_rule -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT || return 1
		ensure_docker_user_rule -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT || return 1
		ensure_docker_user_rule -p udp -d "$container_ip" -j DROP || return 1
		ensure_docker_user_rule -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT || return 1
		ensure_docker_user_rule -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT || return 1
		ensure_docker_user_rule -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT || return 1
	done <<< "$container_ips"

	echo "已阻止IP+端口访问该服务"
	save_iptables_rules
}

clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2
	local container_ips
	local container_ip

	# 获取容器在所有 Docker 网络中的 IPv4 地址，逐个清除规则。
	container_ips=$(get_container_ipv4_addresses "$container_name_or_id")
	if [ -z "$container_ips" ]; then
		echo "错误：无法获取容器 ${container_name_or_id} 的 IPv4 地址。" >&2
		return 1
	fi

	install iptables

	while IFS= read -r container_ip; do
		remove_docker_user_rule -p tcp -d "$container_ip" -j DROP || return 1
		remove_docker_user_rule -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT || return 1
		remove_docker_user_rule -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT || return 1
		remove_docker_user_rule -p udp -d "$container_ip" -j DROP || return 1
		remove_docker_user_rule -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT || return 1
		remove_docker_user_rule -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT || return 1
		remove_docker_user_rule -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT || return 1
	done <<< "$container_ips"

	echo "已允许IP+端口访问该服务"
	save_iptables_rules
}

block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "错误：请提供端口号和允许访问的 IP。"
		echo "用法: block_host_port <端口号> <允许的IP>"
		return 1
	fi

	install iptables


	# 拒绝其他所有 IP 访问
	if ! iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -j DROP
	fi

	# 允许指定 IP 访问
	if ! iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 允许本机访问
	if ! iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi





	# 拒绝其他所有 IP 访问
	if ! iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -j DROP
	fi

	# 允许指定 IP 访问
	if ! iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 允许本机访问
	if ! iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 允许已建立和相关连接的流量
	if ! iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT &>/dev/null; then
		iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	fi

	echo "已阻止IP+端口访问该服务"
	save_iptables_rules
}

clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "错误：请提供端口号和允许访问的 IP。"
		echo "用法: clear_host_port_rules <端口号> <允许的IP>"
		return 1
	fi

	install iptables


	# 清除封禁所有其他 IP 访问的规则
	if iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -j DROP
	fi

	# 清除允许本机访问的规则
	if iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 清除允许指定 IP 访问的规则
	if iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	# 清除封禁所有其他 IP 访问的规则
	if iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -j DROP
	fi

	# 清除允许本机访问的规则
	if iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 清除允许指定 IP 访问的规则
	if iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	echo "已允许IP+端口访问该服务"
	save_iptables_rules

}

setup_docker_dir() {

	mkdir -p /home /home/docker 2>/dev/null

	if [ -d "/vol1/1000/" ] && [ ! -d "/vol1/1000/docker" ]; then
		cp -f /home/docker /home/docker1 2>/dev/null
		rm -rf /home/docker 2>/dev/null
		mkdir -p /vol1/1000/docker 2>/dev/null
		ln -s /vol1/1000/docker /home/docker 2>/dev/null
	fi

	if [ -d "/volume1/" ] && [ ! -d "/volume1/docker" ]; then
		cp -f /home/docker /home/docker1 2>/dev/null
		rm -rf /home/docker 2>/dev/null
		mkdir -p /volume1/docker 2>/dev/null
		ln -s /volume1/docker /home/docker 2>/dev/null
	fi


}

add_app_id() {
mkdir -p /home/docker
touch /home/docker/appno.txt
grep -qxF "${app_id}" /home/docker/appno.txt || echo "${app_id}" >> /home/docker/appno.txt

}


f2b_status() {
	 fail2ban-client reload
	 sleep 3
	 fail2ban-client status
}

f2b_status_xxx() {
	fail2ban-client status $xxx
}

f2b_install_sshd() {

	docker rm -f fail2ban >/dev/null 2>&1
	install fail2ban
	start fail2ban
	enable fail2ban

	if command -v dnf &>/dev/null; then
		cd /etc/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/centos-ssh.conf
	fi

	if command -v apt &>/dev/null; then
		install rsyslog
		systemctl start rsyslog
		systemctl enable rsyslog
	fi

}

f2b_sshd() {
	if grep -q 'Alpine' /etc/issue; then
		xxx=alpine-sshd
		f2b_status_xxx
	else
		xxx=sshd
		f2b_status_xxx
	fi
}

optimize_balanced() {
	_kernel_optimize_core "均衡优化模式" "balanced"
}

optimize_web_server() {
	_kernel_optimize_core "网站搭建优化模式" "web"
}

root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}提示: ${gl_bai}该功能需要root用户才能运行！" && break_end && kejilion
}

run_command() {
	if [ "$zhushi" -eq 0 ]; then
		"$@"
	fi
}

set_dns() {

ip_address

chattr -i /etc/resolv.conf
> /etc/resolv.conf

if [ -n "$ipv4_address" ]; then
	echo "nameserver $dns1_ipv4" >> /etc/resolv.conf
	echo "nameserver $dns2_ipv4" >> /etc/resolv.conf
fi

if [ -n "$ipv6_address" ]; then
	echo "nameserver $dns1_ipv6" >> /etc/resolv.conf
	echo "nameserver $dns2_ipv6" >> /etc/resolv.conf
fi

if [ ! -s /etc/resolv.conf ]; then
	echo "nameserver 223.5.5.5" >> /etc/resolv.conf
	echo "nameserver 8.8.8.8" >> /etc/resolv.conf
fi

chattr +i /etc/resolv.conf

}

kj_ssh_read_host_port() {
	local host_prompt="$1"
	local port_prompt="$2"
	local default_port="${3:-22}"

	while true; do
		read -e -p "$host_prompt" KJ_SSH_HOST
		if kj_ssh_validate_host "$KJ_SSH_HOST"; then
			break
		fi
		echo "错误: 请输入有效的服务器地址。"
	done

	while true; do
		read -e -p "$port_prompt" KJ_SSH_PORT
		KJ_SSH_PORT=${KJ_SSH_PORT:-$default_port}
		if kj_ssh_validate_port "$KJ_SSH_PORT"; then
			break
		fi
		echo "错误: 端口必须是 1-65535 之间的数字。"
	done
}

docker_app() {
if docker inspect "$docker_name" &>/dev/null; then
    clear
    echo "$docker_name 已安装，访问地址: "
    ip_address
    echo "http:$ipv4_address:$docker_port"
    echo ""
    echo "应用操作"
    echo "------------------------"
    echo "1. 更新应用             2. 卸载应用"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

    case $sub_choice in
        1)
            clear
            docker rm -f "$docker_name"
            docker rmi -f "$docker_img"
            # 安装 Docker（请确保有 install_docker 函数）
            install_docker
            $docker_rum
            clear
            echo "$docker_name 已经安装完成"
            echo "------------------------"
            # 获取外部 IP 地址
            ip_address
            echo "您可以使用以下地址访问:"
            echo "http:$ipv4_address:$docker_port"
            $docker_use
            $docker_passwd
            ;;
        2)
            clear
            docker rm -f "$docker_name"
            docker rmi -f "$docker_img"
            rm -rf "/home/docker/$docker_name"
            echo "应用已卸载"
            ;;
        0)
            # 跳出循环，退出菜单
            ;;
        *)
            # 跳出循环，退出菜单
            ;;
    esac
else
    clear
    echo "安装提示"
    echo "$docker_describe"
    echo "$docker_url"
    echo ""

    # 提示用户确认安装
    read -p "确定安装吗？(Y/N): " choice
    case "$choice" in
        [Yy])
            clear
            # 安装 Docker（请确保有 install_docker 函数）
            install_docker
            $docker_rum
            clear
            echo "$docker_name 已经安装完成"
            echo "------------------------"
            # 获取外部 IP 地址
            ip_address
            echo "您可以使用以下地址访问:"
            echo "http:$ipv4_address:$docker_port"
            $docker_use
            $docker_passwd
            ;;
        [Nn])
            # 用户选择不安装
            ;;
        *)
            # 无效输入
            ;;
    esac
fi

}

# ============================================================================
# FoxToolBox 增强功能模块
# ============================================================================

# ---------- 26. Docker 应用市场 ----------
fox_docker_app_list() {
  echo "━━━ Docker 应用市场 ━━━"
  echo " 1.  1Panel 管理面板                   2.  青龙面板(定时任务/薅羊毛)"
  echo " 3.  Nextcloud 私有网盘                4.  LobeChat AI聊天聚合"
  echo " 5.  Dify 大模型知识库                  6.  n8n 自动化工作流"
  echo " 7.  OpenWebUI AI平台                  8.  Bitwarden 密码管理器"
  echo " 9.  Stirling-PDF PDF工具箱            10. it-tools 开发工具箱"
  echo "11.  UptimeKuma 监控面板               12. Portainer 容器管理"
  echo "13.  NginxProxyManager 反代面板         14. Memos 备忘录"
  echo "15.  AList 网盘聚合                    16. emby 媒体服务器"
  echo "17.  qBittorrent BT下载                18. Cloudreve 网盘"
  echo "19.  简单图床                          20. AdGuardHome 去广告"
  echo "21.  ddns-go 动态DNS                   22. Navidrome 音乐服务器"
  echo "23.  searxng 元搜索引擎                24. PhotoPrism 相册"
  echo "25.  Sun-Panel 导航面板                26. RAGFlow 知识库"
  echo "27.  Langfuse LLM可观测性              28. FastGPT 知识库问答"
  echo "29.  Grafana 监控面板                  30. Speedtest 测速"
  echo "31.  draw.io 在线图表绘制              32. Pingvin-Share 文件分享"
  echo "33.  MyIP 工具箱                      34. WebSSH 网页版SSH"
  echo "35.  RustDesk 远程桌面(服务端)         36. FRP 内网穿透(服务端)"
  echo "37.  NewAPI 大模型API管理              38. yt-dlp 视频下载工具"
  echo "39.  Beszel 轻量服务器监控             40. 在线DOS老游戏"
  echo "──────────────────────────"
}

fox_docker_app_market() {
  while true; do
    clear
    echo "▶ Docker 应用市场"
    echo "精选常用自托管应用，一键 Docker 部署（数据目录 /home/docker）"
    fox_docker_app_list
    echo " 0. 返回上一级选单"
    read -p $'\033[1;91m请输入你的选择: \033[0m' app_choice
    case $app_choice in
      1)
        docker_name="1panel"
        docker_img="moeyui/1panel:latest"
        docker_port=64444
        docker_rum="docker run -d --name 1panel --restart always -p 64444:64444 -v /home/docker/1panel:/opt/1panel -v /var/run/docker.sock:/var/run/docker.sock -e TZ=Asia/Shanghai moeyui/1panel:latest"
        docker_describe="1Panel 新一代 Linux 服务器运维管理面板"
        docker_url="官网: https://1panel.cn"
        docker_use="默认账号: admin  默认密码: 1panel"
        docker_passwd=""
        docker_app ;;
      2)
        docker_name="qinglong"
        docker_img="whyour/qinglong:latest"
        docker_port=5700
        docker_rum="docker run -d --name qinglong --restart always -p 5700:5700 -v /home/docker/qinglong:/ql/data whyour/qinglong:latest"
        docker_describe="青龙面板，定时任务管理平台"
        docker_url="官网: https://github.com/whyour/qinglong"
        docker_use="首次访问设置账号密码"
        docker_passwd=""
        docker_app ;;
      3)
        docker_name="nextcloud"
        docker_img="nextcloud:latest"
        docker_port=8080
        docker_rum="docker run -d --name nextcloud --restart always -p 8080:8080 -v /home/docker/nextcloud:/var/www/html nextcloud:latest"
        docker_describe="Nextcloud 私有云网盘"
        docker_url="官网: https://nextcloud.com"
        docker_use="首次访问设置管理员账号"
        docker_passwd=""
        docker_app ;;
      4)
        docker_name="lobechat"
        docker_img="lobehub/lobe-chat:latest"
        docker_port=3210
        docker_rum="docker run -d --name lobechat --restart always -p 3210:3210 -v /home/docker/lobechat:/app/.next lobehub/lobe-chat:latest"
        docker_describe="LobeChat 开源 AI 聊天聚合平台"
        docker_url="官网: https://lobechat.com"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      5)
        docker_name="dify"
        docker_img="langgenius/dify-api:latest"
        docker_port=3000
        docker_rum="docker run -d --name dify --restart always -p 3000:3000 -v /home/docker/dify:/app langgenius/dify-api:latest"
        docker_describe="Dify 开源 LLM 应用开发平台（含 WebUI）"
        docker_url="官网: https://dify.ai"
        docker_use="建议使用 Docker Compose 完整部署"
        docker_passwd=""
        docker_app ;;
      6)
        docker_name="n8n"
        docker_img="n8nio/n8n:latest"
        docker_port=5678
        docker_rum="docker run -d --name n8n --restart always -p 5678:5678 -v /home/docker/n8n:/home/node/.n8n n8nio/n8n:latest"
        docker_describe="n8n 可视化自动化工作流平台"
        docker_url="官网: https://n8n.io"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      7)
        docker_name="openwebui"
        docker_img="ghcr.io/open-webui/open-webui:main"
        docker_port=3000
        docker_rum="docker run -d --name openwebui --restart always -p 3000:3000 -v /home/docker/openwebui:/app/backend/data ghcr.io/open-webui/open-webui:main"
        docker_describe="OpenWebUI 自托管 AI 平台"
        docker_url="官网: https://openwebui.com"
        docker_use="首次访问设置管理员账号"
        docker_passwd=""
        docker_app ;;
      8)
        docker_name="bitwarden"
        docker_img="vaultwarden/server:latest"
        docker_port=8989
        docker_rum="docker run -d --name bitwarden --restart always -p 8989:80 -v /home/docker/bitwarden:/data vaultwarden/server:latest"
        docker_describe="Bitwarden 自托管密码管理器（Vaultwarden）"
        docker_url="官网: https://github.com/dani-garcia/vaultwarden"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      9)
        docker_name="stirlingpdf"
        docker_img="frooodle/s-pdf:latest"
        docker_port=8888
        docker_rum="docker run -d --name stirlingpdf --restart always -p 8888:8080 -v /home/docker/stirlingpdf:/configs frooodle/s-pdf:latest"
        docker_describe="Stirling-PDF 本地 PDF 工具箱"
        docker_url="官网: https://github.com/Stirling-Tools/Stirling-PDF"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      10)
        docker_name="it-tools"
        docker_img="corentinth/it-tools:latest"
        docker_port=8889
        docker_rum="docker run -d --name it-tools --restart always -p 8889:80 corentinth/it-tools:latest"
        docker_describe="it-tools 开发者常用小工具集合"
        docker_url="官网: https://it-tools.tech"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      11)
        docker_name="uptime-kuma"
        docker_img="louislam/uptime-kuma:latest"
        docker_port=3001
        docker_rum="docker run -d --name uptime-kuma --restart always -p 3001:3001 -v /home/docker/uptime-kuma:/app/data louislam/uptime-kuma:latest"
        docker_describe="Uptime Kuma 网站监控面板"
        docker_url="官网: https://github.com/louislam/uptime-kuma"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      12)
        docker_name="portainer"
        docker_img="portainer/portainer-ce:latest"
        docker_port=9443
        docker_rum="docker run -d --name portainer --restart always -p 9443:9443 -v /var/run/docker.sock:/var/run/docker.sock -v /home/docker/portainer:/data portainer/portainer-ce:latest"
        docker_describe="Portainer Docker 可视化容器管理"
        docker_url="官网: https://www.portainer.io"
        docker_use="首次访问设置管理员密码"
        docker_passwd=""
        docker_app ;;
      13)
        docker_name="nginx-proxy-manager"
        docker_img="jc21/nginx-proxy-manager:latest"
        docker_port=8181
        docker_rum="docker run -d --name nginx-proxy-manager --restart always -p 80:80 -p 443:443 -p 8181:81 -v /home/docker/npm:/data jc21/nginx-proxy-manager:latest"
        docker_describe="Nginx Proxy Manager 可视化反代面板"
        docker_url="官网: https://nginxproxymanager.com"
        docker_use="默认账号: admin@example.com  密码: changeme"
        docker_passwd=""
        docker_app ;;
      14)
        docker_name="memos"
        docker_img="ghcr.io/usememos/memos:latest"
        docker_port=5230
        docker_rum="docker run -d --name memos --restart always -p 5230:5230 -v /home/docker/memos:/var/opt/memos ghcr.io/usememos/memos:latest"
        docker_describe="Memos 轻量备忘录中心"
        docker_url="官网: https://github.com/usememos/memos"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      15)
        docker_name="alist"
        docker_img="xhofe/alist:latest"
        docker_port=5244
        docker_rum="docker run -d --name alist --restart always -p 5244:5244 -v /home/docker/alist:/opt/alist/data xhofe/alist:latest"
        docker_describe="AList 多存储文件列表程序"
        docker_url="官网: https://alist.nn.ci"
        docker_use="首次运行执行 docker exec -it alist ./alist admin random 获取密码"
        docker_passwd=""
        docker_app ;;
      16)
        docker_name="emby"
        docker_img="emby/embyserver:latest"
        docker_port=8096
        docker_rum="docker run -d --name emby --restart always -p 8096:8096 -v /home/docker/emby:/config -v /home/docker/emby/media:/media emby/embyserver:latest"
        docker_describe="emby 多媒体管理系统"
        docker_url="官网: https://emby.media"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      17)
        docker_name="qbittorrent"
        docker_img="lscr.io/linuxserver/qbittorrent:latest"
        docker_port=8081
        docker_rum="docker run -d --name qbittorrent --restart always -p 8081:8080 -p 6881:6881 -v /home/docker/qbittorrent:/config -v /home/docker/qbittorrent/downloads:/downloads lscr.io/linuxserver/qbittorrent:latest"
        docker_describe="qBittorrent BT/磁力下载工具"
        docker_url="官网: https://www.qbittorrent.org"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      18)
        docker_name="cloudreve"
        docker_img="xavier1991/cloudreve:latest"
        docker_port=5212
        docker_rum="docker run -d --name cloudreve --restart always -p 5212:80 -v /home/docker/cloudreve:/cloudreve xavier1991/cloudreve:latest"
        docker_describe="Cloudreve 云网盘系统"
        docker_url="官网: https://cloudreve.org"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      19)
        docker_name="lsky"
        docker_img="halcyonazure/lsky-pro-docker:latest"
        docker_port=7791
        docker_rum="docker run -d --name lsky --restart always -p 7791:80 -v /home/docker/lsky:/var/www/html halcyonazure/lsky-pro-docker:latest"
        docker_describe="简单图床（兰空图床）"
        docker_url="官网: https://www.lsky.pro"
        docker_use="安装完成访问 /install 完成配置"
        docker_passwd=""
        docker_app ;;
      20)
        docker_name="adguardhome"
        docker_img="adguard/adguardhome:latest"
        docker_port=3000
        docker_rum="docker run -d --name adguardhome --restart always -p 3000:3000 -p 53:53/tcp -p 53:53/udp -v /home/docker/adguardhome:/opt/adguardhome/work adguard/adguardhome:latest"
        docker_describe="AdGuard Home 去广告 DNS 服务器"
        docker_url="官网: https://adguard.com"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      21)
        docker_name="ddns-go"
        docker_img="jeessy/ddns-go:latest"
        docker_port=9876
        docker_rum="docker run -d --name ddns-go --restart always -p 9876:9876 -v /home/docker/ddns-go:/root jeessy/ddns-go:latest"
        docker_describe="ddns-go 动态 DNS 管理"
        docker_url="官网: https://github.com/jeessy2/ddns-go"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      22)
        docker_name="navidrome"
        docker_img="deluan/navidrome:latest"
        docker_port=4533
        docker_rum="docker run -d --name navidrome --restart always -p 4533:4533 -v /home/docker/navidrome:/data deluan/navidrome:latest"
        docker_describe="Navidrome 私有音乐服务器"
        docker_url="官网: https://www.navidrome.org"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      23)
        docker_name="searxng"
        docker_img="searxng/searxng:latest"
        docker_port=8080
        docker_rum="docker run -d --name searxng --restart always -p 8080:8080 -v /home/docker/searxng:/etc/searxng searxng/searxng:latest"
        docker_describe="SearXNG 元搜索引擎（防追踪）"
        docker_url="官网: https://docs.searxng.org"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      24)
        docker_name="photoprism"
        docker_img="photoprism/photoprism:latest"
        docker_port=2342
        docker_rum="docker run -d --name photoprism --restart always -p 2342:2342 -v /home/docker/photoprism:/photoprism/storage -e PHOTOPRISM_ADMIN_PASSWORD=admin123 photoprism/photoprism:latest"
        docker_describe="PhotoPrism AI 照片管理"
        docker_url="官网: https://photoprism.app"
        docker_use="默认密码: admin123"
        docker_passwd=""
        docker_app ;;
      25)
        docker_name="sun-panel"
        docker_img="hslr/sun-panel:latest"
        docker_port=3002
        docker_rum="docker run -d --name sun-panel --restart always -p 3002:3002 -v /home/docker/sun-panel:/app/conf hslr/sun-panel:latest"
        docker_describe="Sun-Panel 导航面板（NAS/服务器导航）"
        docker_url="官网: https://sun-panel.top"
        docker_use="默认账号: admin@sun.cc  密码: 12345678"
        docker_passwd=""
        docker_app ;;
      26)
        docker_name="ragflow"
        docker_img="infiniflow/ragflow:latest"
        docker_port=9380
        docker_rum="docker run -d --name ragflow --restart always -p 9380:80 -v /home/docker/ragflow:/ragflow infiniflow/ragflow:latest"
        docker_describe="RAGFlow 深度文档理解知识库"
        docker_url="官网: https://ragflow.io"
        docker_use="建议使用 Docker Compose 完整部署"
        docker_passwd=""
        docker_app ;;
      27)
        docker_name="langfuse"
        docker_img="langfuse/langfuse:latest"
        docker_port=3003
        docker_rum="docker run -d --name langfuse --restart always -p 3003:3000 -v /home/docker/langfuse:/data langfuse/langfuse:latest"
        docker_describe="Langfuse LLM 可观测性与追踪"
        docker_url="官网: https://langfuse.com"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      28)
        docker_name="fastgpt"
        docker_img="registry.cn-hangzhou.aliyuncs.com/fastgpt/fastgpt:latest"
        docker_port=3004
        docker_rum="docker run -d --name fastgpt --restart always -p 3004:3000 -v /home/docker/fastgpt:/app/data registry.cn-hangzhou.aliyuncs.com/fastgpt/fastgpt:latest"
        docker_describe="FastGPT 知识库问答系统"
        docker_url="官网: https://fastgpt.in"
        docker_use="建议使用 Docker Compose 完整部署"
        docker_passwd=""
        docker_app ;;
      29)
        docker_name="grafana"
        docker_img="grafana/grafana:latest"
        docker_port=3005
        docker_rum="docker run -d --name grafana --restart always -p 3005:3000 -v /home/docker/grafana:/var/lib/grafana grafana/grafana:latest"
        docker_describe="Grafana 开源监控可视化面板"
        docker_url="官网: https://grafana.com"
        docker_use="默认账号: admin  密码: admin"
        docker_passwd=""
        docker_app ;;
      30)
        docker_name="speedtest"
        docker_img="adolfintel/speedtest:latest"
        docker_port=4867
        docker_rum="docker run -d --name speedtest --restart always -p 4867:80 adolfintel/speedtest:latest"
        docker_describe="Speedtest 网页版测速"
        docker_url="官网: https://github.com/adolfintel/speedtest"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      31)
        docker_name="drawio"
        docker_img="jgraph/drawio:latest"
        docker_port=8080
        docker_rum="docker run -d --name drawio --restart always -p 8080:8080 jgraph/drawio:latest"
        docker_describe="draw.io 免费在线图表绘制工具（流程图、架构图等）"
        docker_url="官网: https://www.drawio.com"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      32)
        docker_name="pingvin-share"
        docker_img="stonith404/pingvin-share:latest"
        docker_port=3000
        docker_rum="docker run -d --name pingvin-share --restart always -p 3000:3000 -v /home/docker/pingvin-share:/opt/app/backend/data stonith404/pingvin-share:latest"
        docker_describe="Pingvin Share 自托管文件分享平台"
        docker_url="官网: https://github.com/stonith404/pingvin-share"
        docker_use="首次访问注册管理员账号"
        docker_passwd=""
        docker_app ;;
      33)
        docker_name="myip"
        docker_img="jason5ng32/myip:latest"
        docker_port=18966
        docker_rum="docker run -d --name myip --restart always -p 18966:80 jason5ng32/myip:latest"
        docker_describe="MyIP 多功能 IP 信息工具箱（IP/网络/浏览器检测）"
        docker_url="官网: https://github.com/jason5ng32/MyIP"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      34)
        docker_name="webssh"
        docker_img="jrohy/webssh:latest"
        docker_port=5032
        docker_rum="docker run -d --name webssh --restart always -p 5032:5032 jrohy/webssh:latest"
        docker_describe="WebSSH 网页版 SSH 客户端，浏览器直接连接服务器"
        docker_url="官网: https://github.com/Jrohy/webssh"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      35)
        docker_name="rustdesk-server"
        docker_img="rustdesk/rustdesk-server:latest"
        docker_port=21115
        docker_rum="docker run -d --name rustdesk-server --restart always -p 21115:21115 -p 21116:21116 -p 21116:21116/udp -p 21117:21117 -v /home/docker/rustdesk:/data rustdesk/rustdesk-server:latest"
        docker_describe="RustDesk 开源远程桌面服务端（自建 TeamViewer）"
        docker_url="官网: https://rustdesk.com"
        docker_use="运行后查看日志获取 key: docker logs rustdesk-server"
        docker_passwd=""
        docker_app ;;
      36)
        docker_name="frps"
        docker_img="snowdreamtech/frps:latest"
        docker_port=7500
        docker_rum="docker run -d --name frps --restart always -p 7500:7500 -p 7000:7000 -p 7001:7001/udp -v /home/docker/frps:/etc/frp/conf snowdreamtech/frps:latest"
        docker_describe="FRP 内网穿透服务端（将内网服务暴露到公网）"
        docker_url="官网: https://github.com/fatedier/frp"
        docker_use="需编辑 /home/docker/frps/frps.toml 配置"
        docker_passwd=""
        docker_app ;;
      37)
        docker_name="newapi"
        docker_img="calciumion/new-api:latest"
        docker_port=3000
        docker_rum="docker run -d --name newapi --restart always -p 3000:3000 -v /home/docker/newapi:/data calciumion/new-api:latest"
        docker_describe="NewAPI 大模型 API 聚合管理平台（One API 升级版）"
        docker_url="官网: https://github.com/Calcium-Ion/new-api"
        docker_use="默认账号: admin  密码: 123456"
        docker_passwd=""
        docker_app ;;
      38)
        docker_name="yt-dlp"
        docker_img="jauderho/yt-dlp:latest"
        docker_port=0
        docker_rum="docker run -d --name yt-dlp --restart always -v /home/docker/yt-dlp:/downloads jauderho/yt-dlp:latest sleep infinity"
        docker_describe="yt-dlp 视频下载工具（支持 YouTube/B站等，通过 docker exec 使用）"
        docker_url="官网: https://github.com/jauderho/dockerfiles"
        docker_use="用法: docker exec yt-dlp yt-dlp -f best [URL]"
        docker_passwd=""
        docker_app ;;
      39)
        docker_name="beszel"
        docker_img="henrygd/beszel:latest"
        docker_port=8090
        docker_rum="docker run -d --name beszel --restart always -p 8090:8090 -v /home/docker/beszel:/data henrygd/beszel:latest"
        docker_describe="Beszel 轻量级服务器监控面板（资源占用极低）"
        docker_url="官网: https://github.com/henrygd/beszel"
        docker_use="首次访问设置管理员账号"
        docker_passwd=""
        docker_app ;;
      40)
        docker_name="dosgame"
        docker_img="oldiy/dosgame-web:latest"
        docker_port=262
        docker_rum="docker run -d --name dosgame --restart always -p 262:262 oldiy/dosgame-web:latest"
        docker_describe="在线 DOS 老游戏合集（怀旧经典）"
        docker_url="官网: https://github.com/rwv/dosgame-web"
        docker_use=""
        docker_passwd=""
        docker_app ;;
      0) break ;;
      *) echo -e "${red}无效的输入!${re}" ;;
    esac
  done
}

# ---------- 27. 内核参数一键调优 ----------
_fox_get_mem_mb() {
  awk '/MemTotal/{printf "%d", $2/1024}' /proc/meminfo
}

_fox_kernel_optimize_core() {
  local mode_name="$1"
  local scene="${2:-high}"
  local CONF="/etc/sysctl.d/99-foxtoolbox-optimize.conf"
  local MEM_MB=$(_fox_get_mem_mb)
  echo -e "${yellow}切换到 ${mode_name}...${re}"
  local SWAPPINESS DIRTY_RATIO DIRTY_BG_RATIO OVERCOMMIT MIN_FREE_KB VFS_PRESSURE
  local RMEM_MAX WMEM_MAX TCP_RMEM TCP_WMEM
  local SOMAXCONN BACKLOG SYN_BACKLOG
  local PORT_RANGE SCHED_AUTOGROUP THP NUMA FIN_TIMEOUT
  local KEEPALIVE_TIME KEEPALIVE_INTVL KEEPALIVE_PROBES
  case "$scene" in
    high|stream|game)
      SWAPPINESS=10; DIRTY_RATIO=15; DIRTY_BG_RATIO=5; OVERCOMMIT=1; VFS_PRESSURE=50
      RMEM_MAX=67108864; WMEM_MAX=67108864
      TCP_RMEM="4096 262144 67108864"; TCP_WMEM="4096 262144 67108864"
      SOMAXCONN=8192; BACKLOG=250000; SYN_BACKLOG=8192; PORT_RANGE="1024 65535"
      SCHED_AUTOGROUP=0; THP="never"; NUMA=0; FIN_TIMEOUT=10
      KEEPALIVE_TIME=300; KEEPALIVE_INTVL=30; KEEPALIVE_PROBES=5 ;;
    web)
      SWAPPINESS=10; DIRTY_RATIO=20; DIRTY_BG_RATIO=10; OVERCOMMIT=1; VFS_PRESSURE=50
      RMEM_MAX=33554432; WMEM_MAX=33554432
      TCP_RMEM="4096 131072 33554432"; TCP_WMEM="4096 131072 33554432"
      SOMAXCONN=16384; BACKLOG=10000; SYN_BACKLOG=16384; PORT_RANGE="1024 65535"
      SCHED_AUTOGROUP=0; THP="never"; NUMA=0; FIN_TIMEOUT=15
      KEEPALIVE_TIME=600; KEEPALIVE_INTVL=60; KEEPALIVE_PROBES=5 ;;
    balanced)
      SWAPPINESS=30; DIRTY_RATIO=20; DIRTY_BG_RATIO=10; OVERCOMMIT=0; VFS_PRESSURE=75
      RMEM_MAX=16777216; WMEM_MAX=16777216
      TCP_RMEM="4096 87380 16777216"; TCP_WMEM="4096 65536 16777216"
      SOMAXCONN=4096; BACKLOG=5000; SYN_BACKLOG=4096; PORT_RANGE="1024 49151"
      SCHED_AUTOGROUP=1; THP="always"; NUMA=1; FIN_TIMEOUT=30
      KEEPALIVE_TIME=600; KEEPALIVE_INTVL=60; KEEPALIVE_PROBES=5 ;;
  esac
  if [ "$MEM_MB" -ge 16384 ]; then MIN_FREE_KB=131072; [ "$scene" != "balanced" ] && SWAPPINESS=5
  elif [ "$MEM_MB" -ge 4096 ]; then MIN_FREE_KB=65536
  elif [ "$MEM_MB" -ge 1024 ]; then
    MIN_FREE_KB=32768
    if [ "$scene" != "balanced" ]; then RMEM_MAX=16777216; WMEM_MAX=16777216; TCP_RMEM="4096 87380 16777216"; TCP_WMEM="4096 65536 16777216"; fi
  else
    MIN_FREE_KB=16384; SWAPPINESS=30; OVERCOMMIT=0; RMEM_MAX=4194304; WMEM_MAX=4194304
    TCP_RMEM="4096 32768 4194304"; TCP_WMEM="4096 32768 4194304"; SOMAXCONN=1024; BACKLOG=1000
  fi
  local STREAM_EXTRA=""
  if [ "$scene" = "stream" ]; then
    STREAM_EXTRA="
# 直播推流 UDP 优化
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.ipv4.tcp_notsent_lowat = 16384"
  fi
  local GAME_EXTRA=""
  if [ "$scene" = "game" ]; then
    GAME_EXTRA="
# 游戏服低延迟优化
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_slow_start_after_idle = 0"
  fi
  local CC="bbr"; local QDISC="fq"; local KVER
  KVER=$(uname -r | grep -oP '^\d+\.\d+')
  if printf '%s\n%s' "4.9" "$KVER" | sort -V -C; then
    if ! lsmod 2>/dev/null | grep -q tcp_bbr; then modprobe tcp_bbr 2>/dev/null; fi
    if ! sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -q bbr; then CC="cubic"; QDISC="fq_codel"; fi
  else
    CC="cubic"; QDISC="fq_codel"
  fi
  [ -f "$CONF" ] && cp "$CONF" "${CONF}.bak.$(date +%s)"
  echo -e "${yellow}写入优化配置...${re}"
  cat > "$CONF" << SYSCTL
# FoxToolBox 内核调优配置
# 模式: $mode_name | 场景: $scene
# 内存: ${MEM_MB}MB | 生成时间: $(date '+%Y-%m-%d %H:%M:%S')

# ── TCP 拥塞控制 ──
net.core.default_qdisc = $QDISC
net.ipv4.tcp_congestion_control = $CC

# ── TCP 缓冲区 ──
net.core.rmem_max = $RMEM_MAX
net.core.wmem_max = $WMEM_MAX
net.core.rmem_default = $(echo "$TCP_RMEM" | awk '{print $2}')
net.core.wmem_default = $(echo "$TCP_WMEM" | awk '{print $2}')
net.ipv4.tcp_rmem = $TCP_RMEM
net.ipv4.tcp_wmem = $TCP_WMEM

# ── 连接队列 ──
net.core.somaxconn = $SOMAXCONN
net.core.netdev_max_backlog = $BACKLOG
net.ipv4.tcp_max_syn_backlog = $SYN_BACKLOG

# ── TCP 连接优化 ──
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = $FIN_TIMEOUT
net.ipv4.tcp_keepalive_time = $KEEPALIVE_TIME
net.ipv4.tcp_keepalive_intvl = $KEEPALIVE_INTVL
net.ipv4.tcp_keepalive_probes = $KEEPALIVE_PROBES
net.ipv4.tcp_max_tw_buckets = 65536
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1

# ── 端口与内存 ──
net.ipv4.ip_local_port_range = $PORT_RANGE
net.ipv4.tcp_mem = $((MEM_MB * 1024 / 8)) $((MEM_MB * 1024 / 4)) $((MEM_MB * 1024 / 2))
net.ipv4.tcp_max_orphans = 32768

# ── 虚拟内存 ──
vm.swappiness = $SWAPPINESS
vm.dirty_ratio = $DIRTY_RATIO
vm.dirty_background_ratio = $DIRTY_BG_RATIO
vm.overcommit_memory = $OVERCOMMIT
vm.min_free_kbytes = $MIN_FREE_KB
vm.vfs_cache_pressure = $VFS_PRESSURE

# ── CPU/内核调度 ──
kernel.sched_autogroup_enabled = $SCHED_AUTOGROUP
$([ -f /proc/sys/kernel/numa_balancing ] && echo "kernel.numa_balancing = $NUMA" || echo "# numa_balancing 不支持")

# ── 安全防护 ──
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# ── 文件描述符 ──
fs.file-max = 1048576
fs.nr_open = 1048576

# ── 连接跟踪 ──
$(if [ -f /proc/sys/net/netfilter/nf_conntrack_max ]; then
echo "net.netfilter.nf_conntrack_max = $((SOMAXCONN * 32))"
echo "net.netfilter.nf_conntrack_tcp_timeout_established = 7200"
echo "net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30"
echo "net.netfilter.nf_conntrack_tcp_timeout_close_wait = 15"
echo "net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 15"
else
echo "# conntrack 未启用"
fi)
$STREAM_EXTRA
$GAME_EXTRA
SYSCTL

  echo -e "${yellow}应用优化参数...${re}"
  local applied=0 skipped=0
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// /}" ]] && continue
    if sysctl -w "$line" >/dev/null 2>&1; then
      applied=$((applied + 1))
    else
      skipped=$((skipped + 1))
    fi
  done < "$CONF"
  echo -e "${green}已应用 ${applied} 项参数${re}${skipped:+，跳过 ${skipped} 项不支持的参数}"

  if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
    echo "$THP" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null
  fi

  if ! grep -q "# foxtoolbox-optimize" /etc/security/limits.conf 2>/dev/null; then
    cat >> /etc/security/limits.conf << 'LIMITS'

# foxtoolbox-optimize
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
LIMITS
  fi

  if [ "$CC" = "bbr" ]; then
    echo "tcp_bbr" > /etc/modules-load.d/bbr.conf 2>/dev/null
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf 2>/dev/null
  fi

  echo -e "${green}${mode_name} 优化完成！配置已持久化到 ${CONF}${re}"
  echo -e "${green}内存: ${MEM_MB}MB | 拥塞算法: ${CC} | 队列: ${QDISC}${re}"
}

_fox_kernel_restore() {
  echo -e "${yellow}还原到默认设置...${re}"
  local CONF="/etc/sysctl.d/99-foxtoolbox-optimize.conf"
  rm -f "$CONF"
  rm -f /etc/sysctl.d/99-network-optimize.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf 2>/dev/null
  sysctl --system 2>/dev/null | tail -1
  [ -f /sys/kernel/mm/transparent_hugepage/enabled ] && \n    echo always > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null
  if grep -q "# foxtoolbox-optimize" /etc/security/limits.conf 2>/dev/null; then
    sed -i '/# foxtoolbox-optimize/,+4d' /etc/security/limits.conf
  fi
  rm -f /etc/modules-load.d/bbr.conf 2>/dev/null
  echo -e "${green}系统已还原到默认设置${re}"
}

fox_kernel_optimize_menu() {
  while true; do
    clear
    local current_mode=$(grep "^# 模式:" /etc/sysctl.d/99-foxtoolbox-optimize.conf 2>/dev/null | sed 's/# 模式: //' | awk -F'|' '{print $1}' | xargs)
    echo "Linux系统内核参数优化"
    if [ -n "$current_mode" ]; then
      echo -e "当前模式: ${green}${current_mode}${re}"
    else
      echo -e "当前模式: ${yellow}未优化${re}"
    fi
    echo "------------------------------------------------"
    echo -e "${red}提示: 生产环境请谨慎使用！${re}"
    echo "--------------------"
    echo " 1. 高性能优化模式      最大化系统性能"
    echo " 2. 均衡优化模式        性能与资源平衡"
    echo " 3. 网站优化模式        高并发连接队列"
    echo " 4. 直播优化模式        UDP 缓冲加大"
    echo " 5. 游戏服优化模式      低延迟优先"
    echo " 6. 还原默认设置"
    echo "--------------------"
    echo " 0. 返回上一级选单"
    echo "--------------------"
    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
    case $sub_choice in
      1) clear; _fox_kernel_optimize_core "高性能优化模式" "high" ;;
      2) clear; _fox_kernel_optimize_core "均衡优化模式" "balanced" ;;
      3) clear; _fox_kernel_optimize_core "网站优化模式" "web" ;;
      4) clear; _fox_kernel_optimize_core "直播优化模式" "stream" ;;
      5) clear; _fox_kernel_optimize_core "游戏服优化模式" "game" ;;
      6) clear; _fox_kernel_restore ;;
      0) break ;;
      *) echo -e "${red}无效的输入!${re}" ;;
    esac
    read -p "按回车键继续..." x
  done
}

# ---------- 28. SSH 防御 fail2ban ----------
_fox_f2b_status() {
  if command -v fail2ban-client >/dev/null 2>&1; then
    echo -e "${green}已安装${re}"
  else
    echo -e "${yellow}未安装${re}"
  fi
}

_fox_f2b_sshd() {
  if grep -q 'Alpine' /etc/issue 2>/dev/null; then
    fail2ban-client status alpine-sshd 2>/dev/null || echo "jail 未启用"
  else
    fail2ban-client status sshd 2>/dev/null || echo "jail 未启用"
  fi
}

_fox_f2b_install() {
  docker rm -f fail2ban >/dev/null 2>&1
  install fail2ban
  if command -v systemctl >/dev/null 2>&1; then
    systemctl start fail2ban 2>/dev/null
    systemctl enable fail2ban 2>/dev/null
  elif command -v service >/dev/null 2>&1; then
    service fail2ban start 2>/dev/null
  fi
  if command -v apt >/dev/null 2>&1; then
    install rsyslog
    systemctl start rsyslog 2>/dev/null
    systemctl enable rsyslog 2>/dev/null
  fi
  mkdir -p /etc/fail2ban/jail.d
  local jail_name="sshd"
  grep -q 'Alpine' /etc/issue 2>/dev/null && jail_name="alpine-sshd"
  cat > /etc/fail2ban/jail.d/sshd.local <<EOF
[$jail_name]
enabled = true
bantime = 1h
findtime = 10m
maxretry = 5
logpath = /var/log/auth.log
EOF
  if command -v fail2ban-client >/dev/null 2>&1; then
    fail2ban-client reload 2>/dev/null
    sleep 2
  fi
  echo -e "${green}Fail2Ban 已安装并启用 SSH 防护${re}"
}

_fox_f2b_config() {
  if ! command -v fail2ban-client >/dev/null 2>&1; then
    echo -e "${yellow}未检测到 fail2ban，请先安装${re}"
    return
  fi
  local jail_name="sshd"
  grep -q 'Alpine' /etc/issue 2>/dev/null && jail_name="alpine-sshd"
  echo "即将配置 SSH jail：$jail_name"
  read -p "封禁时长 bantime (秒/分钟/小时，如 3600 或 1h) [默认 1h]: " bantime
  read -p "时间窗口 findtime (秒/分钟/小时，如 600 或 10m) [默认 10m]: " findtime
  read -p "重试次数 maxretry (整数) [默认 5]: " maxretry
  bantime=${bantime:-1h}
  findtime=${findtime:-10m}
  maxretry=${maxretry:-5}
  mkdir -p /etc/fail2ban/jail.d
  cat > /etc/fail2ban/jail.d/sshd.local <<EOF
[$jail_name]
enabled = true
bantime = $bantime
findtime = $findtime
maxretry = $maxretry
logpath = /var/log/auth.log
EOF
  fail2ban-client reload 2>/dev/null
  sleep 2
  echo -e "${green}已写入配置: /etc/fail2ban/jail.d/sshd.local${re}"
  _fox_f2b_sshd
}

fox_fail2ban_menu() {
  while true; do
    clear
    echo -e "SSH防御程序 $(_fox_f2b_status)"
    echo "fail2ban是一个SSH防止暴力破解工具"
    echo "官网: github.com/fail2ban/fail2ban"
    echo "------------------------"
    echo " 1. 安装防御程序"
    echo " 2. 查看SSH拦截记录"
    echo " 3. 日志实时监控"
    echo " 4. 基础参数配置（封禁时长/时间窗口/重试次数）"
    echo "------------------------"
    echo " 9. 卸载防御程序"
    echo " 0. 返回上一级选单"
    echo "------------------------"
    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
    case $sub_choice in
      1) clear; _fox_f2b_install ;;
      2)
        clear
        echo "------------------------"
        _fox_f2b_sshd
        echo "------------------------"
        ;;
      3) tail -f /var/log/fail2ban.log ;;
      4) clear; _fox_f2b_config ;;
      9)
        remove fail2ban
        rm -rf /etc/fail2ban
        echo -e "${green}Fail2Ban 已卸载${re}"
        break
        ;;
      0) break ;;
      *) echo "无效的输入!" ;;
    esac
    read -p "按回车键继续..." x
  done
}

# ---------- 29. 病毒扫描 ClamAV ----------
_fox_clamav_scan() {
  if [ $# -eq 0 ]; then
    echo "请指定要扫描的目录。"
    return
  fi
  echo -e "${yellow}正在扫描目录 $@ ...${re}"
  local MOUNT_PARAMS=""
  for dir in "$@"; do
    MOUNT_PARAMS+="--mount type=bind,source=${dir},target=/mnt/host${dir} "
  done
  local SCAN_PARAMS=""
  for dir in "$@"; do
    SCAN_PARAMS+="/mnt/host${dir} "
  done
  mkdir -p /home/docker/clamav/log/ > /dev/null 2>&1
  > /home/docker/clamav/log/scan.log
  docker run --rm \n    --name clamav \n    --mount source=clam_db,target=/var/lib/clamav \n    $MOUNT_PARAMS \n    -v /home/docker/clamav/log/:/var/log/clamav/ \n    clamav/clamav-debian:latest \n    clamscan -r --log=/var/log/clamav/scan.log $SCAN_PARAMS
  echo -e "${green}$@ 扫描完成，病毒报告存放: /home/docker/clamav/log/scan.log${re}"
  echo -e "${yellow}如有病毒请在 scan.log 中搜索 FOUND 关键字确定位置${re}"
}

fox_clamav_menu() {
  while true; do
    clear
    echo "clamav病毒扫描工具 (Docker版)"
    echo "------------------------"
    echo "开源的防病毒软件工具，检测恶意软件、病毒、木马等"
    echo "------------------------"
    echo " 1. 全盘扫描"
    echo " 2. 重要目录扫描"
    echo " 3. 自定义目录扫描"
    echo "------------------------"
    echo " 0. 返回上一级选单"
    echo "------------------------"
    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
    case $sub_choice in
      1)
        install_docker
        docker volume create clam_db > /dev/null 2>&1
        docker run --rm --name clamav --mount source=clam_db,target=/var/lib/clamav clamav/clamav-debian:latest freshclam
        _fox_clamav_scan /
        ;;
      2)
        install_docker
        docker volume create clam_db > /dev/null 2>&1
        docker run --rm --name clamav --mount source=clam_db,target=/var/lib/clamav clamav/clamav-debian:latest freshclam
        _fox_clamav_scan /etc /var /usr /home /root
        ;;
      3)
        read -p "请输入要扫描的目录，用空格分隔: " directories
        install_docker
        docker volume create clam_db > /dev/null 2>&1
        docker run --rm --name clamav --mount source=clam_db,target=/var/lib/clamav clamav/clamav-debian:latest freshclam
        _fox_clamav_scan $directories
        ;;
      0) break ;;
      *) echo "无效的输入!" ;;
    esac
    read -p "按回车键继续..." x
  done
}

# ---------- 30. 系统备份与还原 ----------
_fox_backup_list() {
  mkdir -p /backups
  echo "可用的备份："
  ls -1 /backups 2>/dev/null || echo "(无备份)"
}

_fox_backup_create() {
  mkdir -p /backups
  local TIMESTAMP=$(date +"%Y%m%d%H%M%S")
  echo "创建备份示例："
  echo "  - 备份单个目录: /var/www"
  echo "  - 备份多个目录: /etc /home /var/log"
  echo "  - 直接回车将使用默认目录 (/etc /usr /home)"
  read -p "请输入要备份的目录（多个目录用空格分隔，回车用默认）: " input
  if [ -z "$input" ]; then
    local BACKUP_PATHS=("/etc" "/usr" "/home")
  else
    IFS=' ' read -r -a BACKUP_PATHS <<< "$input"
  fi
  local PREFIX=""
  for path in "${BACKUP_PATHS[@]}"; do
    dir_name=$(basename "$path")
    PREFIX+="${dir_name}_"
  done
  PREFIX=${PREFIX%_}
  local BACKUP_NAME="${PREFIX}_$TIMESTAMP.tar.gz"
  echo "您选择的备份目录为："
  for path in "${BACKUP_PATHS[@]}"; do echo "- $path"; done
  echo "正在创建备份 $BACKUP_NAME..."
  install tar
  tar -czvf "/backups/$BACKUP_NAME" "${BACKUP_PATHS[@]}"
  if [ $? -eq 0 ]; then
    echo -e "${green}备份创建成功: /backups/$BACKUP_NAME${re}"
  else
    echo -e "${red}备份创建失败！${re}"
  fi
}

_fox_backup_restore() {
  mkdir -p /backups
  read -p "请输入要恢复的备份文件名: " BACKUP_NAME
  if [ ! -f "/backups/$BACKUP_NAME" ]; then
    echo "备份文件不存在！"
    return
  fi
  echo "正在恢复备份 $BACKUP_NAME..."
  tar -xzvf "/backups/$BACKUP_NAME" -C /
  if [ $? -eq 0 ]; then
    echo -e "${green}备份恢复成功！${re}"
  else
    echo -e "${red}备份恢复失败！${re}"
  fi
}

fox_backup_menu() {
  while true; do
    clear
    echo "系统备份功能"
    echo "------------------------"
    _fox_backup_list
    echo "------------------------"
    echo " 1. 创建备份        2. 恢复备份        3. 删除备份"
    echo "------------------------"
    echo " 0. 返回上一级选单"
    echo "------------------------"
    read -p $'\033[1;91m请输入你的选择: \033[0m' choice
    case $choice in
      1) _fox_backup_create ;;
      2) _fox_backup_restore ;;
      3)
        read -p "请输入要删除的备份文件名: " BACKUP_NAME
        rm -f "/backups/$BACKUP_NAME" && echo -e "${green}备份删除成功！${re}" || echo -e "${red}备份删除失败！${re}"
        ;;
      0) break ;;
      *) echo "无效的输入!" ;;
    esac
    read -p "按回车键继续..." x
  done
}

# ---------- 31. TG-bot 监控预警 ----------
_fox_tg_write_script() {
cat > /root/TG-check-notify.sh << 'EOF'
#!/bin/bash

# 你需要配置 Telegram Bot Token 和 Chat ID
TELEGRAM_BOT_TOKEN="输入TG的机器人API"
CHAT_ID="输入TG的接收通知的账号ID"

# 你可以修改监控阈值设置
CPU_THRESHOLD=70
MEMORY_THRESHOLD=70
DISK_THRESHOLD=70
NETWORK_THRESHOLD_GB=1000

# 获取设备信息
country=$(curl -s ipinfo.io/country 2>/dev/null)
isp_info=$(curl -s ipinfo.io/org 2>/dev/null | sed -e 's/"//g' | awk -F' ' '{print $2}')
ipv4_address=$(curl -s ipv4.ip.sb 2>/dev/null)
masked_ip=$(echo "$ipv4_address" | awk -F'.' '{print "*."$3"."$4}')

send_tg_notification() {
    local MESSAGE=$1
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$MESSAGE" > /dev/null 2>&1
}

get_cpu_usage() {
    awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f\n", (($2+$4-u1) * 100 / (t-t1))}' \n        <(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat)
}

get_memory_usage() {
    free | awk '/Mem/ {printf("%.0f"), $3/$2 * 100}'
}

get_disk_usage() {
    df / | awk 'NR==2 {print $5}' | sed 's/%//'
}

get_rx_bytes() {
    awk 'BEGIN { rx_total = 0 }
        $1 ~ /^(eth|ens|enp|eno)[0-9]+/ { rx_total += $2 }
        END { printf("%.2f", rx_total / (1024 * 1024 * 1024)); }' /proc/net/dev
}

get_tx_bytes() {
    awk 'BEGIN { tx_total = 0 }
        $1 ~ /^(eth|ens|enp|eno)[0-9]+/ { tx_total += $10 }
        END { printf("%.2f", tx_total / (1024 * 1024 * 1024)); }' /proc/net/dev
}

check_and_notify() {
    local USAGE=$1
    local TYPE=$2
    local THRESHOLD=$3
    local CURRENT_VALUE=$4
    if (( $(echo "$USAGE > $THRESHOLD" | bc -l) )); then
        send_tg_notification "警告: ${isp_info}-${country}-${masked_ip} 的 $TYPE 使用率已达到 $USAGE%，超过阈值 $THRESHOLD%。"
    fi
}

while true; do
    CPU_USAGE=$(get_cpu_usage)
    MEMORY_USAGE=$(get_memory_usage)
    DISK_USAGE=$(get_disk_usage)
    NETWORK_RX=$(get_rx_bytes)
    NETWORK_TX=$(get_tx_bytes)

    check_and_notify "$CPU_USAGE" "CPU" "$CPU_THRESHOLD" "$CPU_USAGE"
    check_and_notify "$MEMORY_USAGE" "内存" "$MEMORY_THRESHOLD" "$MEMORY_USAGE"
    check_and_notify "$DISK_USAGE" "硬盘" "$DISK_THRESHOLD" "$DISK_USAGE"

    if (( $(echo "$NETWORK_RX > $NETWORK_THRESHOLD_GB" | bc -l) )); then
        send_tg_notification "警告: ${isp_info}-${country}-${masked_ip} 的流量已达 ${NETWORK_RX}GB，超过阈值 ${NETWORK_THRESHOLD_GB}GB。"
    fi
    sleep 60
done
EOF
}

fox_tg_monitor() {
  clear
  echo "▶ TG-bot 监控预警功能"
  echo "------------------------------------------------"
  echo "您需要配置 TG 机器人 API 和接收预警的用户 ID，即可实现本机 CPU、内存、硬盘、流量、SSH 登录的实时监控预警"
  echo "到达阈值后会向用户发预警消息"
  echo -e "${yellow}- 关于流量，重启服务器将重新计算 -${re}"
  read -p "确定继续吗？(Y/N): " choice
  case "$choice" in
    [Yy])
      install nano tmux bc jq
      _fox_tg_write_script
      chmod +x /root/TG-check-notify.sh
      nano /root/TG-check-notify.sh
      tmux kill-session -t TG-check-notify > /dev/null 2>&1
      tmux new -d -s TG-check-notify "/root/TG-check-notify.sh"
      crontab -l | grep -v 'TG-check-notify.sh' | crontab - > /dev/null 2>&1
      (crontab -l ; echo "@reboot tmux new -d -s TG-check-notify '/root/TG-check-notify.sh'") | crontab - > /dev/null 2>&1
      clear
      echo -e "${green}TG-bot 预警系统已启动${re}"
      read -p "按回车键继续..." x
      ;;
    [Nn]) echo "已取消" ;;
    *) echo "无效的选择，请输入 Y 或 N。" ;;
  esac
}

# ---------- 32. s-ui / 3x-ui 官方版安装 ----------
fox_sui_install() {
  clear
  echo -e "${yellow}正在安装 s-ui (sing-box 面板) 官方版...${re}"
  bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh)
  read -p "按回车键继续..." x
}

fox_3xui_install() {
  clear
  echo -e "${yellow}正在安装 3x-ui (Xray 面板) 官方版...${re}"
  bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)
  read -p "按回车键继续..." x
}

# 运行统计
sum_run_times() {
  local COUNT=$(curl -s -m 2 "https://count.eooce.dpdns.org/?url=https://raw.githubusercontent.com/netjan666/FoxToolBox/main/fox_toolbox.sh") &&
  TODAY=$(echo "$COUNT" | sed -n 's/.*"daily_count": \([0-9]\+\).*/\1/p') &&
  TOTAL=$(echo "$COUNT" | sed -n 's/.*"total_count": \([0-9]\+\).*/\1/p')
}
sum_run_times

while true; do
clear
echo -e ""
echo -e "${red}    ███████╗ ██████╗ ██╗  ██╗    ████████╗ ██████╗  ██████╗ ██╗     ${re}"
echo -e "${yellow}    ██╔════╝██╔═══██╗╚██╗██╔╝    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ${re}"
echo -e "${green}    █████╗  ██║   ██║ ╚███╔╝        ██║   ██║   ██║██║   ██║██║     ${re}"
echo -e "${skyblue}    ██╔══╝  ██║   ██║ ██╔██╗        ██║   ██║   ██║██║   ██║██║     ${re}"
echo -e "${purple}    ██║     ╚██████╔╝██╔╝ ██╗       ██║   ╚██████╔╝╚██████╔╝███████╗ ${re}"
echo -e "${white}    ╚═╝      ╚═════╝ ╚═╝  ╚═╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝ ${re}"
echo -e ""
echo -e "    ${white}🔥 FoxToolBox v1.0${re}  ${purple}│${re}  ${white}多功能 VPS 管理工具箱${re}"
echo -e "    ${blue}🌐 ${white}https://github.com/netjan666/FoxToolBox${re}"
echo -e ""
echo -e "    ${cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"
echo -e "    ${yellow}📊 当日运行：${white}${TODAY}次${re}    ${yellow}累计运行：${white}${TOTAL}次${re}    ${green}支持 Ubuntu / Debian / CentOS / Alpine${re}"
echo -e "    ${cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"
echo -e ""
echo -e "    ${green}┌─ 📋 系统管理 ──────────────────────────────────────────┐${re}"
echo -e "    ${green}│${re}  ${yellow}1${re}.本机信息    ${yellow}2${re}.系统更新 ▶    ${yellow}3${re}.系统清理 ▶    ${yellow}4${re}.组件管理 ▶${re}${green}    │${re}"
echo -e "    ${green}│${re}  ${yellow}5${re}.BBR 加速管理${re}${green}                                        │${re}"
echo -e "    ${green}└──────────────────────────────────────────────────────────┘${re}"
echo -e ""
echo -e "    ${skyblue}┌─ 🐳 容器与建站 ────────────────────────────────────────┐${re}"
echo -e "    ${skyblue}│${re}  ${yellow}6${re}.Docker 管理 ▶  ${yellow}7${re}.WARP 加速 ▶${re}${skyblue}                            │${re}"
echo -e "    ${skyblue}│${re}  ${purple}8${re}.LDNMP 建站 ▶${re}${skyblue}                                         │${re}"
echo -e "    ${skyblue}└──────────────────────────────────────────────────────────┘${re}"
echo -e ""
echo -e "    ${blue}┌─ 🔧 工具与应用 ──────────────────────────────────────────┐${re}"
echo -e "    ${blue}│${re}  ${yellow}9${re}.面板工具 ▶   ${yellow}10${re}.系统工具 ▶   ${yellow}11${re}.工作区 ▶${re}${blue}          │${re}"
echo -e "    ${blue}│${re}  ${yellow}12${re}.节点搭建 ▶   ${yellow}13${re}.测试脚本 ▶   ${yellow}14${re}.甲骨文云 ▶${re}${blue}   │${re}"
echo -e "    ${blue}│${re}  ${yellow}15${re}.环境管理 ▶   ${yellow}16${re}.开设小鸡 ▶${re}${blue}                         │${re}"
echo -e "    ${blue}└──────────────────────────────────────────────────────────┘${re}"
echo -e ""
echo -e "    ${red}┌─ ⚡ 快捷操作 ────────────────────────────────────────────┐${re}"
echo -e "    ${red}│${re}  ${green}00${re}.脚本更新        ${red}88${re}.退出脚本${re}${red}                             │${re}"
echo -e "    ${red}└──────────────────────────────────────────────────────────┘${re}"
echo -e ""
read -p $'\033[1;91m    ⚡ 请输入你的选择: \033[0m' choice

case $choice in
  1)
    clear
    ip_address
    
    if [ "$(uname -m)" == "x86_64" ]; then
      cpu_info=$(cat /proc/cpuinfo | grep 'model name' | uniq | sed -e 's/model name[[:space:]]*: //')
    else
      cpu_info=$(lscpu | grep 'Model name' | sed -e 's/Model name[[:space:]]*: //')
    fi

    cpu_usage=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}')
    cpu_usage_percent=$(printf "%.2f" "$cpu_usage")%

    cpu_cores=$(nproc)

    mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2f MB (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')

    disk_info=$(df -h | awk '$NF=="/"{printf "%d/%dGB (%s)", $3,$2,$5}')

    country=$(curl -s ipinfo.io/country)
    city=$(curl -s ipinfo.io/city)

    isp_info=$(curl -s ipinfo.io/org)

    cpu_arch=$(uname -m)

    hostname=$(hostname)

    kernel_version=$(uname -r)

    congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
    queue_algorithm=$(sysctl -n net.core.default_qdisc)

    # 尝试使用 lsb_release 获取系统信息
    os_info=$(lsb_release -ds 2>/dev/null)

    # 如果 lsb_release 命令失败，则尝试其他方法
    if [ -z "$os_info" ]; then
      # 检查常见的发行文件
      if [ -f "/etc/os-release" ]; then
        os_info=$(source /etc/os-release && echo "$PRETTY_NAME")
      elif [ -f "/etc/debian_version" ]; then
        os_info="Debian $(cat /etc/debian_version)"
      elif [ -f "/etc/redhat-release" ]; then
        os_info=$(cat /etc/redhat-release)
      else
        os_info="Unknown"
      fi
    fi

    clear
    output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
        NR > 2 { rx_total += $2; tx_total += $10 }
        END {
            rx_units = "Bytes";
            tx_units = "Bytes";
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "KB"; }
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "MB"; }
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "GB"; }

            if (tx_total > 1024) { tx_total /= 1024; tx_units = "KB"; }
            if (tx_total > 1024) { tx_total /= 1024; tx_units = "MB"; }
            if (tx_total > 1024) { tx_total /= 1024; tx_units = "GB"; }

            printf("总接收: %.2f %s\n总发送: %.2f %s\n", rx_total, rx_units, tx_total, tx_units);
        }' /proc/net/dev)


    current_time=$(date "+%Y-%m-%d %I:%M %p")


    swap_used=$(free -m | awk 'NR==3{print $3}')
    swap_total=$(free -m | awk 'NR==3{print $2}')

    if [ "$swap_total" -eq 0 ]; then
        swap_percentage=0
    else
        swap_percentage=$((swap_used * 100 / swap_total))
    fi

    swap_info="${swap_used}MB/${swap_total}MB (${swap_percentage}%)"

    runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}')

    echo ""
    echo -e "${white}系统信息详情${re}"
    echo "------------------------"
    echo -e "${white}主机名: ${purple}${hostname}${re}"
    echo -e "${white}运营商: ${purple}${isp_info}${re}"
    echo "------------------------"
    echo -e "${white}系统版本: ${purple}${os_info}${re}"
    echo -e "${white}Linux版本: ${purple}${kernel_version}${re}"
    echo "------------------------"
    echo -e "${white}CPU架构: ${purple}${cpu_arch}${re}"
    echo -e "${white}CPU型号: ${purple}${cpu_info}${re}"
    echo -e "${white}CPU核心数: ${purple}${cpu_cores}${re}"
    echo "------------------------"
    echo -e "${white}CPU占用: ${purple}${cpu_usage_percent}${re}"
    echo -e "${white}物理内存: ${purple}${mem_info}${re}"
    echo -e "${white}虚拟内存: ${purple}${swap_info}${re}"
    echo -e "${white}硬盘占用: ${purple}${disk_info}${re}"
    echo "------------------------"
    echo -e "${purple}$output${re}"
    echo "------------------------"
    echo -e "${white}网络拥堵算法: ${purple}${congestion_algorithm} ${queue_algorithm}${re}"
    echo "------------------------"
    echo -e "${white}公网IPv4地址: ${purple}${ipv4_address}${re}"
    echo -e "${white}公网IPv6地址: ${purple}${ipv6_address}${re}"
    echo "------------------------"
    echo -e "${white}地理位置: ${purple}${country} $city${re}"
    echo -e "${white}系统时间: ${purple}${current_time}${re}"
    echo "------------------------"
    echo -e "${white}系统运行时长: ${purple}${runtime}${re}"
    echo

    ;;

  2)
    while true; do
      clear
      echo -e "${skyblue}┌─ 📦 系统更新 ─────────────────────────────────────────┐${re}"
      echo -e "${skyblue}│${re}  ${yellow}1${re}. 仅刷新软件源（apt update）${re}${skyblue}                          │${re}"
      echo -e "${skyblue}│${re}  ${yellow}2${re}. 完整升级系统（update + upgrade）${re}${skyblue}                    │${re}"
      echo -e "${skyblue}│${re}  ${yellow}3${re}. 仅升级安全补丁${re}${skyblue}                                     │${re}"
      echo -e "${skyblue}│${re}  ${yellow}4${re}. 更换国内软件源（阿里云/清华）${re}${skyblue}                       │${re}"
      echo -e "${skyblue}│${re}  ${red}0${re}. 返回主菜单${re}${skyblue}                                        │${re}"
      echo -e "${skyblue}└──────────────────────────────────────────────────────────┘${re}"
      read -p $'\033[1;91m    请选择: \033[0m' sub_choice
      case $sub_choice in
        1)
          clear
          echo -e "${yellow}▶ 正在刷新软件源...${re}"
          if command -v apt &>/dev/null; then
            apt-get update -y
          elif command -v dnf &>/dev/null; then
            dnf check-update
          elif command -v yum &>/dev/null; then
            yum check-update
          elif command -v apk &>/dev/null; then
            apk update
          fi
          echo -e "${green}✅ 软件源刷新完成${re}"
          read -p "按回车键返回..." x
          ;;
        2)
          clear
          echo -e "${yellow}将执行: ${white}apt update && apt upgrade -y${re}"
          read -p "是否继续? [Y/n]: " confirm
          case $confirm in
            [Nn]) echo "已取消"; read -p "按回车键返回..." x ;;
            *)
              if command -v apt &>/dev/null; then
                DEBIAN_FRONTEND=noninteractive apt-get update -y && apt-get upgrade -y
              elif command -v dnf &>/dev/null; then
                dnf check-update && dnf upgrade -y
              elif command -v yum &>/dev/null; then
                yum check-update && yum upgrade -y
              elif command -v apk &>/dev/null; then
                apk update && apk upgrade
              else
                echo -e "${red}不支持的Linux发行版${re}"
              fi
              echo -e "${green}✅ 系统升级完成${re}"
              read -p "按回车键返回..." x
              ;;
          esac
          ;;
        3)
          clear
          if command -v apt &>/dev/null; then
            echo -e "${yellow}▶ 正在升级安全补丁...${re}"
            DEBIAN_FRONTEND=noninteractive apt-get update -y && apt-get upgrade -y --only-upgrade $(apt list --upgradable 2>/dev/null | awk -F/ '/-security/{print $1}' | tr '\n' ' ')
          else
            echo -e "${yellow}▶ 正在升级系统（含安全补丁）...${re}"
            DEBIAN_FRONTEND=noninteractive apt-get update -y && apt-get upgrade -y
          fi
          echo -e "${green}✅ 安全补丁升级完成${re}"
          read -p "按回车键返回..." x
          ;;
        4)
          clear
          echo -e "${skyblue}┌─ 更换国内软件源 ─────────────────────────────────────┐${re}"
          echo -e "${skyblue}│${re}  ${yellow}1${re}. 阿里云源${re}${skyblue}                                          │${re}"
          echo -e "${skyblue}│${re}  ${yellow}2${re}. 清华源${re}${skyblue}                                           │${re}"
          echo -e "${skyblue}│${re}  ${red}0${re}. 取消${re}${skyblue}                                              │${re}"
          echo -e "${skyblue}└──────────────────────────────────────────────────────────┘${re}"
          read -p $'\033[1;91m    请选择: \033[0m' src_choice
          if [ "$src_choice" == "1" ] || [ "$src_choice" == "2" ]; then
            if command -v apt &>/dev/null; then
              CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
              if [ "$src_choice" == "1" ]; then
                MIRROR="mirrors.aliyun.com"
              else
                MIRROR="mirrors.tuna.tsinghua.edu.cn"
              fi
              cat > /etc/apt/sources.list <<EOF
deb http://${MIRROR}/ubuntu/ ${CODENAME} main restricted universe multiverse
deb http://${MIRROR}/ubuntu/ ${CODENAME}-updates main restricted universe multiverse
deb http://${MIRROR}/ubuntu/ ${CODENAME}-backports main restricted universe multiverse
deb http://${MIRROR}/ubuntu/ ${CODENAME}-security main restricted universe multiverse
EOF
              apt-get update -y
              echo -e "${green}✅ 软件源已切换 + 刷新完成${re}"
            else
              echo -e "${red}当前仅支持 Ubuntu/Debian 系统一键切换，可手动编辑 /etc/yum.repos.d/* 或 /etc/apk/repositories${re}"
            fi
          else
            echo "已取消"
          fi
          read -p "按回车键返回..." x
          ;;
        0|"")
          break
          ;;
        *)
          echo -e "${red}无效选择${re}"
          read -p "按回车键返回..." x
          ;;
      esac
    done
    ;;
  3)
    while true; do
      clear
      echo -e "${skyblue}┌─ 🧹 系统清理 ─────────────────────────────────────────┐${re}"
      echo -e "${skyblue}│${re}  ${yellow}1${re}. 一键清理（残留包+缓存+日志）${re}${skyblue}                       │${re}"
      echo -e "${skyblue}│${re}  ${yellow}2${re}. 仅清理软件包缓存${re}${skyblue}                                  │${re}"
      echo -e "${skyblue}│${re}  ${yellow}3${re}. 仅清理系统日志${re}${skyblue}                                    │${re}"
      echo -e "${skyblue}│${re}  ${yellow}4${re}. 清理旧内核（保留当前）${re}${skyblue}                             │${re}"
      echo -e "${skyblue}│${re}  ${red}0${re}. 返回主菜单${re}${skyblue}                                        │${re}"
      echo -e "${skyblue}└──────────────────────────────────────────────────────────┘${re}"
      read -p $'\033[1;91m    请选择: \033[0m' sub_choice
      case $sub_choice in
        1)
          clear
          echo -e "${yellow}将执行一键清理：残留包 + 缓存 + 日志${re}"
          read -p "是否继续? [Y/n]: " confirm
          case $confirm in
            [Nn]) echo "已取消"; read -p "按回车键返回..." x ;;
            *)
              if command -v apt &>/dev/null; then
                apt autoremove --purge -y && apt clean -y && apt autoclean -y
                apt remove --purge $(dpkg -l | awk '/^rc/ {print $2}') -y
                journalctl --vacuum-time=1s
                journalctl --vacuum-size=50M
              elif command -v yum &>/dev/null; then
                yum autoremove -y && yum clean all
                journalctl --vacuum-time=1s
                journalctl --vacuum-size=50M
              elif command -v dnf &>/dev/null; then
                dnf autoremove -y && dnf clean all
                journalctl --vacuum-time=1s
                journalctl --vacuum-size=50M
              elif command -v apk &>/dev/null; then
                apk autoremove -y
                apk clean
                journalctl --vacuum-time=1s
                journalctl --vacuum-size=50M
              fi
              echo -e "${green}✅ 清理完成${re}"
              read -p "按回车键返回..." x
              ;;
          esac
          ;;
        2)
          clear
          echo -e "${yellow}仅清理软件包缓存（安全，不删包）${re}"
          if command -v apt &>/dev/null; then
            apt clean -y && apt autoclean -y
          elif command -v yum &>/dev/null; then
            yum clean all
          elif command -v dnf &>/dev/null; then
            dnf clean all
          elif command -v apk &>/dev/null; then
            apk clean
          fi
          echo -e "${green}✅ 缓存清理完成${re}"
          read -p "按回车键返回..." x
          ;;
        3)
          clear
          echo -e "${yellow}仅清理系统日志（journalctl 真空）${re}"
          journalctl --vacuum-time=1s
          journalctl --vacuum-size=50M
          # 顺便清理 /var/log 下的旧日志文件
          find /var/log -type f -name "*.log" -mtime +7 -delete 2>/dev/null
          echo -e "${green}✅ 日志清理完成${re}"
          read -p "按回车键返回..." x
          ;;
        4)
          clear
          echo -e "${yellow}清理旧内核（保留当前运行内核）${re}"
          read -p "是否继续? [Y/n]: " confirm
          case $confirm in
            [Nn]) echo "已取消"; read -p "按回车键返回..." x ;;
            *)
              if command -v apt &>/dev/null; then
                apt remove --purge $(dpkg -l | awk '/^ii linux-(image|headers)-[^ ]+/{print $2}' | grep -v $(uname -r | sed 's/-.*//') | xargs) -y
              elif command -v yum &>/dev/null; then
                yum remove $(rpm -q kernel | grep -v $(uname -r)) -y
              elif command -v dnf &>/dev/null; then
                dnf remove $(rpm -q kernel | grep -v $(uname -r)) -y
              elif command -v apk &>/dev/null; then
                apk del $(apk info -vv | grep -E 'linux-[0-9]' | grep -v $(uname -r) | awk '{print $1}') -y
              fi
              echo -e "${green}✅ 旧内核清理完成${re}"
              read -p "按回车键返回..." x
              ;;
          esac
          ;;
        0|"")
          break
          ;;
        *)
          echo -e "${red}无效选择${re}"
          read -p "按回车键返回..." x
          ;;
      esac
    done
    ;;

  4)
  while true; do
      clear
      echo "▶ 组件管理"
      echo "------------------------"
      echo " 1. curl 下载工具"
      echo " 2. wget 下载工具"
      echo " 3. sudo 超级管理权限工具"
      echo " 4. socat 通信连接工具 （申请域名证书必备）"
      echo " 5. htop 系统监控工具"
      echo " 6. iftop 网络流量监控工具"
      echo " 7. unzip ZIP压缩解压工具"
      echo " 8. tar GZ压缩解压工具"
      echo " 9. tmux 多路后台运行工具"
      echo "10. ffmpeg 视频编码直播推流工具"
      echo "11. btop 现代化监控工具"
      echo "12. ranger 文件管理工具"
      echo "13. gdu 磁盘占用查看工具"
      echo "14. fzf 全局搜索工具"
      echo "15. screen后台会话工具"
      echo "16. masscan端口快速扫描工具"
      echo "------------------------"
      echo "21. cmatrix 黑客帝国屏保"
      echo "22. sl 跑火车屏保"
      echo "------------------------"
      echo "26. 俄罗斯方块小游戏"
      echo "27. 贪吃蛇小游戏 "
      echo "28. 太空入侵者小游戏"
      echo "------------------------"
      echo "31. 全部安装"
      echo -e "${red}32. 全部卸载${re}"
      echo "------------------------"
      echo -e "${yellow}41. 安装指定工具${re}"
      echo -e "${red}42. 卸载指定工具${re}"
      echo "------------------------"
      echo -e "${skyblue} 0. 返回主菜单${re}"
      echo "------------------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

      case $sub_choice in
          1)
              clear
              install curl
              clear
              echo "工具已安装，使用方法如下："
              curl --help
              ;;
          2)
              clear
              install wget
              clear
              echo "工具已安装，使用方法如下："
              wget --help
              ;;
            3)
              clear
              install sudo
              clear
              echo "工具已安装，使用方法如下："
              sudo --help
              ;;
            4)
              clear
              install socat
              clear
              echo "工具已安装，使用方法如下："
              socat -h
              ;;
            5)
              clear
              install htop
              clear
              htop
              ;;
            6)
              clear
              install iftop
              clear
              iftop
              ;;
            7)
              clear
              install unzip
              clear
              echo "工具已安装，使用方法如下："
              unzip
              ;;
            8)
              clear
              install tar
              clear
              echo "工具已安装，使用方法如下："
              tar --help
              ;;
            9)
              clear
              install tmux
              clear
              echo "工具已安装，使用方法如下："
              tmux --help
              ;;
            10)
              clear
              install ffmpeg
              clear
              echo "工具已安装，使用方法如下："
              ffmpeg --help
              ;;

            11)
              clear
              install btop
              clear
              btop
              ;;
            12)
              clear
              install ranger
              cd /
              clear
              ranger
              cd ~
              ;;
            13)
              clear
              install gdu
              cd /
              clear
              gdu
              cd ~
              ;;
            14)
              clear
              install fzf
              cd /
              clear
              fzf
              cd ~
              ;;
            15)
              clear
                # 检测 CentOS 系统
                if [ -f /etc/os-release ]; then
                    os_name=$(grep '^ID=' /etc/os-release | cut -d= -f2)
                elif command -v lsb_release > /dev/null 2>&1; then
                    # 如果 os-release 文件不存在，则使用 lsb_release
                    os_name=$(lsb_release -i | cut -f2)
                else
                    echo "无法确定操作系统类型。"
                    exit 1
                fi
                os_name=$(echo $os_name | tr -d '"')
                if [ "$os_name" = "centos" ] || [ "$os_name" = "rocky" ]; then
                    yum install epel-release -y
                    yum install screen -y
                elif [ "$os_name" = "amzn" ]; then
                    amazon-linux-extras install epel
                    yum install screen -y                    
                else
                    install screen
                fi
                cd ~
              ;;
            16)
              clear
                # 检测 CentOS 系统
                if [ -f /etc/os-release ]; then
                    os_name=$(grep '^ID=' /etc/os-release | cut -d= -f2)
                elif command -v lsb_release > /dev/null 2>&1; then
                    # 如果 os-release 文件不存在，则使用 lsb_release
                    os_name=$(lsb_release -i | cut -f2)
                else
                    echo "无法确定操作系统类型。"
                    exit 1
                fi
                os_name=$(echo $os_name | tr -d '"')
                if [ "$os_name" = "centos" ] || [ "$os_name" = "rocky" ]; then
                    yum install epel-release -y
                    yum install masscan -y
                elif [ "$os_name" = "amzn" ]; then
                    amazon-linux-extras install epel
                    yum install masscan -y                    
                else
                    install masscan
                fi
                cd ~
              ;;
            21)
              clear
              install cmatrix
              clear
              cmatrix
              ;;
            22)
              clear
              install sl
              clear
              /usr/games/sl
              ;;
            26)
              clear
              install bastet
              clear
              /usr/games/bastet
              ;;
            27)
              clear
              install nsnake
              clear
              /usr/games/nsnake
              ;;
            28)
              clear
              install ninvaders
              clear
              /usr/games/ninvaders

              ;;

          31)
              clear
              install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger gdu fzf cmatrix sl bastet nsnake ninvaders
              ;;

          32)
              clear
              remove htop iftop unzip tmux ffmpeg btop ranger gdu fzf cmatrix sl bastet nsnake ninvaders
              ;;

          41)
              clear
              read -p "请输入安装的工具名（wget curl sudo htop）: " installname
              install $installname
              ;;
          42)
              clear
              read -p "请输入卸载的工具名（htop ufw tmux cmatrix）: " removename
              remove $removename
              ;;

          0)
              main_menu

              ;;

          *)
              echo "无效的输入!"
              ;;
      esac
      break_end
  done

    ;;

  5)
    clear
    install wget
    wget --no-check-certificate -O tcpx.sh https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh && chmod +x tcpx.sh && ./tcpx.sh
    rm tcpx.sh
    break_end
    main_menu
    ;;

  6)
    while true; do
      clear
      echo "▶ Docker管理器"
      echo "------------------------"
      echo "1. 安装更新Docker环境"
      echo "------------------------"
      echo "2. 查看Dcoker全局状态"
      echo "------------------------"
      echo "3. Dcoker容器管理 ▶"
      echo "4. Dcoker镜像管理 ▶"
      echo "5. Dcoker网络管理 ▶"
      echo "6. Dcoker卷管理 ▶"
      echo "------------------------"
      echo "7. 清理无用的docker容器和镜像网络数据卷"
      echo "------------------------"
      echo -e "${red}8. 卸载Dcoker环境${re}"
      echo "------------------------"
      echo -e "${skyblue} 0. 返回主菜单${re}"
      echo "------------------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

      case $sub_choice in
          1)
              clear
              curl -fsSL https://get.docker.com | sh && ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin
              systemctl start docker
              systemctl enable docker
              ;;
          2)
              clear
              echo "Dcoker版本"
              docker --version
              docker-compose --version
              echo ""
              echo "Dcoker镜像列表"
              docker image ls
              echo ""
              echo "Dcoker容器列表"
              docker ps -a
              echo ""
              echo "Dcoker卷列表"
              docker volume ls
              echo ""
              echo "Dcoker网络列表"
              docker network ls
              echo ""

              ;;
          3)
              while true; do
                  clear
                  echo "Docker容器列表"
                  docker ps -a
                  echo ""
                  echo "容器操作"
                  echo "------------------------"
                  echo " 1. 创建新的容器"
                  echo "------------------------"
                  echo " 2. 启动指定容器             6. 启动所有容器"
                  echo " 3. 停止指定容器             7. 暂停所有容器"
                  echo " 4. 删除指定容器             8. 删除所有容器"
                  echo " 5. 重启指定容器             9. 重启所有容器"
                  echo "------------------------"
                  echo "11. 进入指定容器           12. 查看容器日志           13. 查看容器网络"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                          read -p "请输入创建命令: " dockername
                          $dockername
                          ;;

                      2)
                          read -p "请输入容器名: " dockername
                          docker start $dockername
                          ;;
                      3)
                          read -p "请输入容器名: " dockername
                          docker stop $dockername
                          ;;
                      4)
                          read -p "请输入容器名: " dockername
                          docker rm -f $dockername
                          ;;
                      5)
                          read -p "请输入容器名: " dockername
                          docker restart $dockername
                          ;;
                      6)
                          docker start $(docker ps -a -q)
                          ;;
                      7)
                          docker stop $(docker ps -q)
                          ;;
                      8)
                          read -p "确定删除所有容器吗？(Y/N): " choice
                          case "$choice" in
                            [Yy])
                              docker rm -f $(docker ps -a -q)
                              ;;
                            [Nn])
                              ;;
                            *)
                              echo "无效的选择，请输入 Y 或 N。"
                              ;;
                          esac
                          ;;
                      9)
                          docker restart $(docker ps -q)
                          ;;
                      11)
                          read -p "请输入容器名: " dockername
                          docker exec -it $dockername /bin/bash
                          break_end
                          ;;
                      12)
                          read -p "请输入容器名: " dockername
                          docker logs $dockername
                          break_end
                          ;;
                      13)
                          echo ""
                          container_ids=$(docker ps -q)

                          echo "------------------------------------------------------------"
                          printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"

                          for container_id in $container_ids; do
                              container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")

                              container_name=$(echo "$container_info" | awk '{print $1}')
                              network_info=$(echo "$container_info" | cut -d' ' -f2-)

                              while IFS= read -r line; do
                                  network_name=$(echo "$line" | awk '{print $1}')
                                  ip_address=$(echo "$line" | awk '{print $2}')

                                  printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
                              done <<< "$network_info"
                          done

                          break_end
                          ;;

                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;
                  esac
              done
              ;;
          4)
              while true; do
                  clear
                  echo "Docker镜像列表"
                  docker image ls
                  echo ""
                  echo "镜像操作"
                  echo "------------------------"
                  echo "1. 获取指定镜像             3. 删除指定镜像"
                  echo "2. 更新指定镜像             4. 删除所有镜像"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                          read -p "请输入镜像名: " dockername
                          docker pull $dockername
                          ;;
                      2)
                          read -p "请输入镜像名: " dockername
                          docker pull $dockername
                          ;;
                      3)
                          read -p "请输入镜像名: " dockername
                          docker rmi -f $dockername
                          ;;
                      4)
                          read -p "确定删除所有镜像吗？(Y/N): " choice
                          case "$choice" in
                            [Yy])
                              docker rmi -f $(docker images -q)
                              ;;
                            [Nn])

                              ;;
                            *)
                              echo "无效的选择，请输入 Y 或 N。"
                              ;;
                          esac
                          ;;
                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;
                  esac
              done
              ;;

          5)
              while true; do
                  clear
                  echo "Docker网络列表"
                  echo "------------------------------------------------------------"
                  docker network ls
                  echo ""

                  echo "------------------------------------------------------------"
                  container_ids=$(docker ps -q)
                  printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"

                  for container_id in $container_ids; do
                      container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")

                      container_name=$(echo "$container_info" | awk '{print $1}')
                      network_info=$(echo "$container_info" | cut -d' ' -f2-)

                      while IFS= read -r line; do
                          network_name=$(echo "$line" | awk '{print $1}')
                          ip_address=$(echo "$line" | awk '{print $2}')

                          printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
                      done <<< "$network_info"
                  done

                  echo ""
                  echo "网络操作"
                  echo "------------------------"
                  echo "1. 创建网络"
                  echo "2. 加入网络"
                  echo "3. 退出网络"
                  echo "4. 删除网络"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                          read -p "设置新网络名: " dockernetwork
                          docker network create $dockernetwork
                          ;;
                      2)
                          read -p "加入网络名: " dockernetwork
                          read -p "那些容器加入该网络: " dockername
                          docker network connect $dockernetwork $dockername
                          echo ""
                          ;;
                      3)
                          read -p "退出网络名: " dockernetwork
                          read -p "那些容器退出该网络: " dockername
                          docker network disconnect $dockernetwork $dockername
                          echo ""
                          ;;

                      4)
                          read -p "请输入要删除的网络名: " dockernetwork
                          docker network rm $dockernetwork
                          ;;
                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;
                  esac
              done
              ;;

          6)
              while true; do
                  clear
                  echo "Docker卷列表"
                  docker volume ls
                  echo ""
                  echo "卷操作"
                  echo "------------------------"
                  echo "1. 创建新卷"
                  echo "2. 删除卷"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                          read -p "设置新卷名: " dockerjuan
                          docker volume create $dockerjuan

                          ;;
                      2)
                          read -p "输入删除卷名: " dockerjuan
                          docker volume rm $dockerjuan

                          ;;
                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;
                  esac
              done
              ;;
          7)
              clear
              read -p "确定清理无用的镜像容器网络吗？(Y/N): " choice
              case "$choice" in
                [Yy])
                  docker system prune -af --volumes
                  ;;
                [Nn])
                  ;;
                *)
                  echo "无效的选择，请输入 Y 或 N。"
                  ;;
              esac
              ;;
          8)
              clear
              read -p "确定卸载docker环境吗？(Y/N): " choice
              case "$choice" in
                [Yy])
                  docker rm $(docker ps -a -q) && docker rmi $(docker images -q) && docker network prune
                  remove docker docker-ce > /dev/null 2>&1
                  rm -rf /var/lib/docker
                  ;;
                [Nn])
                  ;;
                *)
                  echo "无效的选择，请输入 Y 或 N。"
                  ;;
              esac
              ;;
          0)
              main_menu

              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      break_end


    done

    ;;


  7)
    clear
    install wget
    wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh [option] [lisence/url/token]
    ;;

  8)
  linux_ldnmp
  ;;


  9)
    while true; do
      clear
      echo "▶ 面板工具"
      echo "------------------------"
      echo " 1. 宝塔面板官方版                        2. aaPanel宝塔国际版"
      echo " 3. 1Panel新一代管理面板                  4. NginxProxyManager可视化面板"
      echo " 5. AList多存储文件列表程序               6. Ubuntu远程桌面网页版"
      echo " 7. 哪吒探针VPS监控面板                   8. QB离线BT磁力下载面板"
      echo " 9. Poste.io邮件服务器程序               10. RocketChat多人在线聊天系统"
      echo "11. 禅道项目管理软件                     12. 青龙面板定时任务管理平台"
      echo "13. Cloudreve网盘系统                    14. 简单图床图片管理程序"
      echo "15. emby多媒体管理系统                   16. Speedtest测速服务面板"
      echo "17. AdGuardHome去广告软件                18. onlyoffice在线办公OFFICE"
      echo "19. 雷池WAF防火墙面板                    20. portainer容器管理面板"
      echo "21. VScode网页版                         22. UptimeKuma监控工具"
      echo "23. Memos网页备忘录                     24. s-ui代理面板"
      echo "25. 3x-ui代理面板                        "
      echo "------------------------"
      echo -e "${skyblue} 0. 返回主菜单${re}"
      echo "------------------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

      case $sub_choice in
          1)
            if [ -f "/etc/init.d/bt" ] && [ -d "/www/server/panel" ]; then
                clear
                echo "宝塔面板已安装，应用操作"
                echo ""
                echo "------------------------"
                echo "1. 管理宝塔面板           2. 卸载宝塔面板"
                echo "------------------------"
                echo "0. 返回上一级选单"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                case $sub_choice in
                    1)
                        clear
                        # 更新宝塔面板操作
                        bt
                        ;;
                    2)
                        clear
                        curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh > /dev/null 2>&1
                        chmod +x bt-uninstall.sh
                        ./bt-uninstall.sh
                        ;;
                    0)
                        break  # 跳出循环，退出菜单
                        ;;
                    *)
                        break  # 跳出循环，退出菜单
                        ;;
                esac
            else
                clear
                echo "安装提示"
                echo "如果您已经安装了其他面板工具或者LDNMP建站环境，建议先卸载，再安装宝塔面板！"
                echo "会根据系统自动安装，支持Debian，Ubuntu，Centos"
                echo "官网介绍: https://www.bt.cn/new/index.html"
                echo ""

                # 获取当前系统类型
                get_system_type() {
                    if [ -f /etc/os-release ]; then
                        . /etc/os-release
                        if [ "$ID" == "centos" ]; then
                            echo "centos"
                        elif [ "$ID" == "ubuntu" ]; then
                            echo "ubuntu"
                        elif [ "$ID" == "debian" ]; then
                            echo "debian"
                        else
                            echo "unknown"
                        fi
                    else
                        echo "unknown"
                    fi
                }

                system_type=$(get_system_type)

                if [ "$system_type" == "unknown" ]; then
                    echo "不支持的操作系统类型"
                else
                    read -p "确定安装宝塔吗？(Y/N): " choice
                    case "$choice" in
                        [Yy])
                            iptables_open
                            install wget
                            if [ "$system_type" == "centos" ]; then
                                yum install -y wget && wget -O install.sh https://download.bt.cn/install/install_6.0.sh && sh install.sh ed8484bec
                            elif [ "$system_type" == "ubuntu" ]; then
                                wget -O install.sh https://download.bt.cn/install/install-ubuntu_6.0.sh && bash install.sh ed8484bec
                            elif [ "$system_type" == "debian" ]; then
                                wget -O install.sh https://download.bt.cn/install/install-ubuntu_6.0.sh && bash install.sh ed8484bec
                            fi
                            ;;
                        [Nn])
                            ;;
                        *)
                            ;;
                    esac
                fi
            fi

              ;;
          2)
            if [ -f "/etc/init.d/bt" ] && [ -d "/www/server/panel" ]; then
                clear
                echo "aaPanel已安装，应用操作"
                echo ""
                echo "------------------------"
                echo "1. 管理aaPanel           2. 卸载aaPanel"
                echo "------------------------"
                echo "0. 返回上一级选单"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                case $sub_choice in
                    1)
                        clear
                        # 更新aaPanel操作
                        bt
                        ;;
                    2)
                        clear
                        curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh > /dev/null 2>&1
                        chmod +x bt-uninstall.sh
                        ./bt-uninstall.sh
                        ;;
                    0)
                        break  # 跳出循环，退出菜单
                        ;;
                    *)
                        break  # 跳出循环，退出菜单
                        ;;
                esac
            else
                clear
                echo "安装提示"
                echo "如果您已经安装了其他面板工具或者LDNMP建站环境，建议先卸载，再安装aaPanel！"
                echo "会根据系统自动安装，支持Debian，Ubuntu，Centos"
                echo "官网介绍: https://www.aapanel.com/new/index.html"
                echo ""

                # 获取当前系统类型
                get_system_type() {
                    if [ -f /etc/os-release ]; then
                        . /etc/os-release
                        if [ "$ID" == "centos" ]; then
                            echo "centos"
                        elif [ "$ID" == "ubuntu" ]; then
                            echo "ubuntu"
                        elif [ "$ID" == "debian" ]; then
                            echo "debian"
                        else
                            echo "unknown"
                        fi
                    else
                        echo "unknown"
                    fi
                }

                system_type=$(get_system_type)

                if [ "$system_type" == "unknown" ]; then
                    echo "不支持的操作系统类型"
                else
                    read -p "确定安装aaPanel吗？(Y/N): " choice
                    case "$choice" in
                        [Yy])
                            iptables_open
                            install wget
                            if [ "$system_type" == "centos" ]; then
                                yum install -y wget && wget -O install.sh http://www.aapanel.com/script/install_6.0_en.sh && bash install.sh aapanel
                            elif [ "$system_type" == "ubuntu" ]; then
                                wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash install.sh aapanel
                            elif [ "$system_type" == "debian" ]; then
                                wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash install.sh aapanel
                            fi
                            ;;
                        [Nn])
                            ;;
                        *)
                            ;;
                    esac
                fi
            fi
              ;;
          3)
            if command -v 1pctl &> /dev/null; then
                clear
                echo "1Panel已安装，应用操作"
                echo ""
                echo "------------------------"
                echo "1. 查看1Panel信息           2. 卸载1Panel"
                echo "------------------------"
                echo "0. 返回上一级选单"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                case $sub_choice in
                    1)
                        clear
                        1pctl user-info
                        1pctl update password
                        ;;
                    2)
                        clear
                        1pctl uninstall

                        ;;
                    0)
                        break  # 跳出循环，退出菜单
                        ;;
                    *)
                        break  # 跳出循环，退出菜单
                        ;;
                esac
            else

                clear
                echo "安装提示"
                echo "如果您已经安装了其他面板工具或者LDNMP建站环境，建议先卸载，再安装1Panel！"
                echo "会根据系统自动安装，支持Debian，Ubuntu，Centos"
                echo "官网介绍: https://1panel.cn/"
                echo ""
                # 获取当前系统类型
                get_system_type() {
                  if [ -f /etc/os-release ]; then
                    . /etc/os-release
                    if [ "$ID" == "centos" ]; then
                      echo "centos"
                    elif [ "$ID" == "ubuntu" ]; then
                      echo "ubuntu"
                    elif [ "$ID" == "debian" ]; then
                      echo "debian"
                    else
                      echo "unknown"
                    fi
                  else
                    echo "unknown"
                  fi
                }

                system_type=$(get_system_type)

                if [ "$system_type" == "unknown" ]; then
                  echo "不支持的操作系统类型"
                else
                  read -p "确定安装1Panel吗？(Y/N): " choice
                  case "$choice" in
                    [Yy])
                      iptables_open
                      install_docker
                      if [ "$system_type" == "centos" ]; then
                        curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && sh quick_start.sh
                      elif [ "$system_type" == "ubuntu" ]; then
                        curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
                      elif [ "$system_type" == "debian" ]; then
                        curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
                      fi
                      ;;
                    [Nn])
                      ;;
                    *)
                      ;;
                  esac
                fi
            fi
            ;;
          4)

            docker_name="npm"
            docker_img="jc21/nginx-proxy-manager:latest"
            docker_port=81
            docker_rum="docker run -d \
                          --name=$docker_name \
                          -p 80:80 \
                          -p 81:$docker_port \
                          -p 443:443 \
                          -v /home/docker/npm/data:/data \
                          -v /home/docker/npm/letsencrypt:/etc/letsencrypt \
                          --restart=always \
                          $docker_img"
            docker_describe="如果您已经安装了其他面板工具或者LDNMP建站环境，建议先卸载，再安装npm！"
            docker_url="官网介绍: https://nginxproxymanager.com/"
            docker_use="echo \"初始用户名: admin@example.com\""
            docker_passwd="echo \"初始密码: changeme\""

            docker_app

              ;;

          5)

            docker_name="alist"
            docker_img="xhofe/alist:latest"
            docker_port=5244
            docker_rum="docker run -d \
                                --restart=always \
                                -v /home/docker/alist:/opt/alist/data \
                                -p 5244:5244 \
                                -e PUID=0 \
                                -e PGID=0 \
                                -e UMASK=022 \
                                --name="alist" \
                                xhofe/alist:latest"
            docker_describe="一个支持多种存储，支持网页浏览和 WebDAV 的文件列表程序，由 gin 和 Solidjs 驱动"
            docker_url="官网介绍: https://alist.nn.ci/zh/"
            docker_use="docker exec -it alist ./alist admin random"
            docker_passwd=""

            docker_app

              ;;

          6)
            docker_name="ubuntu-novnc"
            docker_img="fredblgr/ubuntu-novnc:20.04"
            docker_port=6080
            rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
            docker_rum="docker run -d \
                                --name ubuntu-novnc \
                                -p 6080:80 \
                                -v /home/docker/ubuntu-novnc:/workspace:rw \
                                -e HTTP_PASSWORD=$rootpasswd \
                                -e RESOLUTION=1280x720 \
                                --restart=always \
                                fredblgr/ubuntu-novnc:20.04"
            docker_describe="一个网页版Ubuntu远程桌面，挺好用的！"
            docker_url="官网介绍: https://hub.docker.com/r/fredblgr/ubuntu-novnc"
            docker_use="echo \"用户名: root\""
            docker_passwd="echo \"密码: $rootpasswd\""

            docker_app

              ;;
          7)
            clear
            curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh  -o nezha.sh && chmod +x nezha.sh
            ./nezha.sh
              ;;

          8)

            docker_name="qbittorrent"
            docker_img="lscr.io/linuxserver/qbittorrent:latest"
            docker_port=8081
            docker_rum="docker run -d \
                                  --name=qbittorrent \
                                  -e PUID=1000 \
                                  -e PGID=1000 \
                                  -e TZ=Etc/UTC \
                                  -e WEBUI_PORT=8081 \
                                  -p 8081:8081 \
                                  -p 6881:6881 \
                                  -p 6881:6881/udp \
                                  -v /home/docker/qbittorrent/config:/config \
                                  -v /home/docker/qbittorrent/downloads:/downloads \
                                  --restart unless-stopped \
                                  lscr.io/linuxserver/qbittorrent:latest"
            docker_describe="qbittorrent离线BT磁力下载服务"
            docker_url="官网介绍: https://hub.docker.com/r/linuxserver/qbittorrent"
            docker_use="sleep 3"
            docker_passwd="docker logs qbittorrent"

            docker_app

              ;;

          9)
            if docker inspect mailserver &>/dev/null; then

                    clear
                    echo "poste.io已安装，访问地址: "
                    yuming=$(cat /home/docker/mail.txt)
                    echo "https://$yuming"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f mailserver
                            docker rmi -f analogic/poste.io
                            install_docker
                            yuming=$(cat /home/docker/mail.txt)
                            docker run \
                                --net=host \
                                -e TZ=Europe/Prague \
                                -v /home/docker/mail:/data \
                                --name "mailserver" \
                                -h "$yuming" \
                                --restart=always \
                                -d analogic/poste.io

                            clear
                            echo "poste.io已经安装完成"
                            echo "------------------------"
                            echo "您可以使用以下地址访问poste.io:"
                            echo "https://$yuming"
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f mailserver
                            docker rmi -f analogic/poste.io
                            rm /home/docker/mail.txt
                            rm -rf /home/docker/mail
                            echo "应用已卸载"
                            ;;
                        0)
                            break  # 跳出循环，退出菜单
                            ;;
                        *)
                            break  # 跳出循环，退出菜单
                            ;;
                    esac
            else
                clear
                install telnet

                clear
                echo ""
                echo "端口检测"
                port=25
                timeout=3

                if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
                  echo -e "\e[32m端口$port当前可用\e[0m"
                else
                  echo -e "\e[31m端口$port当前不可用\e[0m"
                fi
                echo "------------------------"
                echo ""


                echo "安装提示"
                echo "poste.io一个邮件服务器，确保80和443端口没被占用，确保25端口开放"
                echo "官网介绍: https://hub.docker.com/r/analogic/poste.io"
                echo ""

                # 提示用户确认安装
                read -p "确定安装poste.io吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear

                    read -p "请设置邮箱域名 例如 mail.yuming.com : " yuming
                    mkdir -p /home/docker      # 递归创建目录
                    echo "$yuming" > /home/docker/mail.txt  # 写入文件
                    echo "------------------------"
                    ip_address
                    echo "先解析这些DNS记录"
                    echo "A           mail            $ipv4_address"
                    echo "CNAME       imap            $yuming"
                    echo "CNAME       pop             $yuming"
                    echo "CNAME       smtp            $yuming"
                    echo "MX          @               $yuming"
                    echo "TXT         @               v=spf1 mx ~all"
                    echo "TXT         ?               ?"
                    echo ""
                    echo "------------------------"
                    echo "按任意键继续..."
                    read -n 1 -s -r -p ""

                    install_docker

                    docker run \
                        --net=host \
                        -e TZ=Europe/Prague \
                        -v /home/docker/mail:/data \
                        --name "mailserver" \
                        -h "$yuming" \
                        --restart=always \
                        -d analogic/poste.io

                    clear
                    echo "poste.io已经安装完成"
                    echo "------------------------"
                    echo "您可以使用以下地址访问poste.io:"
                    echo "https://$yuming"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi
              ;;

          10)
            if docker inspect rocketchat &>/dev/null; then


                    clear
                    echo "rocket.chat已安装，访问地址: "
                    ip_address
                    echo "http:$ipv4_address:3897"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f rocketchat
                            docker rmi -f rocket.chat:6.3
                            install_docker

                            docker run --name rocketchat --restart=always -p 3897:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat

                            clear
                            ip_address
                            echo "rocket.chat已经安装完成"
                            echo "------------------------"
                            echo "多等一会，您可以使用以下地址访问rocket.chat:"
                            echo "http:$ipv4_address:3897"
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f rocketchat
                            docker rmi -f rocket.chat
                            docker rmi -f rocket.chat:6.3
                            docker rm -f db
                            docker rmi -f mongo:latest
                            # docker rmi -f mongo:6
                            rm -rf /home/docker/mongo
                            echo "应用已卸载"
                            ;;
                        0)
                            break  # 跳出循环，退出菜单
                            ;;
                        *)
                            break  # 跳出循环，退出菜单
                            ;;
                    esac
            else
                clear
                echo "安装提示"
                echo "rocket.chat国外知名开源多人聊天系统"
                echo "官网介绍: https://www.rocket.chat"
                echo ""

                # 提示用户确认安装
                read -p "确定安装rocket.chat吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear
                    install_docker
                    docker run --name db -d --restart=always \
                        -v /home/docker/mongo/dump:/dump \
                        mongo:latest --replSet rs5 --oplogSize 256
                    sleep 1
                    docker exec -it db mongosh --eval "printjson(rs.initiate())"
                    sleep 5
                    docker run --name rocketchat --restart=always -p 3897:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat:6.3

                    clear

                    ip_address
                    echo "rocket.chat已经安装完成"
                    echo "------------------------"
                    echo "多等一会，您可以使用以下地址访问rocket.chat:"
                    echo "http:$ipv4_address:3897"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi
              ;;



          11)
            docker_name="zentao-server"
            docker_img="idoop/zentao:latest"
            docker_port=82
            docker_rum="docker run -d -p 82:80 -p 3308:3306 \
                              -e ADMINER_USER="root" -e ADMINER_PASSWD="password" \
                              -e BIND_ADDRESS="false" \
                              -v /home/docker/zentao-server/:/opt/zbox/ \
                              --add-host smtp.exmail.qq.com:163.177.90.125 \
                              --name zentao-server \
                              --restart=always \
                              idoop/zentao:latest"
            docker_describe="禅道是通用的项目管理软件"
            docker_url="官网介绍: https://www.zentao.net/"
            docker_use="echo \"初始用户名: admin\""
            docker_passwd="echo \"初始密码: 123456\""
            docker_app

              ;;

          12)
            docker_name="qinglong"
            docker_img="whyour/qinglong:latest"
            docker_port=5700
            docker_rum="docker run -d \
                      -v /home/docker/qinglong/data:/ql/data \
                      -p 5700:5700 \
                      --name qinglong \
                      --hostname qinglong \
                      --restart unless-stopped \
                      whyour/qinglong:latest"
            docker_describe="青龙面板是一个定时任务管理平台"
            docker_url="官网介绍: https://github.com/whyour/qinglong"
            docker_use=""
            docker_passwd=""
            docker_app

              ;;
          13)
            if docker inspect cloudreve &>/dev/null; then

                    clear
                    echo "cloudreve已安装，访问地址: "
                    ip_address
                    echo "http:$ipv4_address:5212"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f cloudreve
                            docker rmi -f cloudreve/cloudreve:latest
                            docker rm -f aria2
                            docker rmi -f p3terx/aria2-pro
                            install_docker
                            cd /home/ && mkdir -p docker/cloud && cd docker/cloud && mkdir temp_data && mkdir -vp cloudreve/{uploads,avatar} && touch cloudreve/conf.ini && touch cloudreve/cloudreve.db && mkdir -p aria2/config && mkdir -p data/aria2 && chmod -R 777 data/aria2
                            curl -o /home/docker/cloud/docker-compose.yml https://raw.githubusercontent.com/kejilion/docker/main/cloudreve-docker-compose.yml
                            cd /home/docker/cloud/ && docker-compose up -d


                            clear
                            echo "cloudreve已经安装完成"
                            echo "------------------------"
                            echo "您可以使用以下地址访问cloudreve:"
                            ip_address
                            echo "http:$ipv4_address:5212"
                            sleep 3
                            docker logs cloudreve
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f cloudreve
                            docker rmi -f cloudreve/cloudreve:latest
                            docker rm -f aria2
                            docker rmi -f p3terx/aria2-pro
                            rm -rf /home/docker/cloud
                            echo "应用已卸载"
                            ;;
                        0)
                            break  # 跳出循环，退出菜单
                            ;;
                        *)
                            break  # 跳出循环，退出菜单
                            ;;
                    esac
            else
                clear
                echo "安装提示"
                echo "cloudreve是一个支持多家云存储的网盘系统"
                echo "官网介绍: https://cloudreve.org/"
                echo ""

                # 提示用户确认安装
                read -p "确定安装cloudreve吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear
                    install_docker
                    cd /home/ && mkdir -p docker/cloud && cd docker/cloud && mkdir temp_data && mkdir -vp cloudreve/{uploads,avatar} && touch cloudreve/conf.ini && touch cloudreve/cloudreve.db && mkdir -p aria2/config && mkdir -p data/aria2 && chmod -R 777 data/aria2
                    curl -o /home/docker/cloud/docker-compose.yml https://raw.githubusercontent.com/kejilion/docker/main/cloudreve-docker-compose.yml
                    cd /home/docker/cloud/ && docker-compose up -d


                    clear
                    echo "cloudreve已经安装完成"
                    echo "------------------------"
                    echo "您可以使用以下地址访问cloudreve:"
                    ip_address
                    echo "http:$ipv4_address:5212"
                    sleep 3
                    docker logs cloudreve
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi

              ;;

          14)
            docker_name="easyimage"
            docker_img="ddsderek/easyimage:latest"
            docker_port=85
            docker_rum="docker run -d \
                      --name easyimage \
                      -p 85:80 \
                      -e TZ=Asia/Shanghai \
                      -e PUID=1000 \
                      -e PGID=1000 \
                      -v /home/docker/easyimage/config:/app/web/config \
                      -v /home/docker/easyimage/i:/app/web/i \
                      --restart unless-stopped \
                      ddsderek/easyimage:latest"
            docker_describe="简单图床是一个简单的图床程序"
            docker_url="官网介绍: https://github.com/icret/EasyImages2.0"
            docker_use=""
            docker_passwd=""
            docker_app
              ;;

          15)
            docker_name="emby"
            docker_img="linuxserver/emby:latest"
            docker_port=8096
            docker_rum="docker run -d --name=emby --restart=always \
                        -v /homeo/docker/emby/config:/config \
                        -v /homeo/docker/emby/share1:/mnt/share1 \
                        -v /homeo/docker/emby/share2:/mnt/share2 \
                        -v /mnt/notify:/mnt/notify \
                        -p 8096:8096 -p 8920:8920 \
                        -e UID=1000 -e GID=100 -e GIDLIST=100 \
                        linuxserver/emby:latest"
            docker_describe="emby是一个主从式架构的媒体服务器软件，可以用来整理服务器上的视频和音频，并将音频和视频流式传输到客户端设备"
            docker_url="官网介绍: https://emby.media/"
            docker_use=""
            docker_passwd=""
            docker_app
              ;;

          16)
            docker_name="looking-glass"
            docker_img="wikihostinc/looking-glass-server"
            docker_port=89
            docker_rum="docker run -d --name looking-glass --restart always -p 89:80 wikihostinc/looking-glass-server"
            docker_describe="Speedtest测速面板是一个VPS网速测试工具，多项测试功能，还可以实时监控VPS进出站流量"
            docker_url="官网介绍: https://github.com/wikihost-opensource/als"
            docker_use=""
            docker_passwd=""
            docker_app

              ;;
          17)

            docker_name="adguardhome"
            docker_img="adguard/adguardhome"
            docker_port=3000
            docker_rum="docker run -d \
                            --name adguardhome \
                            -v /home/docker/adguardhome/work:/opt/adguardhome/work \
                            -v /home/docker/adguardhome/conf:/opt/adguardhome/conf \
                            -p 53:53/tcp \
                            -p 53:53/udp \
                            -p 3000:3000/tcp \
                            --restart always \
                            adguard/adguardhome"
            docker_describe="AdGuardHome是一款全网广告拦截与反跟踪软件，未来将不止是一个DNS服务器。"
            docker_url="官网介绍: https://hub.docker.com/r/adguard/adguardhome"
            docker_use=""
            docker_passwd=""
            docker_app

              ;;


          18)

            docker_name="onlyoffice"
            docker_img="onlyoffice/documentserver"
            docker_port=8082
            docker_rum="docker run -d -p 8082:80 \
                        --restart=always \
                        --name onlyoffice \
                        -v /home/docker/onlyoffice/DocumentServer/logs:/var/log/onlyoffice  \
                        -v /home/docker/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data  \
                         onlyoffice/documentserver"
            docker_describe="onlyoffice是一款开源的在线office工具，太强大了！"
            docker_url="官网介绍: https://www.onlyoffice.com/"
            docker_use=""
            docker_passwd=""
            docker_app

              ;;

          19)

            if docker inspect safeline-tengine &>/dev/null; then

                    clear
                    echo "雷池已安装，访问地址: "
                    ip_address
                    echo "http:$ipv4_address:9443"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                    case $sub_choice in
                        1)
                            clear
                            echo "暂不支持"
                            echo ""
                            ;;
                        2)

                            clear
                            echo "cd命令到安装目录下执行: docker compose down"
                            echo ""
                            ;;
                        0)
                            break  # 跳出循环，退出菜单
                            ;;
                        *)
                            break  # 跳出循环，退出菜单
                            ;;
                    esac
            else
                clear
                echo "安装提示"
                echo "雷池是长亭科技开发的WAF站点防火墙程序面板，可以反代站点进行自动化防御"
                echo "80和443端口不能被占用，无法与宝塔，1panel，npm，ldnmp建站共存"
                echo "官网介绍: https://github.com/chaitin/safeline"
                echo ""

                # 提示用户确认安装
                read -p "确定安装吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear
                    install_docker
                    bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"

                    clear
                    echo "雷池WAF面板已经安装完成"
                    echo "------------------------"
                    echo "您可以使用以下地址访问:"
                    ip_address
                    echo "http:$ipv4_address:9443"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi

              ;;

          20)
            docker_name="portainer"
            docker_img="portainer/portainer"
            docker_port=9050
            docker_rum="docker run -d \
                    --name portainer \
                    -p 9050:9000 \
                    -v /var/run/docker.sock:/var/run/docker.sock \
                    -v /home/docker/portainer:/data \
                    --restart always \
                    portainer/portainer"
            docker_describe="portainer是一个轻量级的docker容器管理面板"
            docker_url="官网介绍: https://www.portainer.io/"
            docker_use=""
            docker_passwd=""
            docker_app

              ;;

          21)
            docker_name="vscode-web"
            docker_img="codercom/code-server"
            docker_port=8180
            docker_rum="docker run -d -p 8180:8080 -v /home/docker/vscode-web:/home/coder/.local/share/code-server --name vscode-web --restart always codercom/code-server"
            docker_describe="VScode是一款强大的在线代码编写工具"
            docker_url="官网介绍: https://github.com/coder/code-server"
            docker_use="sleep 3"
            docker_passwd="docker exec vscode-web cat /home/coder/.config/code-server/config.yaml"
            docker_app
              ;;
          22)
            docker_name="uptime-kuma"
            docker_img="louislam/uptime-kuma:latest"
            docker_port=3003
            docker_rum="docker run -d \
                            --name=uptime-kuma \
                            -p 3003:3001 \
                            -v /home/docker/uptime-kuma/uptime-kuma-data:/app/data \
                            --restart=always \
                            louislam/uptime-kuma:latest"
            docker_describe="Uptime Kuma 易于使用的自托管监控工具"
            docker_url="官网介绍: https://github.com/louislam/uptime-kuma"
            docker_use=""
            docker_passwd=""
            docker_app
              ;;

          23)
            docker_name="memos"
            docker_img="ghcr.io/usememos/memos:latest"
            docker_port=5230
            docker_rum="docker run -d --name memos -p 5230:5230 -v /home/docker/memos:/var/opt/memos --restart always ghcr.io/usememos/memos:latest"
            docker_describe="Memos是一款轻量级、自托管的备忘录中心"
            docker_url="官网介绍: https://github.com/usememos/memos"
            docker_use=""
            docker_passwd=""
            docker_app
              ;;

          24)
            clear 
            echo -e "${yellow}s-ui: sing-box 官方 Web 管理面板${re}"
            echo "官网: https://github.com/alireza0/s-ui"
            echo "默认端口: 2096   默认路径: /sui"
            echo "------------------------"
            read -p "确定安装 s-ui 官方版吗？(Y/N): " choice
            case "$choice" in
              [Yy])
                bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh)
                read -p "按回车键继续..." x
                ;;
              *) ;;
            esac
            ;;
          25)
            clear 
            echo -e "${yellow}3x-ui: Xray 官方 Web 管理面板（支持多协议）${re}"
            echo "官网: https://github.com/MHSanaei/3x-ui"
            echo "默认端口: 54321   默认账号: admin   默认密码: admin"
            echo "------------------------"
            read -p "确定安装 3x-ui 官方版吗？(Y/N): " choice
            case "$choice" in
              [Yy])
                bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)
                read -p "按回车键继续..." x
                ;;
              *) ;;
            esac
            ;;
          0)
              main_menu
              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      break_end

    done
    ;;

  10)
    while true; do
      clear
      echo "▶ 系统工具"
      echo "------------------------"
      echo " 1. 设置脚本启动快捷键"
      echo "------------------------"
      echo " 2. 修改ROOT密码                   9. 禁用ROOT账户创建新账户"
      echo " 3. 开启ROOT密码登录              10. 切换优先ipv4/ipv6"
      echo " 4. 禁用修改ROOT密码              11. 查看端口占用状态"
      echo " 5. 开放所有端口                  12. 修改虚拟内存大小"
      echo " 6. 修改SSH连接端口               13. 用户/密码生成器"
      echo " 7. 优化DNS地址                   14. 用户管理"
      echo -e "${skyblue} 8. 一键重装系统                  15. NAT小鸡一键重装系统${re} "
      echo -e "${yellow}--------------------------------------------------------${re}"
      echo "16. 开启BBR3加速                  23. 系统时区调整"
      echo "17. 防火墙高级管理器              24. iptables一键转发"
      echo "18. 修改主机名                    25. NAT批量SSH连接测试"
      echo "19. 切换系统更新源"
      echo "20. 定时任务管理"
      echo "21. ip开放端口扫描"
      echo "22. 服务器资源限制"
      echo -e "${skyblue}------------------------${re}"
      echo -e "${skyblue} 🚀 增强功能${re}"
      echo "26. Docker应用市场                  30. 系统备份与还原"
      echo "27. 内核参数一键调优                31. TG-bot监控预警"
      echo "28. SSH防御(fail2ban)              "
      echo "29. 病毒扫描(ClamAV)               "
      echo "------------------------"
      echo "80. 留言板"
      echo "------------------------"
      echo "99. 重启服务器"
      echo "------------------------"
      echo -e "${skyblue} 0. 返回主菜单${re}"
      echo "------------------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

      case $sub_choice in
          1)
              clear
              read -p $'\033[1;91m请输入你需要设置的快捷按键: \033[0m' kuaijiejian              
                [ -z "$kuaijiejian" ] && echo -e "${red}你似乎什么也没输入${re}" && main_menu || kuaijiejian_value="$kuaijiejian"
    
                # 检查输入是否为单个字母
                if [[ ! "$kuaijiejian_value" =~ ^[a-zA-Z]$ ]]; then
                    echo -e "${red}请输入单个大写或小写字母${re}"
                else
                    # 将输入转换为大写和小写
                    uppercase_value=$(echo "$kuaijiejian_value" | tr '[:lower:]' '[:upper:]')
                    lowercase_value=$(echo "$kuaijiejian_value" | tr '[:upper:]' '[:lower:]')
                    
                    # 软连接目标脚本
                    script_path="/usr/local/bin/fox_toolbox.sh"
                    
                    # 确保目标脚本存在且有执行权限
                    if [ ! -f "$script_path" ]; then
                        echo -e "${red}目标脚本不存在，请先安装脚本${re}"
                    else
                        # 删除可能存在的同名软连接
                        rm -f "/usr/local/bin/$uppercase_value" 2>/dev/null
                        rm -f "/usr/local/bin/$lowercase_value" 2>/dev/null
                        
                        # 创建大写和小写的软连接
                        ln -sf "$script_path" "/usr/local/bin/$uppercase_value"
                        ln -sf "$script_path" "/usr/local/bin/$lowercase_value"
                        hash -r >/dev/null 2>&1
                        echo -e "${green}快捷键已设置为：$uppercase_value 和 $lowercase_value${re}"
                    fi
                fi
              ;;

          2)
              clear
               read -p $'\033[1;35m请输入新的ROOT密码: \033[0m' passwd
               echo "root:$passwd" | chpasswd && echo -e "\033[1;32mRoot密码修改成功. 正在重启服务器...\033[0m" && sleep 1 && reboot || echo -e "\033[1;91mRoot密码修改失败\033[0m"
              ;;
          3)
              clear
              read -p $'\033[1;35m请设置你的root密码: \033[0m' passwd
              echo "root:$passwd" | chpasswd && echo "Root密码设置成功" || echo "Root密码修改失败"
              sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
              sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
              sed -i 's|^Include /etc/ssh/sshd_config.d/\*.conf|#&|' /etc/ssh/sshd_config;
              service sshd restart
              echo -e "${green}ROOT登录设置完毕，重启服务器生效${re}"
              read -p $'\033[1;35m需要立即重启服务器吗？(y/n): \033[0m' choice
          case "$choice" in
            [Yy])
              reboot
              ;;
            [Nn])
              echo "已取消"
              ;;
            *)
              echo "无效的选择，请输入 Y 或 N。"
              ;;
          esac
              ;;

          4)
            clear
                chattr +i /etc/passwd
                chattr +i /etc/shadow
                echo -e "${yellow}已禁用修改ROOT密码${re}"
              ;;

          5)
              clear
              iptables_open
              remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
              echo -e "${green}端口已全部开放${re}"

              ;;
          6)
              clear
              #!/bin/bash

              # 去掉 #Port 的注释
              sed -i 's/#Port/Port/' /etc/ssh/sshd_config

              # 读取当前的 SSH 端口号
              current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

              # 打印当前的 SSH 端口号
              echo "当前的 SSH 端口号是: $current_port"

              echo "------------------------"

              # 提示用户输入新的 SSH 端口号
              read -p $'\033[1;35m请输入新的 SSH 端口号: \033[0m' new_port

              # 备份 SSH 配置文件
              cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

              # 替换 SSH 配置文件中的端口号
              sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

              # 重启 SSH 服务
              service sshd restart

              echo "SSH 端口已修改为: $new_port"

              clear
              iptables_open
              remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

              ;;


          7)
            clear
            echo "当前DNS地址"
            echo "------------------------"
            cat /etc/resolv.conf
            echo "------------------------"
            echo ""
            # 询问用户是否要优化DNS设置
            read -p $'\033[1;35m是否要设置为Cloudflare和Google的DNS地址？(y/n): \033[0m' choice

            if [ "$choice" == "y" ]; then
                # 定义DNS地址
                cloudflare_ipv4="1.1.1.1"
                google_ipv4="8.8.8.8"
                cloudflare_ipv6="2606:4700:4700::1111"
                google_ipv6="2001:4860:4860::8888"

                # 检查机器是否有IPv6地址
                ipv6_available=0
                if [[ $(ip -6 addr | grep -c "inet6") -gt 0 ]]; then
                    ipv6_available=1
                fi

                # 设置DNS地址为Cloudflare和Google（IPv4和IPv6）
                echo "设置DNS为Cloudflare和Google"

                # 设置IPv4地址
                echo "nameserver $cloudflare_ipv4" > /etc/resolv.conf
                echo "nameserver $google_ipv4" >> /etc/resolv.conf

                # 如果有IPv6地址，则设置IPv6地址
                if [[ $ipv6_available -eq 1 ]]; then
                    echo "nameserver $cloudflare_ipv6" >> /etc/resolv.conf
                    echo "nameserver $google_ipv6" >> /etc/resolv.conf
                fi

                echo "DNS地址已更新"
                echo "------------------------"
                cat /etc/resolv.conf
                echo "------------------------"
            else
                echo "DNS设置未更改"
            fi

              ;;

          8)
            clear

            restart_system() {
                read -p $'\033[1;35m是否立即重启系统继续完成安装？(y/n): \033[0m' restart_choice
                echo -e "${green}重启系统几分钟后即可连接SSH${re}"
                if [[ $restart_choice =~ ^[Yy]$ ]]; then
                    reboot
                else 
                    echo -e "${green}请手动重启系统继续完成安装${re}"
                    sleep 2
                    main_menu
                fi
            }

            echo -e "${purple}重装系统将无法恢复数据，请提前做好备份${re}"
            echo ""
            read -p $'\033[1;35m确定要重装吗？(y/n): \033[0m' confirm

            if [[ $confirm =~ ^[Yy]$ ]]; then
                    sleep 1
                    echo -e "${yellow}初始化安装环境...${re}"
                    install wget
                    wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh
                    sleep 1
                while true; do
                    echo ""
                    echo -e "${purple}请保存你的root密码，安装后使用该密码登录，登录成功后自行修改${re}"
                    echo -e "${yellow}Linux默认用户名：${purple}root${yellow} 默认密码：${purple}LeitboGi0ro${yellow} 默认ssh端口22${re}"
                    echo -e "${yellow}Windows默认用户名：${purple}Administrator${yellow} 默认密码：${purple}Teddysun.com${yellow} 默认远程连接端口${purple}3389${re}"
                    echo -e "${yellow}详细参数参考Github项目地址：https://github.com/leitbogioro/Tools${re}"
                    echo ""
                    echo -e "${green} 1.安装Debian-12            2.安装Debian-13${re}"
                    echo -e "${green} 3.安装Ubuntu-22.04         4.安装Ubuntu-24.04${re}"
                    echo -e "${green} 5.安装Alpine-3.19          6.安装Alpine-3.20${re}"
                    echo -e "${green} 7.安装Centos-8             8.安装Centos-9${re}"
                    echo -e "${green} 9.安装Fedora-39           10.安装RockyLinux-9${re}"
                    echo -e "${green}11.安装AlmaLinux-9         12.安装Kali-Rolling${re}"
                    echo -e "${green}13.安装Windows-10          14.安装Windows-11${re}"
                    echo "-----------------------------------------------"
                    echo -e "${red}0.取消安装${re}"
                    echo "---------------------"
                    read -p $'\033[1;35m请输入你的选择: \033[0m' sub_choice
                   
                    case $sub_choice in
                        1) 
                            echo -e "${green}开始为你安装Debian-12${re}"
                            sleep 1
                            bash InstallNET.sh -debian 12
                            sleep 2
                            clear
                            restart_system
                            ;;
                        2) 
                            echo -e "${green}开始为你安装Debian-13${re}"
                            sleep 1
                            bash InstallNET.sh -debian 13
                            sleep 2
                            clear
                            restart_system
                            ;;
                        3) 
                            echo -e "${green}开始为你安装Ubuntu-22.04${re}"
                            sleep 1
                            bash InstallNET.sh -ubuntu 22.04
                            sleep 2
                            clear
                            restart_system
                            ;;
                        4) 
                            echo -e "${green}开始为你安装Ubuntu-24.04${re}"
                            sleep 1
                            bash InstallNET.sh -ubuntu 24.04
                            sleep 2
                            clear
                            restart_system
                            ;;
                        5) 
                            echo -e "${green}开始为你安装Alpine-3.19${re}"
                            sleep 1
                            bash InstallNET.sh -alpine 3.19
                            sleep 2
                            clear
                            restart_system
                            ;;
                        6) 
                            echo -e "${green}开始为你安装Alpine-3.20${re}"
                            sleep 1
                            bash InstallNET.sh -alpine
                            sleep 2
                            clear
                            restart_system
                            ;;
                        7) 
                            echo -e "${green}开始为你安装Centos-8${re}"
                            sleep 1
                            bash InstallNET.sh -centos 8
                            sleep 2
                            clear
                            restart_system
                            ;;
                        8) 
                            echo -e "${green}开始为你安装Centos-9${re}"
                            sleep 1
                            bash InstallNET.sh -centos 9
                            sleep 2
                            clear
                            restart_system
                            ;;
                        9) 
                            echo -e "${green}开始为你安装Fedora-39${re}"
                            sleep 1
                            bash InstallNET.sh -fedora
                            sleep 2
                            clear
                            restart_system
                            ;;
                        10) 
                            echo -e "${green}开始为你安装RockyLinux-9${re}"
                            sleep 1
                            bash InstallNET.sh -rockylinux
                            sleep 2
                            clear
                            restart_system
                            ;;
                        11) 
                            echo -e "${green}开始为你安装AlmaLinux-9${re}"
                            sleep 1
                            bash InstallNET.sh -almaLinux
                            sleep 2
                            clear
                            restart_system
                            ;;
                        12) 
                            echo -e "${green}开始为你安装Kali-Rolling${re}"
                            sleep 1
                            bash InstallNET.sh -kali
                            sleep 2
                            clear
                            restart_system
                            ;;
                        13) 
                            echo -e "${green}开始为你安装Windows-10${re}"
                            sleep 1
                            bash InstallNET.sh -windows 10 -lang "cn"
                            sleep 2
                            clear
                            restart_system
                            ;;
                        14) 
                            echo -e "${green}开始为你安装Windows-11${re}"
                            sleep 1
                            bash InstallNET.sh -windows 11 -lang "cn"
                            sleep 2
                            clear
                            restart_system
                            ;;
                        0) 
                            echo -e "${red}正在退出安装...${re}"
                            rm InstallNET.sh
                            sleep 1
                            main_menu
                            ;;
                        *)
                            echo -e "${red}输入错误，请重新输入${re}"
                            ;;
                    esac
                done
            else 
                main_menu
            fi
            ;;

          9)
            clear
            install sudo

            # 提示用户输入新用户名
            read -p "请输入新用户名: " new_username

            # 创建新用户并设置密码
            sudo useradd -m -s /bin/bash "$new_username"
            sudo passwd "$new_username"

            # 赋予新用户sudo权限
            echo "$new_username ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

            # 禁用ROOT用户登录
            sudo passwd -l root

            echo "操作已完成。"
            ;;


          10)
            clear
            GAI_CONF="/etc/gai.conf"

            echo ""
            if grep -qE '^\s*precedence\s+::ffff:0:0/96\s+100' "$GAI_CONF" 2>/dev/null; then
                echo "当前网络优先级设置: IPv4 优先"
            else
                echo "当前网络优先级设置: IPv6 优先"
            fi
            echo "------------------------"

            echo ""
            echo "切换的网络优先级"
            echo "------------------------"
            echo "1. IPv4 优先          2. IPv6 优先      3. 禁用 IPv6"
            echo "------------------------"
            read -p "选择优先的网络: " choice

            case $choice in
                1)
                    [ ! -f "${GAI_CONF}.bak" ] && cp "$GAI_CONF" "${GAI_CONF}.bak" 2>/dev/null
                    [ ! -f "$GAI_CONF" ] && touch "$GAI_CONF"
                    sed -i '/^\s*precedence\s\+::ffff:0:0\/96/d' "$GAI_CONF"
                    echo "precedence ::ffff:0:0/96  100" >> "$GAI_CONF"
                    
                    # 检查IPv6是否禁用
                    v6_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null)
                    if [ "$v6_disabled" -eq 1 ]; then
                        echo -e "\n${yellow}IPv6 已禁用，是否需要开启？[Y/N]${re}"
                        read -p "是否需要开启？[Y/N]" choice
                        if [[ "$choice" =~ [Yy] ]]; then
                            sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null 2>&1
                            sysctl -w net.ipv6.conf.default.disable_ipv6=0 >/dev/null 2>&1
                            sysctl -w net.ipv6.conf.lo.disable_ipv6=0 >/dev/null 2>&1

                            # 写入持久化
                            sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
                            sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
                            sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf

                            {
                                echo "net.ipv6.conf.all.disable_ipv6 = 0"
                                echo "net.ipv6.conf.default.disable_ipv6 = 0"
                                echo "net.ipv6.conf.lo.disable_ipv6 = 0"
                            } >> /etc/sysctl.conf

                            sysctl -p >/dev/null 2>&1
                        fi
                    fi
                    echo -e "\n${green}已切换为 IPv4 优先(IPv6 仍然可用，只是优先级降低)${re}\n"
                    ;;
                2)
                    [ ! -f "${GAI_CONF}.bak" ] && cp "$GAI_CONF" "${GAI_CONF}.bak" 2>/dev/null
                    [ ! -f "$GAI_CONF" ] && touch "$GAI_CONF"
                    # 移除 IPv4 优先规则即可恢复默认 IPv6 优先
                    sed -i '/^\s*precedence\s\+::ffff:0:0\/96/d' "$GAI_CONF"
                    sysctl -w net.ipv6.conf.all.disable_ipv6=0 > /dev/null 2>&1
                    echo -e "\n${green}已切换为 IPv6 优先(IPv4 仍然可用，只是优先级降低)${re}\n"
                    ;;
                3)
                    sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
                    sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
                    sysctl -w net.ipv6.conf.lo.disable_ipv6=1 >/dev/null 2>&1

                    sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
                    sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
                    sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf

                    {
                        echo "net.ipv6.conf.all.disable_ipv6 = 1"
                        echo "net.ipv6.conf.default.disable_ipv6 = 1"
                        echo "net.ipv6.conf.lo.disable_ipv6 = 1"
                    } >> /etc/sysctl.conf

                    sysctl -p >/dev/null 2>&1
                    # 同时移除 IPv4 优先规则（禁用 IPv6 后此规则无意义）
                    sed -i '/^\s*precedence\s\+::ffff:0:0\/96/d' "$GAI_CONF" 2>/dev/null
                    echo -e "\n${yellow}✓ IPv6 已在系统层禁用${re}\n"
                    ;;
                *)
                    echo "无效的选择"
                    ;;

            esac
            ;;

          11)
            clear
            ss -tulnape
            ;;

          12)

            if [ "$EUID" -ne 0 ]; then
              echo "请以 root 权限运行此脚本。"
              exit 1
            fi

            clear
            # 获取当前交换空间信息
            swap_used=$(free -m | awk 'NR==3{print $3}')
            swap_total=$(free -m | awk 'NR==3{print $2}')

            if [ "$swap_total" -eq 0 ]; then
              swap_percentage=0
            else
              swap_percentage=$((swap_used * 100 / swap_total))
            fi

            swap_info="${swap_used}MB/${swap_total}MB (${swap_percentage}%)"

            echo "当前虚拟内存: $swap_info"

            read -p "是否调整大小?(Y/N): " choice

            case "$choice" in
              [Yy])
                # 输入新的虚拟内存大小
                read -p "请输入虚拟内存大小MB: " new_swap

                # 获取当前系统中所有的 swap 分区
                swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

                # 遍历并删除所有的 swap 分区
                for partition in $swap_partitions; do
                  swapoff "$partition"
                  wipefs -a "$partition"  # 清除文件系统标识符
                  mkswap -f "$partition"
                  echo "已删除并重新创建 swap 分区: $partition"
                done

                # 确保 /swapfile 不再被使用
                swapoff /swapfile

                # 删除旧的 /swapfile
                rm -f /swapfile

                # 创建新的 swap 分区
                dd if=/dev/zero of=/swapfile bs=1M count=$new_swap
                chmod 600 /swapfile
                mkswap /swapfile
                swapon /swapfile
                echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

                echo "虚拟内存大小已调整为${new_swap}MB"
                ;;
              [Nn])
                echo "已取消"
                ;;
              *)
                echo "无效的选择，请输入 Y 或 N。"
                ;;
            esac
            ;;

          13)
            clear

            echo "随机用户名"
            echo "------------------------"
            for i in {1..5}; do
                username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
                echo "随机用户名 $i: $username"
            done

            echo ""
            echo "随机姓名"
            echo "------------------------"
            first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
            last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

            # 生成5个随机用户姓名
            for i in {1..5}; do
                first_name_index=$((RANDOM % ${#first_names[@]}))
                last_name_index=$((RANDOM % ${#last_names[@]}))
                user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
                echo "随机用户姓名 $i: $user_name"
            done

            echo ""
            echo "随机UUID"
            echo "------------------------"
            for i in {1..5}; do
                uuid=$(cat /proc/sys/kernel/random/uuid)
                echo "随机UUID $i: $uuid"
            done

            echo ""
            echo "16位随机密码"
            echo "------------------------"
            for i in {1..5}; do
                password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
                echo "随机密码 $i: $password"
            done

            echo ""
            echo "32位随机密码"
            echo "------------------------"
            for i in {1..5}; do
                password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
                echo "随机密码 $i: $password"
            done
            echo ""
            ;;

          14)
            clear
              while true; do
                clear
                install sudo
                clear
                # 显示所有用户、用户权限、用户组和是否在sudoers中
                echo "用户列表"
                echo "----------------------------------------------------------------------------"
                printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"
                while IFS=: read -r username _ userid groupid _ _ homedir shell; do
                    groups=$(groups "$username" | cut -d : -f 2)
                    sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
                    printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
                done < /etc/passwd


                  echo ""
                  echo "账户操作"
                  echo "------------------------"
                  echo "1. 创建普通账户             2. 创建高级账户"
                  echo "------------------------"
                  echo "3. 赋予最高权限             4. 取消最高权限"
                  echo "------------------------"
                  echo "5. 删除账号"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                       # 提示用户输入新用户名
                       read -p "请输入新用户名: " new_username

                       # 创建新用户并设置密码
                       sudo useradd -m -s /bin/bash "$new_username"
                       sudo passwd "$new_username"

                       echo "操作已完成。"
                          ;;

                      2)
                       # 提示用户输入新用户名
                       read -p "请输入新用户名: " new_username

                       # 创建新用户并设置密码
                       sudo useradd -m -s /bin/bash "$new_username"
                       sudo passwd "$new_username"

                       # 赋予新用户sudo权限
                       echo "$new_username ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

                       echo "操作已完成。"

                          ;;
                      3)
                       read -p "请输入用户名: " username
                       # 赋予新用户sudo权限
                       echo "$username ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers
                          ;;
                      4)
                       read -p "请输入用户名: " username
                       # 从sudoers文件中移除用户的sudo权限
                       sudo sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

                          ;;
                      5)
                       read -p "请输入要删除的用户名: " username
                       # 删除用户及其主目录
                       sudo userdel -r "$username"
                          ;;

                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;
                  esac
              done
              ;;

          15)
            clear
            echo -e "${green}重装系统将无法恢复数据，请提前做好备份${re}"
            echo ""
            read -p $'\033[1;35m确定要重装吗？(y/n): \033[0m' confirm

                if [[ $confirm =~ ^[Yy]$ ]]; then
                    sleep 1
                    curl -so OsMutation.sh https://raw.githubusercontent.com/LloydAsp/OsMutation/main/OsMutation.sh && chmod u+x OsMutation.sh && ./OsMutation.sh
                    break_end
                else 
                    main_menu
                fi
            ;;

          16)
          if dpkg -l | grep -q 'linux-xanmod'; then
            while true; do
                  clear
                  kernel_version=$(uname -r)
                  echo "您已安装xanmod的BBRv3内核"
                  echo "当前内核版本: $kernel_version"

                  echo ""
                  echo "内核管理"
                  echo "------------------------"
                  echo "1. 更新BBRv3内核              2. 卸载BBRv3内核"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                        apt update -y
                        apt upgrade -y
                        echo "XanMod内核已更新。重启后生效"
                        reboot

                          ;;
                      2)
                        apt purge -y 'linux-*xanmod1*'
                        update-grub
                        echo "XanMod内核已卸载。重启后生效"
                        reboot
                          ;;
                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;

                  esac
            done
        else

          clear
          echo "请备份数据，将为你升级Linux内核开启BBR3"
          echo "官网介绍: https://xanmod.org/"
          echo "------------------------------------------------"
          echo "仅支持Debian/Ubuntu 仅支持x86_64架构"
          echo "VPS是512M内存的，请提前添加1G虚拟内存，防止因内存不足失联！"
          echo "------------------------------------------------"
          read -p "确定继续吗？(Y/N): " choice

          case "$choice" in
            [Yy])
            if [ -r /etc/os-release ]; then
                . /etc/os-release
                if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
                    echo "当前环境不支持，仅支持Debian和Ubuntu系统"
                    break
                fi
            else
                echo "无法确定操作系统类型"
                break
            fi

            # 检查系统架构
            arch=$(dpkg --print-architecture)
            if [ "$arch" != "amd64" ]; then
              echo "当前环境不支持，仅支持x86_64架构"
              break
            fi

            install wget gnupg

            # wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
            wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

            # 步骤3：添加存储库
            echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

            # version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
            version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

            apt update -y
            apt install -y linux-xanmod-x64v$version

            # 步骤5：启用BBR3
            cat > /etc/sysctl.conf << EOF
net.core.default_qdisc=fq_pie
net.ipv4.tcp_congestion_control=bbr
EOF
            sysctl -p
            echo "XanMod内核安装并BBR3启用成功。重启后生效"
            rm -f /etc/apt/sources.list.d/xanmod-release.list
            rm -f check_x86-64_psabi.sh*
            reboot

              ;;
            [Nn])
              echo "已取消"
              ;;
            *)
              echo "无效的选择，请输入 Y 或 N。"
              ;;
          esac
        fi
              ;;

          17)
          if dpkg -l | grep -q iptables-persistent; then
            while true; do
                  clear
                  echo "防火墙已安装"
                  echo "------------------------"
                  iptables -L INPUT

                  echo ""
                  echo "防火墙管理"
                  echo "------------------------"
                  echo "1. 开放指定端口              2. 关闭指定端口"
                  echo "3. 开放所有端口              4. 关闭所有端口"
                  echo "------------------------"
                  echo "5. IP白名单                  6. IP黑名单"
                  echo "7. 清除指定IP"
                  echo "------------------------"
                  echo "9. 关闭并卸载防火墙"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                      read -p "请输入开放的端口号: " o_port
                      sed -i "/COMMIT/i -A INPUT -p tcp --dport $o_port -j ACCEPT" /etc/iptables/rules.v4
                      sed -i "/COMMIT/i -A INPUT -p udp --dport $o_port -j ACCEPT" /etc/iptables/rules.v4
                      iptables-restore < /etc/iptables/rules.v4

                          ;;
                      2)
                      read -p "请输入关闭的端口号: " c_port
                      sed -i "/--dport $c_port/d" /etc/iptables/rules.v4
                      iptables-restore < /etc/iptables/rules.v4
                        ;;

                      3)
                      current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

                      cat > /etc/iptables/rules.v4 << EOF
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A FORWARD -i lo -j ACCEPT
-A INPUT -p tcp --dport $current_port -j ACCEPT
COMMIT
EOF
                      iptables-restore < /etc/iptables/rules.v4

                          ;;
                      4)
                      current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

                      cat > /etc/iptables/rules.v4 << EOF
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A FORWARD -i lo -j ACCEPT
-A INPUT -p tcp --dport $current_port -j ACCEPT
COMMIT
EOF
                      iptables-restore < /etc/iptables/rules.v4

                          ;;

                      5)
                      read -p "请输入放行的IP: " o_ip
                      sed -i "/COMMIT/i -A INPUT -s $o_ip -j ACCEPT" /etc/iptables/rules.v4
                      iptables-restore < /etc/iptables/rules.v4

                          ;;

                      6)
                      read -p "请输入封锁的IP: " c_ip
                      sed -i "/COMMIT/i -A INPUT -s $c_ip -j DROP" /etc/iptables/rules.v4
                      iptables-restore < /etc/iptables/rules.v4
                          ;;

                      7)
                     read -p "请输入清除的IP: " d_ip
                     sed -i "/-A INPUT -s $d_ip/d" /etc/iptables/rules.v4
                     iptables-restore < /etc/iptables/rules.v4
                          ;;

                      9)
                      sudo systemctl stop ufw.service && sudo systemctl disable ufw.service && (sudo ufw status | grep -q 'Status: inactive' && echo "UFW closed successfully" || echo "Failed to close UFW")
                      remove iptables-persistent
                      rm /etc/iptables/rules.v4
                      break
                      # echo "防火墙已卸载，重启生效"
                      # reboot
                          ;;

                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;

                  esac
            done
        else

          clear
          echo "将为你安装防火墙，该防火墙仅支持Debian/Ubuntu"
          echo "------------------------------------------------"
          read -p "确定继续吗？(Y/N): " choice

          case "$choice" in
            [Yy])
            if [ -r /etc/os-release ]; then
                . /etc/os-release
                if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
                    echo "当前环境不支持，仅支持Debian和Ubuntu系统"
                    break
                fi
            else
                echo "无法确定操作系统类型"
                break
            fi

          clear
          iptables_open
          remove iptables-persistent ufw
          rm /etc/iptables/rules.v4

          apt update -y && apt install -y iptables-persistent

          current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

          cat > /etc/iptables/rules.v4 << EOF
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A FORWARD -i lo -j ACCEPT
-A INPUT -p tcp --dport $current_port -j ACCEPT
COMMIT
EOF

          iptables-restore < /etc/iptables/rules.v4
          systemctl enable netfilter-persistent
          echo "防火墙安装完成"


              ;;
            [Nn])
              echo "已取消"
              ;;
            *)
              echo "无效的选择，请输入 Y 或 N。"
              ;;
          esac
        fi
              ;;

          18)
            clear
            # 获取系统信息
            source /etc/os-release
            echo -e "${yellow}当前系统: ${red}${PRETTY_NAME}${re}"
            current_hostname=$(hostname)
            read -p $'\033[1;35m确定要更改主机名？ (y/n): \033[0m' choice

            if [[ "$choice" =~ ^[Yy]$ ]]; then

                read -p $'\033[1;35m请输入新的主机名: \033[0m' new_hostname

                case $ID in
                    "alpine")
                        echo "$new_hostname" > /etc/hostname
                        echo "127.0.0.1 localhost $new_hostname" > /etc/hosts
                        ;;
                    "debian" | "ubuntu")
                        hostnamectl set-hostname "$new_hostname"
                        sed -i "s/$current_hostname/$new_hostname/g" /etc/hostname
                        ;;
                    "centos" | "fedora" | "rocky" | "amzn" | "almalinux")
                        hostnamectl set-hostname "$new_hostname"
                        ;;
                    *)
                        echo -e "${red}不支持的系统类型: ${ID}${re}"
                        sleep 3
                        main_menu
                        ;;
                esac

                echo -e $'\033[1;35m主机名已更改，重新连接ssh生效\033[0m'
                    sleep 2
                    main_menu
            else
                echo -e "${green}取消更改主机名。${re}"
                sleep 2
                main_menu
            fi

            ;;
            
          19)

          # 获取系统信息
          source /etc/os-release

          # 定义 Ubuntu 更新源
          aliyun_ubuntu_source="http://mirrors.aliyun.com/ubuntu/"
          official_ubuntu_source="http://archive.ubuntu.com/ubuntu/"
          initial_ubuntu_source=""

          # 定义 Debian 更新源
          aliyun_debian_source="http://mirrors.aliyun.com/debian/"
          official_debian_source="http://deb.debian.org/debian/"
          initial_debian_source=""

          # 定义 CentOS 更新源
          aliyun_centos_source="http://mirrors.aliyun.com/centos/"
          official_centos_source="http://mirror.centos.org/centos/"
          initial_centos_source=""

          # 获取当前更新源并设置初始源
          case "$ID" in
              ubuntu)
                  initial_ubuntu_source=$(grep -E '^deb ' /etc/apt/sources.list | head -n 1 | awk '{print $2}')
                  ;;
              debian)
                  initial_debian_source=$(grep -E '^deb ' /etc/apt/sources.list | head -n 1 | awk '{print $2}')
                  ;;
              centos)
                  initial_centos_source=$(awk -F= '/^baseurl=/ {print $2}' /etc/yum.repos.d/CentOS-Base.repo | head -n 1 | tr -d ' ')
                  ;;
              *)
                  echo "未知系统，无法执行切换源脚本"
                  exit 1
                  ;;
          esac

          # 备份当前源
          backup_sources() {
              case "$ID" in
                  ubuntu)
                      cp /etc/apt/sources.list /etc/apt/sources.list.bak
                      ;;
                  debian)
                      cp /etc/apt/sources.list /etc/apt/sources.list.bak
                      ;;
                  centos)
                      if [ ! -f /etc/yum.repos.d/CentOS-Base.repo.bak ]; then
                          cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
                      else
                          echo "备份已存在，无需重复备份"
                      fi
                      ;;
                  *)
                      echo "未知系统，无法执行备份操作"
                      exit 1
                      ;;
              esac
              echo "已备份当前更新源为 /etc/apt/sources.list.bak 或 /etc/yum.repos.d/CentOS-Base.repo.bak"
          }

          # 还原初始更新源
          restore_initial_source() {
              case "$ID" in
                  ubuntu)
                      cp /etc/apt/sources.list.bak /etc/apt/sources.list
                      ;;
                  debian)
                      cp /etc/apt/sources.list.bak /etc/apt/sources.list
                      ;;
                  centos)
                      cp /etc/yum.repos.d/CentOS-Base.repo.bak /etc/yum.repos.d/CentOS-Base.repo
                      ;;
                  *)
                      echo "未知系统，无法执行还原操作"
                      exit 1
                      ;;
              esac
              echo "已还原初始更新源"
          }

          # 函数：切换更新源
          switch_source() {
              case "$ID" in
                  ubuntu)
                      sed -i 's|'"$initial_ubuntu_source"'|'"$1"'|g' /etc/apt/sources.list
                      ;;
                  debian)
                      sed -i 's|'"$initial_debian_source"'|'"$1"'|g' /etc/apt/sources.list
                      ;;
                  centos)
                      sed -i "s|^baseurl=.*$|baseurl=$1|g" /etc/yum.repos.d/CentOS-Base.repo
                      ;;
                  *)
                      echo "未知系统，无法执行切换操作"
                      exit 1
                      ;;
              esac
          }

          # 主菜单
          while true; do
              clear
              case "$ID" in
                  ubuntu)
                      echo "Ubuntu 更新源切换脚本"
                      echo "------------------------"
                      ;;
                  debian)
                      echo "Debian 更新源切换脚本"
                      echo "------------------------"
                      ;;
                  centos)
                      echo "CentOS 更新源切换脚本"
                      echo "------------------------"
                      ;;
                  *)
                      echo "未知系统，无法执行脚本"
                      exit 1
                      ;;
              esac

              echo "1. 切换到阿里云源"
              echo "2. 切换到官方源"
              echo "------------------------"
              echo "3. 备份当前更新源"
              echo "4. 还原初始更新源"
              echo -e "${green}5. 国内软件源列表(推荐)${re}"
              echo -e "${green}6. 国外软件源列表(推荐)${re}"
              echo "------------------------"
              echo "0. 返回上一级"
              echo "------------------------"
              read -p "请选择操作: " choice

              case $choice in
                  1)
                      backup_sources
                      case "$ID" in
                          ubuntu)
                              switch_source $aliyun_ubuntu_source
                              ;;
                          debian)
                              switch_source $aliyun_debian_source
                              ;;
                          centos)
                              switch_source $aliyun_centos_source
                              ;;
                          *)
                              echo "未知系统，无法执行切换操作"
                              exit 1
                              ;;
                      esac
                      echo "已切换到阿里云源"
                      ;;
                  2)
                      backup_sources
                      case "$ID" in
                          ubuntu)
                              switch_source $official_ubuntu_source
                              ;;
                          debian)
                              switch_source $official_debian_source
                              ;;
                          centos)
                              switch_source $official_centos_source
                              ;;
                          *)
                              echo "未知系统，无法执行切换操作"
                              exit 1
                              ;;
                      esac
                      echo "已切换到官方源"
                      ;;
                  3)
                      backup_sources
                      case "$ID" in
                          ubuntu)
                              switch_source $initial_ubuntu_source
                              ;;
                          debian)
                              switch_source $initial_debian_source
                              ;;
                          centos)
                              switch_source $initial_centos_source
                              ;;
                          *)
                              echo "未知系统，无法执行切换操作"
                              exit 1
                              ;;
                      esac
                      echo "已切换到初始更新源"
                      ;;
                  4)
                      restore_initial_source
                      ;;
                  5)
                      clear
                      bash <(curl -sSL https://raw.githubusercontent.com/SuperManito/LinuxMirrors/main/ChangeMirrors.sh)
                      break_end
                      ;;     
                  6)
                      clear
                      bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
                      break_end
                      ;;                 
                  0)
                      break
                      ;;
                  *)
                      echo "无效的选择，请重新输入"
                      ;;
              esac
              break_end

          done

              ;;

          20)

              while true; do
                  clear
                  echo "定时任务列表"
                  crontab -l
                  echo ""
                  echo "操作"
                  echo "------------------------"
                  echo "1. 添加定时任务              2. 删除定时任务"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                          read -p "请输入新任务的执行命令: " newquest
                          echo "------------------------"
                          echo "1. 每周任务                 2. 每天任务"
                          read -p $'\033[1;91m请输入你的选择: \033[0m' dingshi

                          case $dingshi in
                              1)
                                  read -p "选择周几执行任务？ (0-6，0代表星期日): " weekday
                                  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
                                  ;;
                              2)
                                  read -p "选择每天几点执行任务？（小时，0-23）: " hour
                                  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
                                  ;;
                              *)
                                  break  # 跳出
                                  ;;
                          esac
                          ;;
                      2)
                          read -p "请输入需要删除任务的关键字: " kquest
                          crontab -l | grep -v "$kquest" | crontab -
                          ;;
                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;
                  esac
              done

              ;;

          21)

            while true; do
                clear
                echo "ip端口扫描"
                echo "------------------------"
                echo "1. ipv4"
                echo "2. ipv6"
                echo "------------------------"
                echo "0. 返回上一级选单"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice   

                case $sub_choice in
                    1)
                        clear
                        # 检查是否已安装 nmap
                        if command -v nmap &> /dev/null; then
                            # nmap 已安装
                            echo -e "${green}nmap已存在，无需安装${re}"
                            while true; do
                                read -p "请输入你想要扫描的ipv4: " ip4
                                if [[ $ip4 =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
                                    break
                                else
                                    echo -e "${red}无效的IPv4地址，请重新输入${re}"
                                fi
                            done
                            sleep 1
                            echo -e "${green}开始扫描${ip4}开放的端口，请稍等...${re}"
                            nmap -sS -p 1-65535 $ip4
                            echo -e "${green}${ip4}端口已扫描完${re}"

                        else
                            # nmap 未安装，使用相应的包管理工具进行安装
                            echo -e "${yellow}nmap不存在. 开始安装nmap...${re}"
                            install "nmap"
                            sleep 1
                            clear
                            while true; do
                                read -p "请输入你想要扫描的ipv4: " ip4
                                if [[ $ip4 =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
                                    break
                                else
                                    echo -e "${red}无效的IPv4地址，请重新输入${re}"
                                fi
                            done
                            sleep 1
                            echo -e "${green}开始扫描${ip4}开放的端口，请稍等...${re}"
                            nmap -sS -p 1-65535 $ip4
                            echo -e "${green}${ip4}端口已扫描完${re}"

                        fi
                            break_end

                        ;;
                    
                    2)
                        clear
                        # 检查是否已安装 nmap
                        if command -v nmap &> /dev/null; then
                            # nmap 已安装
                            echo -e "${green}nmap已存在，无需安装${re}"
                            while true; do
                                read -p "请输入你想要扫描的ipv6: " ip6
                                if [[ $ip6 =~ ^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^::([0-9a-fA-F]{1,4}:){0,5}[0-9a-fA-F]{1,4}$|^([0-9a-fA-F]{1,4}:){1,6}:$|^([0-9a-fA-F]{1,4}:){1,6}::([0-9a-fA-F]{1,4}:){0,4}[0-9a-fA-F]{1,4}$ ]]; then
                                    break
                                else
                                    echo -e "${red}无效的IPv6地址，请重新输入${re}"
                                fi
                            done
                            sleep 1
                            echo -e "${green}开始扫描${ip6}开放的端口，请稍等...${re}"
                            nmap -6 -sS -p 1-65535 $ip6
                            echo -e "${green}${ip6}端口已扫描完${re}"

                        else
                            # nmap 未安装，使用相应的包管理工具进行安装
                            echo -e "${yellow}nmap不存在. 开始安装nmap...${re}"
                            install "nmap"
                            sleep 1
                            while true; do
                                read -p "请输入你想要扫描的ipv6: " ip6
                                if [[ $ip6 =~ ^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^::([0-9a-fA-F]{1,4}:){0,5}[0-9a-fA-F]{1,4}$|^([0-9a-fA-F]{1,4}:){1,6}:$|^([0-9a-fA-F]{1,4}:){1,6}::([0-9a-fA-F]{1,4}:){0,4}[0-9a-fA-F]{1,4}$ ]]; then
                                    break
                                else
                                    echo -e "${red}无效的IPv6地址，请重新输入${re}"
                                fi
                            done
                            sleep 1
                            echo -e "${green}开始扫描${ip6}开放的端口，请稍等...${re}"
                            nmap -6 -sS -p 1-65535 $ip6
                            echo -e "${green}${ip6}端口已扫描完${re}"

                        fi
                            break_end
                        ;;
                    0)
                        break  # 跳出循环，退出菜单
                    ;;

                    *)
                        break  # 跳出循环，退出菜单
                    ;; 
                esac
            done
            ;;

          22)
            # 检查依赖包
            check_packages() {
                install net-tools bc sysstat
            }
            check_packages
            
            while true; do
                clear
                echo -e "${yellow}服务器资源控制${re}"
                echo "------------------------"
                echo -e "${yellow}当CPU或内存或流量达到设置的阈值将采取关机操作${re}"
                echo "------------------------"
                echo "1. 一键限制CPU，当CPU达到99%自动关机"
                echo "2. 一键限制内存，内存达到99%自动关机"
                echo "3. 一键限制流量1T，流量达到1T自动关机"
                echo "4. CPU99%、内存99%、流量5T统一限制"
                echo "------------------------"
                echo "0. 返回上一级选单"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice   

                case $sub_choice in
                    1)
                        curl https://raw.githubusercontent.com/eooce/ssh_tool/main/check_cpu.sh -o check_cpu.sh && chmod +x check_cpu.sh && bash check_cpu.sh

                        # 添加Cron任务
                        (crontab -l 2>/dev/null; echo "*/10 * * * * /bin/bash /root/check_cpu.sh >> /root/check_cpu.log 2>&1") | crontab -
                        echo -e "${green}Cron任务已添加${re}"
                        break_end
                    ;;
                    2)
                        curl https://raw.githubusercontent.com/eooce/ssh_tool/main/check_memory.sh -o check_memory.sh && chmod +x check_memory.sh && bash check_memory.sh

                        # 添加Cron任务
                        (crontab -l 2>/dev/null; echo "*/10 * * * * /bin/bash /root/check_memory.sh >> /root/check_cpu.log 2>&1") | crontab -
                        echo -e "${green}Cron任务已添加${re}"
                        break_end                         
                    ;;
                    3)
                        curl https://raw.githubusercontent.com/eooce/ssh_tool/main/check_traffic.sh -o check_traffic.sh && chmod +x check_traffic.sh && bash check_traffic.sh

                        # 添加Cron任务
                        (crontab -l 2>/dev/null; echo "*/10 * * * * /bin/bash /root/check_traffic.sh >> /root/check_traffic.log 2>&1") | crontab -
                        echo -e "${green}Cron任务已添加${re}"
                        break_end                         
                    ;;
                    4)
                        curl https://raw.githubusercontent.com/eooce/ssh_tool/main/check.sh -o check.sh && chmod +x check.sh && bash check.sh

                        # 添加Cron任务
                        (crontab -l 2>/dev/null; echo "*/10 * * * * /bin/bash /root/check.sh >> /root/check.log 2>&1") | crontab -
                        echo -e "${green}Cron任务已添加${re}"
                        break_end                         
                    ;;

                    0)
                        break  # 跳出循环，退出菜单
                    ;;

                    *)
                        break  # 跳出循环，退出菜单
                    ;; 
                esac
            done
            ;;

          23)
            while true; do
                clear
                # 获取当前系统时区
                if [ -f /etc/alpine-release ]; then
                    if [ ! -f /etc/timezone ]; then
                        apk add --no-cache tzdata
                        cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
                        echo "Asia/Shanghai" > /etc/timezone
                        current_timezone=$(cat /etc/timezone)
                    else
                        current_timezone=$(cat /etc/timezone)
                    fi
                else
                    current_timezone=$(timedatectl show --property=Timezone --value)
                fi
                clear
                echo -e "${green}系统时间信息${re}"
                echo ""
                # 获取当前系统时间
                current_time=$(date +"%Y-%m-%d %H:%M:%S")

                # 显示时区和时间
                echo -e "${purple}当前系统时区：${re}${yellow}${current_timezone}${re}"
                echo -e "${purple}当前系统时间：${re}${yellow}${current_time}${re}"

                echo ""
                echo "时区切换"
                echo "亚洲------------------------"
                echo " 1. 中国上海时间              2. 中国香港时间"
                echo " 3. 日本东京时间              4. 韩国首尔时间"
                echo " 5. 新加坡时间                6. 印度加尔各答时间"
                echo " 7. 阿联酋迪拜时间            8. 澳大利亚悉尼时间"
                echo "欧洲------------------------"
                echo "11. 英国伦敦时间             12. 法国巴黎时间"
                echo "13. 德国柏林时间             14. 俄罗斯莫斯科时间"
                echo "15. 荷兰尤特赖赫特时间       16. 西班牙马德里时间"
                echo "美洲------------------------"
                echo "21. 美国西部时间             22. 美国东部时间"
                echo "23. 加拿大时间               24. 墨西哥时间"
                echo "25. 巴西时间                 26. 阿根廷时间"
                echo "------------------------"
                echo " 0. 返回上一级选单"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                case $sub_choice in
                    1) timedatectl set-timezone Asia/Shanghai ;;
                    2) timedatectl set-timezone Asia/Hong_Kong ;;
                    3) timedatectl set-timezone Asia/Tokyo ;;
                    4) timedatectl set-timezone Asia/Seoul ;;
                    5) timedatectl set-timezone Asia/Singapore ;;
                    6) timedatectl set-timezone Asia/Kolkata ;;
                    7) timedatectl set-timezone Asia/Dubai ;;
                    8) timedatectl set-timezone Australia/Sydney ;;
                    11) timedatectl set-timezone Europe/London ;;
                    12) timedatectl set-timezone Europe/Paris ;;
                    13) timedatectl set-timezone Europe/Berlin ;;
                    14) timedatectl set-timezone Europe/Moscow ;;
                    15) timedatectl set-timezone Europe/Amsterdam ;;
                    16) timedatectl set-timezone Europe/Madrid ;;
                    21) timedatectl set-timezone America/Los_Angeles ;;
                    22) timedatectl set-timezone America/New_York ;;
                    23) timedatectl set-timezone America/Vareouver ;;
                    24) timedatectl set-timezone America/Mexico_City ;;
                    25) timedatectl set-timezone America/Sao_Paulo ;;
                    26) timedatectl set-timezone America/Argentina/Buenos_Aires ;;
                    0) break ;; # 跳出循环，退出菜单
                    *) break ;; # 跳出循环，退出菜单
                esac
            done
            ;;

          24)
            clear
            wget --no-check-certificate -qO natcfg.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/natcfg.sh && bash natcfg.sh
            sleep 2
            break_end
            ;;
          25)
            clear
                echo -e "${yellow}初始化环境...${re}"
                install sshpass
                clear
                read -p $'\033[1;35m请输入要连接的ipv4/ipv6地址: \033[0m' common_ip
                
                echo -e "${green}即将进入nano编辑器，请添加nat小鸡配置信息${re}"
                sleep 1
                echo -e "# 示例配置: \n# ex1 20001 8a2a7f65c 30001 30025" > server.txt
                nano -w server.txt
                echo -e "${green}进入测试中,请稍等...${re}"

                if [ -f "server.txt" ]; then
                    mapfile -t lines < "server.txt"

                    # 遍历配置文件进行连接测试
                    for line in "${lines[@]}"; do
 
                        if [[ "$line" == \#* || -z "$line" ]]; then
                            continue
                        fi

                        name=$(echo "$line" | awk '{print $1}')
                        port=$(echo "$line" | awk '{print $2}')
                        password=$(echo "$line" | awk '{print $3}')

                        ssh_output=$(sshpass -p "$password" ssh -p "$port" -o ConnectTimeout=5 "root@$common_ip" "echo Connection successful!" 2>&1 || true)

                        if [[ "$ssh_output" == *successful* ]]; then
                            echo -e "${green}$name $port $password connect successful${re}"
                        else
                            echo -e "${red}$name $port $password connect failed${re}"
                        fi
                    done

                else
                    echo -e "${red}未找到server.txt配置文件${re}"
                    exit 1
                fi

                rm server.txt
                
              ;;
          26)
            fox_docker_app_market
            ;;

          27)
            fox_kernel_optimize_menu
            ;;

          28)
            fox_fail2ban_menu
            ;;

          29)
            fox_clamav_menu
            ;;

          30)
            fox_backup_menu
            ;;

          31)
            fox_tg_monitor
            ;;

          80)
            clear
            install sshpass

            remote_ip="8.8.8.8"
            remote_user="liaotian123"
            remote_file="/home/liaotian123/liaotian.txt"
            password="wangYYDS"  # 替换为您的密码

            clear
            echo "留言板"
            echo "------------------------"
            # 显示已有的留言内容
            sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${remote_user}@${remote_ip}" "cat '${remote_file}'"
            echo ""
            echo "------------------------"

            # 判断是否要留言
            read -p "是否要留言？(y/n): " leave_message

            if [ "$leave_message" == "y" ] || [ "$leave_message" == "Y" ]; then
                # 输入新的留言内容
                read -p "输入你的昵称: " nicheng
                read -p "输入你的聊天内容: " neirong

                # 添加新留言到远程文件
                sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${remote_user}@${remote_ip}" "echo -e '${nicheng}: ${neirong}' >> '${remote_file}'"
                echo "已添加留言: "
                echo "${nicheng}: ${neirong}"
                echo ""
            else
                echo "您选择了不留言。"
            fi

            echo "留言板操作完成。"

              ;;

          99)
              clear
              echo "正在重启服务器，即将断开SSH连接"
              reboot
              ;;
          0)
              main_menu

              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      break_end

    done
    ;;


  11)
    while true; do
      clear
      echo "▶ 我的工作区"
      echo "系统将为你提供5个后台运行的工作区，你可以用来执行长时间的任务"
      echo "即使你断开SSH，工作区中的任务也不会中断，非常方便！来试试吧！"
      echo -e "\033[33m注意: 进入工作区后使用Ctrl+b再单独按d，退出工作区！\033[0m"
      echo "------------------------"
      echo "a. 安装工作区环境"
      echo "------------------------"
      echo "1. 1号工作区"
      echo "2. 2号工作区"
      echo "3. 3号工作区"
      echo "4. 4号工作区"
      echo "5. 5号工作区"
      echo "------------------------"
      echo "8. 工作区状态"
      echo "------------------------"
      echo "b. 卸载工作区"
      echo "------------------------"
      echo -e "${skyblue}0. 返回主菜单${re}"
      echo "------------------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

      case $sub_choice in
          a)
              clear
              install tmux

              ;;
          b)
              clear
              remove tmux
              ;;
          1)
              clear
              SESSION_NAME="work1"

              # Check if the session already exists
              tmux has-session -t $SESSION_NAME 2>/dev/null

              # $? is a special variable that holds the exit status of the last executed command
              if [ $? != 0 ]; then
                # Session doesn't exist, create a new one
                tmux new -s $SESSION_NAME
              else
                # Session exists, attach to it
                tmux attach-session -t $SESSION_NAME
              fi
              ;;
          2)
              clear
              SESSION_NAME="work2"

              # Check if the session already exists
              tmux has-session -t $SESSION_NAME 2>/dev/null

              # $? is a special variable that holds the exit status of the last executed command
              if [ $? != 0 ]; then
                # Session doesn't exist, create a new one
                tmux new -s $SESSION_NAME
              else
                # Session exists, attach to it
                tmux attach-session -t $SESSION_NAME
              fi
              ;;
          3)
              clear
              SESSION_NAME="work3"

              # Check if the session already exists
              tmux has-session -t $SESSION_NAME 2>/dev/null

              # $? is a special variable that holds the exit status of the last executed command
              if [ $? != 0 ]; then
                # Session doesn't exist, create a new one
                tmux new -s $SESSION_NAME
              else
                # Session exists, attach to it
                tmux attach-session -t $SESSION_NAME
              fi
              ;;
          4)
              clear
              SESSION_NAME="work4"

              # Check if the session already exists
              tmux has-session -t $SESSION_NAME 2>/dev/null

              # $? is a special variable that holds the exit status of the last executed command
              if [ $? != 0 ]; then
                # Session doesn't exist, create a new one
                tmux new -s $SESSION_NAME
              else
                # Session exists, attach to it
                tmux attach-session -t $SESSION_NAME
              fi
              ;;
          5)
              clear
              SESSION_NAME="work5"

              # Check if the session already exists
              tmux has-session -t $SESSION_NAME 2>/dev/null

              # $? is a special variable that holds the exit status of the last executed command
              if [ $? != 0 ]; then
                # Session doesn't exist, create a new one
                tmux new -s $SESSION_NAME
              else
                # Session exists, attach to it
                tmux attach-session -t $SESSION_NAME
              fi
              ;;

          8)
              clear
              tmux list-sessions
              ;;
          0)
              main_menu
              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      break_end

    done
    ;;


  12)
    while true; do
      clear
      echo -e "${purple}▶ 节点搭建脚本合集${re}"
      echo -e "${green}---------------------------------------------------------${re}"
      echo -e "${green}       Sing-box多合一             Argo-tunnel${re}"
      echo -e "${green}---------------------------------------------------------${re}"
      echo -e "${white} 1. F佬Sing-box一键脚本        5. 老王xray-2go一键脚本${re}"
      echo -e "${white} 2. 老王Sing-box四合一         6. F佬ArgoX一键脚本${re}"
      echo -e "${white} 3. 勇哥Sing-box四合一         7. Suoha一键Argo脚本${re}"
      echo -e "${white} 4. 233boy.sing-box一键脚本    8. 老王小钢炮(可挂哪吒)${re}"
      echo -e "${yellow}---------------------------------------------------------${re}"
      echo -e "${yellow}        单协议                    XRAY面板及其他${re}"
      echo -e "${yellow}---------------------------------------------------------${re}"
      echo -e "${white} 9. 老王Hysteria2一键脚本     13.新版X-UI面板一键脚本${re}"
      echo -e "${white}10. 老王Juicity一键脚本       14.伊朗版3X-UI面板一键脚本${re}"
      echo -e "${white}11. 老王Tuic-v5一键脚本       15.OpenVPN一键安装脚本 ${re}"
      echo -e "${white}12. Snell一键安装脚本         16.一键搭建TG代理 ${re}"
      echo -e "${white}17. 老王Reality一键脚本       18.sing-box面板(sui) ▶${re}"
      echo "---------------------------------------------------------" 
      echo -e "${skyblue} 0. 返回主菜单${re}"
      echo "---------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice   

      case $sub_choice in

        1)
        clear
            bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/sing-box/main/sing-box.sh)
            break_end
        ;;
        2)
        clear
            bash <(curl -Ls https://raw.githubusercontent.com/eooce/sing-box/main/sing-box.sh)
            break_end
        ;;
        3)
        clear
            bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh)
            break_end
        ;;
        4)
        clear
            install wget
            bash <(wget -qO- -o- https://github.com/233boy/sing-box/raw/main/install.sh)
            break_end
        ;;
        5)
        clear
            bash <(curl -Ls https://github.com/eooce/xray-2go/raw/main/xray_2go.sh)
            break_end 
        ;;
        6)
        clear
            bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/argox/main/argox.sh)
            break_end         
        ;;            
        7)
        clear
            bash <(curl -Ls https://www.baipiao.eu.org/suoha.sh)
            break_end             
        ;; 
        8)
        clear
            install wget bash
            clear

            read -p $'\033[1;33m是否需要安装哪吒探针？(y/n) 【直接回车不安装】: \033[0m' nezha
            
            if [ "$nezha" == "y" ] || [ "$nezha" == "Y" ]; then
                read -p $'\033[1;35m请输入哪吒客域名(v1格式: nezha.xxx.com:8008  v0格式: nezha.xxx.com): \033[0m' nzserver
                read -p $'\033[1;35m请输入哪吒agent端口(哪吒v1请直接回车留空): \033[0m' nzport
                read -p $'\033[1;35m请输入哪吒agnt密钥: \033[0m' nzkey
            fi
            read -p $'\033[1;33m是否需要使用固定隧道？(直接回车将使用临时隧道 y/n) : \033[0m' isargo
            if [ "$isargo" == "y" ] || [ "$isargo" == "Y" ]; then
                read -p $'\033[1;35m请输入固定隧道的域名(格式: xxx.xxx.com): \033[0m' argodomain
                read -p $'\033[1;35m请输入固定隧道密钥(json或token): \033[0m' argokey
            fi

            read -p $'\033[1;33m是否需要直连协议(hy2,tuic,reality,anytls,socks5,anyReality等,直接回车不启用)？(y/n) : \033[0m' isdirect
            if [ "$isdirect" == "y" ] || [ "$isdirect" == "Y" ]; then
                read -p $'\033[1;35m请输入Hy2节点端口(不需要可直接回车留空): \033[0m' hy2pt
                read -p $'\033[1;35m请输入Tuic节点端口(不需要可直接回车留空): \033[0m' tuicpt
                read -p $'\033[1;35m请输入Reality节点端口(不需要可直接回车留空): \033[0m' realitypt
                read -p $'\033[1;35m请输入Anytls节点端口(不需要可直接回车留空): \033[0m' anytlspt
                read -p $'\033[1;35m请输入Socks5节点端口(不需要可直接回车留空): \033[0m' socks5pt
                read -p $'\033[1;35m请输入AnyReality节点端口(不需要可直接回车留空): \033[0m' anyrealitypt
            fi
            read -p $'\033[1;35m请输入你的UUID(留空将随机生成,哪吒v1将依赖此uuid): \033[0m' uuid
            [[ -z $uuid ]] && uuid=$(cat /proc/sys/kernel/random/uuid)
            UUID=$uuid NEZHA_SERVER=$nzserver NEZHA_PORT=$nzport NEZHA_KEY=$nzkey ARGO_DOMAIN=$argodomain ARGO_AUTH=$argokey HY2_PORT=$hy2pt TUIC_PORT=$tuicpt REALITY_PORT=$realitypt ANYTLS_PORT=$anytlspt S5_PORT=$socks5pt ANYREALITY_PORT=$anyrealitypt bash <(curl -Ls https://main.ssss.nyc.mn/sb.sh)
            sleep 1
            break_end
        ;;
        9)
        while true; do
        clear
          echo "--------------"
          echo -e "${green}1.安装Hysteria2${re}"
          echo -e "${red}2.卸载Hysteria2${re}"
          echo -e "${yellow}3.更换Hysteria2端口${re}"          
          echo "--------------"
          echo -e "${skyblue}0. 返回上一级菜单${re}"
          echo "--------------"
          read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
            case $sub_choice in
                1)
                  clear
                    read -p $'\033[1;35m请输入Hysteria2节点端口(nat小鸡请输入可用端口范围内的端口),回车跳过则使用随机端口：\033[0m' port
                    [[ -z $port ]]
                    until [[ -z $(netstat -tuln | grep -w udp | awk '{print $4}' | sed 's/.*://g' | grep -w "$port") ]]; do
                        if [[ -n $(netstat -tuln | grep -w udp | awk '{print $4}' | sed 's/.*://g' | grep -w "$port") ]]; then
                            echo -e "${red}${port}端口已经被其他程序占用，请更换端口重试${re}"
                            read -p $'\033[1;35m设置Hysteria2端口[1-65535]（回车将使用随机端口）：\033[0m' port
                            [[ -z $HY2_PORT ]] && port=8880
                        fi
                    done
                    if [ -f "/etc/alpine-release" ]; then
                        SERVER_PORT=$port bash -c "$(curl -L https://raw.githubusercontent.com/eooce/scripts/master/containers-shell/hy2.sh)"
                    else
                        HY2_PORT=$port bash -c "$(curl -L https://raw.githubusercontent.com/eooce/scripts/master/Hysteria2.sh)"
                    fi
                    sleep 1
                    break_end

                    ;;
                2)
                    if [ -f "/etc/alpine-release" ]; then
                        pkill -f '[w]eb'
                        pkill -f '[n]pm'
                        cd && rm -rf web npm server.crt server.key config.yaml
                    else
                        systemctl stop hysteria-server.service
                        rm /usr/local/bin/hysteria
                        rm /etc/systemd/system/hysteria-server.service
                        rm /etc/hysteria/config.yaml
                        sudo systemctl daemon-reload
                        clear
                    fi
                    echo -e "${green}Hysteria2已卸载${re}"
                    break_end
                    ;;
                3)
                    clear
                        read -p $'\033[1;35m设置Hysteria2端口[1-65535]（回车跳过将使用随机端口）：\033[0m' new_port
                        [[ -z $new_port ]] && new_port=$(shuf -i 2000-65000 -n 1)
                        until [[ -z $(netstat -tuln | grep -w udp | awk '{print $4}' | sed 's/.*://g' | grep -w "$new_port") ]]; do
                            if [[ -n $(netstat -tuln | grep -w udp | awk '{print $4}' | sed 's/.*://g' | grep -w "$new_port") ]]; then
                                echo -e "${red}${new_port}端口已经被其他程序占用，请更换端口重试${re}"
                                read -p $'\033[1;35m设置Hysteria2端口[1-65535]（回车跳过将使用随机端口）：\033[0m' new_port
                                [[ -z $new_port ]] && new_port=$(shuf -i 2000-65000 -n 1)
                            fi
                        done
                        if [ -f "/etc/alpine-release" ]; then
                            sed -i "s/^listen: :[0-9]*/listen: :$new_port/" /root/config.yaml
                            pkill -f '[w]eb'
                            nohup ./web server config.yaml >/dev/null 2>&1 &
                        else
                            clear
                            sed -i "s/^listen: :[0-9]*/listen: :$new_port/" /etc/hysteria/config.yaml
                            systemctl restart hysteria-server.service
                        fi
                        echo -e "${green}Hysteria2端口已更换成$new_port,请手动更改客户端配置!${re}"
                        sleep 1   
                        break_end
                    ;;

                0)
                    break

                    ;;                   
                *)
                    echo -e "${red}无效的输入!${re}"
                    ;;
            esac  
        done
        ;;     
        10)
        clear
            bash <(curl -Ls https://raw.githubusercontent.com/eooce/scripts/master/juicity.sh)
            break_end
        ;;   
        11)
        clear
            bash -c "$(curl -L https://raw.githubusercontent.com/eooce/scripts/master/tuic.sh)"
            break_end
        ;;      

        12)
        clear
            install wget && wget -O snell.sh --no-check-certificate https://git.io/Snell.sh && chmod +x snell.sh && ./snell.sh
            break_end
        ;;

        13)
        clear
            bash <(curl -Ls https://raw.githubusercontent.com/slobys/x-ui/main/install.sh)
            break_end
        ;; 
        14)
        clear
            bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
            break_end
        ;;           
        15)
        clear
            install wget && wget https://git.io/vpn -O openvpn-install.sh && bash openvpn-install.sh
            break_end
        ;;   

        16)
        clear
            install iproute2
            clear
            read -p $'\033[1;35m请输入MTProto代理端口(直接回车则使用随机端口): \033[0m' port
            while true; do
                if [[ -z $port ]]; then
                    port=$(shuf -i 2000-65000 -n 1)
                    echo -e "${green}使用随机端口: $port${re}"
                fi
                
                # 检查端口是否被占用
                if [[ -n $(ss -tln | grep ":$port ") ]] || [[ -n $(lsof -i :$port 2>/dev/null) ]]; then
                    if [[ $port == "$original_port" ]]; then
                        echo -e "${red}${port}端口已经被其他程序占用，请更换端口重试${re}"
                    else
                        echo -e "${red}随机生成的端口 ${port} 已被占用，重新生成...${re}"
                    fi
                    port=""
                    continue
                else
                    break
                fi
            done
            PORT=$port bash <(curl -Ls https://raw.githubusercontent.com/eooce/scripts/master/mtp.sh)
            sleep 1
            break_end
        ;;

        17)
        while true; do
        clear
          echo "--------------"
          echo -e "${green}1.安装Reality${re}"
          echo -e "${red}2.卸载Reality${re}"
          echo -e "${yellow}3.更换Reality端口${re}"          
          echo "--------------"
          echo -e "${skyblue}0. 返回上一级菜单${re}"
          echo "--------------"
          read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
            case $sub_choice in
                1)
                  clear
                    install lsof
                    clear
                    read -p $'\033[1;35m请输入reality节点端口(nat小鸡请输入可用端口范围内的端口),回车跳过则使用随机端口：\033[0m' port
                    [[ -z $port ]]
                    until [[ -z $(lsof -i :$port 2>/dev/null) ]]; do
                        if [[ -n $(lsof -i :$port 2>/dev/null) ]]; then
                            echo -e "${red}${port}端口已经被其他程序占用，请更换端口重试${re}"
                            read -p $'\033[1;35m设置 reality 端口[1-65535]（回车跳过将使用随机端口）：\033[0m' port
                            [[ -z $port ]] && port=$(shuf -i 2000-65000 -n 1)
                        fi
                    done
                    if [ -f "/etc/alpine-release" ]; then
                        PORT=$port bash -c "$(curl -L https://raw.githubusercontent.com/eooce/scripts/master/test.sh)"
                    else
                        PORT=$port bash -c "$(curl -L https://raw.githubusercontent.com/eooce/xray-reality/master/reality.sh)"
                    fi
                    sleep 1
                    break_end
                    ;;
                2)
                if [ -f "/etc/alpine-release" ]; then
                    pkill -f '[w]eb'
                    pkill -f '[n]pm'
                    cd && rm -rf app
                    clear
                else
                    sudo systemctl stop xray
                    sudo rm /usr/local/bin/xray
                    sudo rm /etc/systemd/system/xray.service
                    sudo rm /usr/local/etc/xray/config.json
                    sudo rm /usr/local/share/xray/geoip.dat
                    sudo rm /usr/local/share/xray/geosite.dat
                    sudo rm /etc/systemd/system/xray@.service

                    # Reload the systemd daemon
                    sudo systemctl daemon-reload

                    # Remove any leftover Xray files or directories
                    sudo rm -rf /var/log/xray /var/lib/xray
                    clear
                  fi

                    echo -e "\e[1;32mReality已卸载\033[0m"
                    break_end
                    ;;
                3)
                    clear
                        read -p $'\033[1;35m设置 reality 端口[1-65535]（回车跳过将使用随机端口）：\033[0m' new_port
                        [[ -z $new_port ]] && new_port=$(shuf -i 2000-65000 -n 1)
                        until [[ -z $(lsof -i :$new_port 2>/dev/null) ]]; do
                            if [[ -n $(lsof -i :$new_port 2>/dev/null) ]]; then
                                echo -e "${red}${new_port}端口已经被其他程序占用，请更换端口重试${re}"
                                read -p $'\033[1;35m设置reality端口[1-65535]（回车跳过将使用随机端口）：\033[0m' new_port
                                [[ -z $new_port ]] && new_port=$(shuf -i 2000-65000 -n 1)
                            fi
                        done
                        install jq 
                        if [ -f "/etc/alpine-release" ]; then
                            jq --argjson new_port "$new_port" '.inbounds[0].port = $new_port' /root/app/config.json > tmp.json && mv tmp.json /root/app/config.json
                            pkill -f '[w]eb'
                            cd ~ && cd app
                            nohup ./web -c config.json >/dev/null 2>&1 &
                        else
                            clear
                            jq --argjson new_port "$new_port" '.inbounds[0].port = $new_port' /usr/local/etc/xray/config.json > tmp.json && mv tmp.json /usr/local/etc/xray/config.json
                            systemctl restart xray.service
                        fi
                        echo -e "${green}Reality端口已更换成$new_port,请手动更改客户端配置!${re}"
                        sleep 1   
                        break_end
                    ;;
                0)
                    break

                    ;;
                *)
                    echo -e "${red}无效的输入!${re}"
                    ;;
            esac  
        done
        ;;

        18)
        while true; do
        clear
          echo -e "${skyblue}▶ Sui面板${re}"
          echo "--------------"
          echo -e "${green}1.安装sui面板${re}"
          echo -e "${red}2.卸载sui面板${re}"
          echo "--------------"
          echo -e "${skyblue}0. 返回上一级菜单${re}"
          echo "--------------"
          read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
            case $sub_choice in
                1)
                    bash <(curl -Ls https://raw.githubusercontent.com/Misaka-blog/s-ui/master/install.sh)
                    sleep 2
                    echo ""
                    break_end

                    ;;
                2)
                    systemctl disable sing-box --now
                    systemctl disable s-ui --now

                    rm -f /etc/systemd/system/s-ui.service
                    rm -f /etc/systemd/system/sing-box.service
                    systemctl daemon-reload

                    rm -fr /usr/local/s-ui
                    clear
                    echo -e "${green}sui面板已卸载${re}"
                    break_end

                    ;;
                0)
                    break

                    ;;
                *)
                    echo -e "${red}无效的输入!${re}"
                    ;;
            esac  
        done
        ;;
        0)
            main_menu # 返回主菜单
        ;;

        *)
        break  # 跳出循环，退出菜单
        ;;
      esac
    done
    ;; 
    
  13)
    while true; do
      clear
      echo -e "${purple}▶ 测试脚本合集${re}"
      echo ""
      echo -e "${green}----IP及解锁状态检测-------${re}"
      echo -e "${green} 1. ChatGPT解锁状态检测${re}"
      echo -e "${green} 2. Region流媒体解锁测试${re}"
      echo -e "${green} 3. yeahwu流媒体解锁检测${re}"
      echo -e "${green} 4. xykt_IP质量体检脚本${re}"
      echo ""
      echo -e "${skyblue}----网络线路测速-----------${re}"
      echo -e "${skyblue} 5. Superspeed三网测速${re}"
      echo -e "${skyblue} 6. nxtrace快速回程测试${re}"
      echo -e "${skyblue} 7. ludashi2020三网线路测试${re}"
      echo -e "${skyblue} 8. mtr_trace三网回程线路测试${re}"
      echo -e "${skyblue} 9. besttrace三网回程延迟路由测试${re}"
      echo ""
      echo -e "${green}----硬件性能测试-----------${re}"
      echo -e "${green}10. yabs性能测试${re}"
      echo -e "${green}11. icu/gb5 CPU性能测试脚本${re}"
      echo ""
      echo -e "${purple}----综合性测试-------------${re}"
      echo -e "${purple}12. bench性能测试${re}"
      echo -e "${purple}13. spiritysdx融合怪测评${re}"
      echo ""
      echo "---------------------------"
      echo -e "${skyblue} 0. 返回主菜单${re}"
      echo "---------------------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
      case $sub_choice in
          1)
              clear
              bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
              ;;
          2)
              clear
              bash <(curl -L -s check.unlock.media)
              ;;
          3)
              clear
              install wget
              wget -qO- https://github.com/yeahwu/check/raw/main/check.sh | bash
              ;;
          4)
              clear
              bash <(curl -Ls IP.Check.Place)
              ;;
          5)
              clear
              bash <(curl -Lso- https://git.io/superspeed_uxh)
              ;;
          6)
              clear
              curl nxtrace.org/nt |bash
              nexttrace --fast-trace --tcp
              ;;
          7)
              clear
              curl https://raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
              ;;
          8)
              clear
              curl https://raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
              ;;
          9)
              clear
              install wget
              wget -qO- git.io/besttrace | bash
              ;;
          10)
              clear
              curl -sL yabs.sh | bash -s -- -i -5
              ;;
          11)
              clear
              bash <(curl -sL bash.icu/gb5)
              ;;
          12)
              clear
              curl -Lso- bench.sh | bash
              ;;
          13)
              clear
              curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
              ;;
          0)
              main_menu
              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
        break_end
    done
    ;;

  14)
     while true; do
      clear
      echo -e "${green}▶ 甲骨文云脚本合集${re}"
      echo "------------------------"
      echo -e "${green}1. 一键闲置机器活跃${re}"
      echo -e "${green}2. 开启ROOT密码登录${re}"
      echo "------------------------"
      echo -e "${purple}3. 一键DD重装系统${re}"
      echo "------------------------"
      echo -e "${green}4. 安装R探长刷机${re}"
      echo -e "${red}5. 卸载R探长刷机${re}"
      echo "------------------------"
      echo -e "${skyblue}0. 返回主菜单${re}"
      echo "------------------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

      case $sub_choice in
          1)
             clear
              curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh -o oalive.sh && chmod +x oalive.sh && bash oalive.sh
            ;; 
          2)
              clear
              read -p $'\033[1;33m请设置你的root密码: \033[0m' pswd
              echo "root:$pswd" | chpasswd
              sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
              sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
              service sshd restart
              echo -e "${green}root登录设置完毕，请断开连接使用root+密码登录${re}"
            ;;  
          3)
          clear
          echo "请备份数据，将为你重装系统，预计花费15分钟。"
          read -p "确定继续吗？(Y/N): " choice

          case "$choice" in
            [Yy])
              while true; do
                read -p "请选择要重装的系统:  1. Debian12 | 2. Ubuntu20.04 : " sys_choice

                case "$sys_choice" in
                  1)
                    xitong="-d 12"
                    break  # 结束循环
                    ;;
                  2)
                    xitong="-u 20.04"
                    break  # 结束循环
                    ;;
                  *)
                    echo "无效的选择，请重新输入。"
                    ;;
                esac
              done

              read -p "请输入你重装后的密码: " vpspasswd
              install wget
              bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') $xitong -v 64 -p $vpspasswd -port 22
              ;;
            [Nn])
              echo "已取消"
              ;;
            *)
              echo "无效的选择，请输入 Y 或 N。"
              ;;
          esac
              ;;

          4)
              clear  
              echo -e "${purple}温馨提醒：自动抢机属于官方禁止行为，可能会造成封号现象，如因刷机造成封号，与本人无关！\n开始执行此任务前请确认以下3步是否操作完成。${re}"
              echo ""
              echo -e "${yellow}1：请确保你的服务器${purple}9527端口${yellow}可用，故此一键开机也不适合nat小鸡${re}"
              echo ""
              echo -e "${yellow}2：获取R探长机器人对应的${purple}username和password，${yellow}机器人获取链接https://t.me/radiance_helper_bot，使用/raninfo命令随机生成${re}"
              echo ""
              echo -e "${yellow}3：获取甲骨文云${purple}api密钥${yellow}下载文件并复制内容保存，获取方式在甲骨文云控制台右上角头像--我的概要信息里${re}"
              echo ""
              read -p $'\033[1;91m确定要继续吗？[y/n]: \033[0m' confirm
              echo ""

                if [[ $confirm =~ ^[Yy]$ ]]; then
                    echo -e "${yellow}开安装依赖...${re}"
                    install iptables wget nano
                    install_java
                    iptables -A INPUT -p tcp --dport 9527 -j ACCEPT
                    mkdir -p rtbot && cd rtbot
                    # 下载、解压、设置权限并后台运行 sh_client_bot.sh
                    wget -O sh_client_bot.sh https://github.com/semicons/java_oci_manage/releases/latest/download/sh_client_bot.sh && chmod +x sh_client_bot.sh && bash sh_client_bot.sh
                    clear 

                    while true; do
                        pid_tail=$(ps aux | grep '[t]ail' | awk '{print $2}')
                        pid_java=$(ps aux | grep '[j]ava' | grep -v 'grep' | awk '{print $2}')

                        tail_running=true
                        java_running=true

                        if [ ! -z "$pid_tail" ]; then
                            kill $pid_tail
                            echo -e "${green}已结束PID为${pid_tail}的tail进程。${re}"
                            tail_running=false
                        fi

                        if [ ! -z "$pid_java" ]; then
                            kill $pid_java
                            echo -e "${green}已结束PID为${pid_java}的java进程。${re}"
                            java_running=false
                        fi

                        if [ "$tail_running" = false ] && [ "$java_running" = false ]; then
                            break
                        fi

                        sleep 5
                    done
                    sleep 2
                    clear
                    echo ""
                    echo -e "${red}等待完成以下步骤,请完成后再确认${re}"
                    echo ""
                    echo -e "${yellow}1：获取R探长机器人对应的${purple}username和password，${yellow}机器人获取链接https://t.me/radiance_helper_bot${re}"
                    echo ""
                    echo -e "${yellow}2：获取甲骨文云${purple}api密钥下载文件并复制内容保存，${yellow}获取方式在甲骨文云控制台右上角头像--我的概要信息里${re}"
                    echo ""
                    echo -e "${yellow}3：将甲骨文云api密钥文件上传至root目录内，并复制文件路径保存，api密钥最后一行的路径改为此路径${re}"
                    echo ""                    
                    read -p $'\033[1;91m是否已完成以上步骤？[y/n]: \033[0m' confirm
                        sleep 1
                        if [[ $confirm =~ ^[Yy]$ ]]; then
                            # 使用 nano 编辑器打开文件
                            chmod +x /root/rtbot/client_config
                            echo ""
                            echo -e "${purple}即将打开/root/rtbot/client_config配置文件进行编辑。${re}"
                            echo ""
                            echo -e "${purple}键盘上下键定位，将api密钥(注意最后一行的路径)，username，password粘贴到指定位置${re}"
                            echo ""
                            echo -e "${purple}编辑完成后，请按顺序输入命令(Ctrl+O, Enter, Ctrl+X)保存退出${re}"
                            sleep 2
                            echo ""
                            read -p $'\033[1;91m是否清楚以上步骤？[y/n]: \033[0m' confirm

                            if [[ $confirm =~ ^[Yy]$ ]]; then
                                sleep 1
                                nano "/root/rtbot/client_config"
                                echo -e "${green}client_config配置更新成功。${re}"
                                sleep 1
                                echo -e "${green}开始执行抢机...${re}"
                                bash sh_client_bot.sh
                                sleep  3
                                echo -e "${green}正在后台执行抢机中，可关闭SSH，开机成功会在R探长bot上提醒...${re}"
                                sleep  3
                                main_menu
                            else 
                                echo -e "${yellow}请重新执行，正在退出...${re}"
                                sleep 1
                                rm -rf /root/rtbot
                                main_menu
                            fi
                        else 
                            echo -e "${yellow}已取消操作，正在退出...${re}"
                            rm -rf /root/rtbot
                            sleep 2
                            main_menu

                        fi
                else 
                    echo -e "${yellow}已取消操作，正在退出...${re}"
                    sleep 2
                    main_menu
                fi
              ;;

          5)
              clear
              ps -ef | grep r_client.jar | grep -v grep | awk '{print $2}' | xargs kill -9
              rm -rf /root/rtbot
              echo -e "${green}卸载完毕...${re}"
              break_end
              ;;
          0)
              main_menu

              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      break_end

    done
    ;;

  15)
    while true; do
        clear
       echo -e "${skyblue}▶ 常用环境管理${re}"
        echo "------------------------"
        echo -e "${green}1. 一键安装Python最新版${re}"
        echo -e "${green}2. 一键安装Nodejs最新版${re}"
        echo -e "${green}3. 一键安装Golang最新版${re}"
        echo -e "${green}4. 一键安装Java最新版${re}"
        echo "------------------------"
        echo -e "${red}5. 一键卸载Python${re}"
        echo -e "${red}6. 一键卸载Nodejs${re}"
        echo -e "${red}7. 一键卸载Golang${re}"
        echo -e "${red}8. 一键卸载Java${re}"
        echo "------------------------"
        echo -e "${skyblue}0. 返回主菜单${re}"
        echo "------------------------"
        read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

        case $sub_choice in
            1)
             clear
                # 获取系统信息
                OS=$(grep -o -E "Debian|Ubuntu|CentOS|Alpine|Fedora|Rocky|AlmaLinux|Amazon" /etc/os-release 2>/dev/null | head -n 1)

                # 检查系统支持性
                if [[ -n $OS ]]; then
                    echo -e "${green}检测到你的系统是${yellow}${OS}${re}"
                else
                    echo -e "${red}很抱歉，暂不支持的系统！${re}"
                    sleep 2
                    main_menu
                fi

                # 检测安装Python3的版本
                VERSION=$(python3 -V 2>&1 | awk '{print $2}')

                # 获取最新Python3版本
                PY_VERSION=$(curl -s https://www.python.org/ | grep "downloads/release" | grep -o 'Python [0-9.]*' | grep -o '[0-9.]*')

                # 卸载Python3旧版本
                if [[ $VERSION == "3"* ]]; then
                    if [ "$VERSION" = "$PY_VERSION" ]; then
                        echo -e "${green}检测到你的Python3版本已经是最新版本:${red}${PY_VERSION}${green}，无需安装或升级${re}"
                        sleep 2
                        main_menu
                    else
                        echo -e "${yellow}检测到你的Python3版本:${red}${VERSION}${yellow},最新版本:${green}${PY_VERSION}${re}"
                        read -p $'\033[1;91m是否确认升级最新版Python3？[y/n]: \033[0m' confirm
                        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                            if [[ $OS == "CentOS" ]]; then
                                yum remove python3 -y
                                package-cleanup --leaves
                                package-cleanup --orphans
                                yum autoremove -y
                                rm-rf /usr/local/python3* >/dev/null 2>&1
                                
                            elif [[ $OS == "Alpine" ]]; then
                                apk del python3
                                apk info --installed | xargs apk info --installed -R | cut -d: -f1 | sort | uniq -c | sort -n | grep -v ' 1 ' | awk '{print $2}' | xargs apk del
                                rm -rf /usr/lib/python3.*
                                rm -rf /etc/python3
                                rm -rf /var/cache/apk/*
                                    
                            elif [[ $OS == "Fedora" ]] || [[ $OS == "Rocky" ]] || [[ $OS == "AlmaLinux" ]] || [[ $OS == "Amazon" ]]; then
                                dnf remove python3 -y
                                dnf autoremove -y
                                rm -rf ~/.local/lib/python3.*                  
                            else
                                apt --purge remove python3 python3-pip -y
                                rm-rf /usr/local/python3*
                            fi
                        else
                            echo -e "${yellow}已取消升级Python3${re}"
                            sleep 1
                            main_menu
                        fi
                    fi   
                else
                    echo -e "${red}检测到没有安装Python3。${re}"
                    read -p $'\033[1;91m是否确认安装最新版Python3？[y/n]: \033[0m' confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                        echo -e "${green}开始安装最新版Python3...${re}"
                    else
                        echo -e "${yellow}已取消安装Python3${re}"
                        exit 1
                    fi
                fi

                # 安装相关依赖
                if [[ $OS == "CentOS" ]]; then
                    yum update -y
                    yum groupinstall -y "development tools"
                    yum install wget tar openssl-devel bzip2-devel libffi-devel zlib-devel -y
                elif [[ $OS == "Fedora" ]] || [[ $OS == "Rocky" ]] || [[ $OS == "AlmaLinux" ]] || [[ $OS == "Amazon" ]]; then
                    dnf update -y
                    dnf groupinstall -y "development tools"
                    dnf install wget tar openssl-devel bzip2-devel libffi-devel zlib-devel -y
                elif [[ $OS == "Alpine" ]]; then
                    apk update
                    apk add python3
                    apk add py3-pip
                    apk add wget tar openssl-dev bzip2-dev libffi-dev zlib-dev
                    sleep 2
                    break_end
                    exit 1
                else
                    apt update -y
                    apt install wget tar build-essential libreadline-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev -y
                fi
                
                # 安装python3
                install wget tar
                cd /root/
                wget https://www.python.org/ftp/python/${PY_VERSION}/Python-"$PY_VERSION".tgz
                tar -zxf Python-${PY_VERSION}.tgz
                cd Python-${PY_VERSION}
                ./configure --prefix=/usr/local/python3
                make -j $(nproc)
                make install
                if [ $? -eq 0 ];then
                    rm -f /usr/local/bin/python3*
                    rm -f /usr/local/bin/pip3*
                    ln -sf /usr/local/python3/bin/python3 /usr/bin/python3
                    ln -sf /usr/local/python3/bin/pip3 /usr/bin/pip3
                    clear
                    echo -e "${yellow}Python3安装${green}成功，${re}版本为: ${re}${green}${PY_VERSION}${re}"
                    sleep 2
                else
                    clear
                    echo -e "${red}Python3安装失败！${re}"
                    exit 1
                fi
                cd /root/ && rm -rf Python-${PY_VERSION}.tgz && rm -rf Python-${PY_VERSION}
            ;;

            2)
             clear
                # 检查系统中是否存在nodejs
                if command -v node &>/dev/null; then
                    # 获取当前nodejs版本
                    current_version=$(node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

                    # 获取最新nodejs版本
                    install jq
                    json_data=$(curl -s https://nodejs.org/dist/index.json)
                    latest_version=$(echo "$json_data" | jq -r '.[] | select(.lts != null) | .version' | head -n 1 | sed 's/^v//')
                    # echo "$latest_version"
                    if [ "$current_version" = "$latest_version" ]; then
                        echo -e "${yellow}当前版本${green}$current_version${yellow}已经是最新版${green}${latest_version}${yellow}，无需更新！${re}"
                        sleep 2
                        main_menu
                    else
                        # 如果不是最新版本
                        echo -e "${yellow}你的nodejs版本是${re}${red}${current_version}${re}，${yellow}最新版本是${purple}${latest_version}${re}"                                 
                        read -p $'\033[1;91m是否卸载旧版nodejs并安装最新版？[y/n]: \033[0m' confirm
                        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                                                       
                            remove nodejs
                            sleep 1

                            # 安装新版nodejs
                            install_nodejs
                        else
                            main_menu 
                        fi
                    fi

                else
                    install_nodejs
                    break_end
                fi           
                
            ;;

            3)
            clear
                # 获取最新版Go的版本
                html=$(curl -s https://go.dev/dl/)
                latest_version=$(echo "$html" | grep -oP 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)    
                
                # 根据系统架构选择不同的下载链接
                architecture=$(uname -m)
                case "$architecture" in
                    x86_64|amd64)
                        latest_version_url="https://golang.org/dl/${latest_version}.linux-amd64.tar.gz"
                        ;;
                    x86)
                        latest_version_url="https://golang.org/dl/${latest_version}.linux-386.tar.gz"
                        ;;
                    arm64|aarch64)
                        latest_version_url="https://golang.org/dl/${latest_version}.linux-arm64.tar.gz"
                        ;;
                    *)
                        echo -e "${red}暂不支持的系统架构：$architecture${re}"
                        sleep 2
                        main_menu
                        ;;
                esac
                
                # 检查是否已安装Go
                if command -v go &> /dev/null; then
                    # 获取当前已安装的Go版本
                    installed_version=$(go version | grep -oE 'go[0-9]+\.[0-9]+\.[0-9]+')
                    echo -e "${yellow}当前已安装的Go版本：${red}$installed_version${re}"
                
                    # 比较已安装版本与最新版本
                    if [ "$installed_version" = "$latest_version" ]; then
                        echo -e "${green}当前Go已经是最新版本，无需更新。${re}"
                        sleep 2
                        main_menu
                    elif [ "$(printf "$installed_version\n$latest_version" | sort -V | head -n 1)" != "$installed_version" ]; then
                        echo -e "${yellow}发现新版本：$latest_version。${re}"
                        read -p $'\033[1;91m需要卸载当前版本 $installed_version 并安装新版本 $latest_version 吗 [y/n]: \033[0m' confirm
                        
                        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                            echo "卸载旧版Go：$installed_version"
                            rm -rf /usr/local/go
                        else
                            echo -e "${yellow}退出更新。${re}"
                            sleep 2
                            break_end
                        fi
                    fi
                else
                    echo -e "${yellow}系统中未安装Go，正在为你安装最新版Go...${re}"
                fi
                
                # 下载并安装最新版Go
                install tar
                wget -O go_latest.tar.gz "$latest_version_url"
                tar -C /usr/local -xzf go_latest.tar.gz
                
                # 设置环境变量
                GO_PATH="/usr/local/go/bin"
                if [[ ":$PATH:" != *":${GO_PATH}:"* ]]; then
                    if grep -qi alpine /etc/os-release; then
                        echo "export PATH=${GO_PATH}:\$PATH" > /etc/profile.d/go.sh
                        chmod +x /etc/profile.d/go.sh
                        source /etc/profile.d/go.sh
                    else
                        echo "export PATH=${GO_PATH}:\$PATH" | tee -a /etc/profile > /dev/null
                        source /etc/profile
                    fi
                fi
                
                rm go_latest.tar.gz
                
                # 验证安装
                if command -v go &> /dev/null; then
                    echo -e "${green}GO安装完成，当前Go版本：${red}$(go version | grep -oE 'go[0-9]+\.[0-9]+\.[0-9]+' | cut -c 3-)${re}"
                    echo -e "${red}退出脚本后请手动执行以下命令使全局环境变量生效：${yellow}source /etc/profile${re}\n"
                else
                    echo -e "${red}Go安装完成，但全局环境变量未生效，请退出脚本后手动执行以下命令使全局环境变量生效：${yellow}source /etc/profile${re}\n"
                fi
              sleep 1
              break_end
            ;;            

            4)
              clear
                latest_version="17.0.10"
                if command -v java &>/dev/null; then
                    installed_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
                    echo -e "${green}当前Java版本是${yellow}${installed_version},最新版本是${green}${latest_version}${re}"

                    if [ "$installed_version" == "$latest_version" ]; then
                        echo -e "${green}当前已安装Java最新版：${yellow}${latest_version},无需更新${re}"
                        sleep 2
                        main_menu
                    else
                        echo -e "${red}"
                        read -p "是否卸载旧版java并安装最新版？[y/n]: " confirm
                        if [[ $confirm =~ ^[Yy]$ ]]; then
                            # 卸载旧版java
                            remove java
                            sleep 2
                            install_java                           

                        else
                            main_menu 
                        fi   
                    fi

                else
                    install_java
                fi
            ;;

            5)
             clear
                if command -v python3 &>/dev/null; then
                    # 获取当前安装的python版本
                    current_version=$(python3 --version 2>&1 | awk '{print $2}')   

                    echo -e "${yellow}当前已安装python${red}${current_version}"

                    read -p $'\033[1;91m确定卸载python？[y/n]: \033[0m' confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                    
                        # 卸载python3
                        remove python3

                        # 清理缓存配置文件
                        rm -rf /usr/bin/pip3
                        rm -rf /usr/bin/python3
                        rm -rf /usr/share/python3
                        rm -rf /usr/local/python3
                        rm -rf /usr/share/man/man1/python3.1.gz
                        rm -rf /usr/local/bin/python
                        rm -rf /usr/local/lib/python*
                        rm -rf /usr/local/bin/python*

                        echo -e "${green}python已卸载${re}"
                        break_end
                    else
                        main_menu
                    fi
                else
                    echo -e "${yellow}系统中未安装python，无需卸载${re}"
                    sleep 2
                    main_menu
                fi           
            ;;

            6)
             clear
                if command -v node &>/dev/null; then
                    # 获取当前安装的nodjs版本
                    current_version=$(node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')    

                    echo -e "${yellow}当前已安装nodejs${red}$current_version${re}"
                            
                    read -p $'\033[1;91m确定卸载nodejs？[y/n]: \033[0m' confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                        
                        # 卸载
                        remove nodejs npm 
         
                        # 清理缓存配置文件
                        rm -rf ~/.npm
                        rm -rf ~/.nvm
                        rm -rf /usr/local/bin/node
                        rm -rf /usr/local/lib/node_modules

                        echo -e "${green}nodejs已卸载${re}"
                        break_end
                    else
                        main_menu
                    fi
                else
                    echo -e "${yellow}系统中未安装nodejs，无需卸载${re}"
                    sleep 2
                    main_menu
                fi           
            ;;

            7)
             clear
                if command -v go &> /dev/null; then
                    # 获取当前安装的Go版本
                    installed_version=$(go version | grep -oE 'go[0-9]+\.[0-9]+\.[0-9]+' | cut -c 3-)   

                    echo -e "${yellow}当前已安装Go：${red}$installed_version${re}"
                            
                    read -p $'\033[1;91m确定卸载Go？[y/n]: \033[0m' confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then

                        rm -rf /usr/local/go

                        # 清理环境变量
                        export PATH=$PATH:/usr/local/go/bin
                        export GOPATH=$HOME/go
                        export PATH=$PATH:$GOPATH/bin
                        source ~/.bashrc && source ~/.profile && source ~/.bash_profile

                        echo -e "${green}Go已卸载${re}"
                        sleep 1
                        break_end

                    else
                        main_menu
                    fi
                else
                    echo -e "${yellow}系统中未安装Go，无需卸载${re}"
                    sleep 2
                    main_menu
                fi           
            ;;

            8)
             clear
                if command -v java &> /dev/null; then
                    # 获取当前安装的Java版本
                    installed_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
                    echo -e "${yellow}你的Java版本：${red}${installed_version}${re}"

                    read -p $'\033[1;91m确定卸载Java？[y/n]: \033[0m' confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then

                        remove_java() {
                            local remove_status=0

                            if command -v apt &>/dev/null; then
                                apt remove -y openjdk-17-jdk && apt autoremove -y openjdk-17-jdk
                            elif command -v yum &>/dev/null; then
                                yum remove -y java && yum autoremove -y java
                            elif command -v dnf &>/dev/null; then
                                dnf remove -y java && dnf autoremove -y java
                            elif command -v apk &>/dev/null; then
                                apk del openjdk17
                            else
                                echo -e "${red}暂不支持你的系统！${re}"
                                exit 1
                            fi
                            # 检查是否安装成功，如果没有成功则重新
                            if [ $remove_status -eq 0 ]; then
                                echo -e "${green}Java卸载成功！${re}"
                            else                    
                                echo -e "${red}Java卸载失败，请重试!${re}"
                                break_end
                            fi
                        }
                        remove_java

                        rm -rf /usr/lib/jvm/java-*
                        rm -rf /usr/local/java
                        rm -rf /opt/java
                        echo -e "${red}"
                        read -p $'\033[1;91m重启服务器配置才可生效，需要立即重启吗 [y/n]: \033[0m' confirm

                        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                            sleep 1
                            reboot
                        else
                            main_menu
                        fi

                    else
                        main_menu
                    fi
                else
                    echo -e "${yellow}系统中未安装Java，无需卸载${re}"
                    sleep 2
                fi           
            ;;

            0)
                main_menu
            ;;

            *)
            echo -e "${yellow}无效的输入!${re}"
            ;;
        esac
    done
    ;; 

  16)
    while true; do
        clear
        echo -e "${purple}▶ 管理NAT小鸡${re}"
        echo "------------------------"
        echo -e "${yellow}开设kvm小鸡分两步，请依次执行。 \n如果第一步失败，请选择其他方式开设小鸡。\n建议选择4或9，大部分vps都兼容！${re}"
        echo "------------------------"
        echo -e "${skyblue} 1. 开设KVM小鸡(第1步)${re}" 
        echo -e "${skyblue} 2. 开设KVM小鸡(第2步)${re}"
        echo -e "${red} 3. 删除所有KVM小鸡${re}"
        echo "------------------------"
        echo -e "${green} 4. 开设LXC小鸡(官方版)${re}" 
        echo -e "${green} 5. 开设LXC小鸡(魔改版)${re}" 
        echo -e "${skyblue} 6. 管理LXC小鸡 ▶${re}"
        echo "------------------------"
        echo -e "${green} 7. 开设Docker小鸡${re}"
        echo -e "${red} 8. 删除所有Docker容器${re}"
        echo "------------------------"
        echo -e "${green} 9. 开设incus小鸡(官方版)${re}" 
        echo -e "${skyblue}10. 管理incus小鸡 ▶${re}"
        echo "------------------------"
        echo -e "${skyblue} 0. 返回主菜单${re}"
        echo "------------------------"
        while :; do
            echo
            read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
            if ! [[ "$sub_choice" =~ ^[0-9]+$ ]]; then
                echo -e "${red}输入错误, 请输入0~10的数字!${re}"
                continue
            fi
            if [ $sub_choice -ge 0 -a $sub_choice -le 12 ]; then
                break
            else
                echo -e "${red}输入错误, 请输入0~10的数字!${re}"   
            fi
        done
        case $sub_choice in 
            1)
                clear
                echo -e "${yellow}开始进行环境检测...${re}"
                install wget
                output=$(bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/oneclickvirt/pve/main/scripts/check_kernal.sh))
                echo "$output"
                if echo "$output" | grep -q "CPU不支持硬件虚拟化，无法嵌套虚拟化KVM服务器，但可以开LXC服务器(CT)"; then
                    echo ""
                    echo -e "${red}你的服务器不支持开设KVM小鸡，建议选择4或9开设其他类型，正在退出...${re}"
                    rm -rf /root/check_kernal.sh
                    sleep 2
                    break_end

                elif echo "$output" | grep -q "本机符合要求：可以使用PVE虚拟化KVM服务器，并可以在开出来的KVM服务器选项中开启KVM硬件虚拟化"; then
                    echo -e "${green}本机符合开设kvm小鸡的要求${re}"
                    read -p $'\033[1;35m确定要开设kvm小鸡吗？ [y/n]: \033[0m' confirm
                    sleep 1
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                        echo ""
                        echo ""
                        echo ""
                        echo -e "${yellow}开设虚拟内存(Swap),请先输入2移除原来的配置，会自动重新执行一次，再输入1添加虚拟内存${re}"
                        curl -L https://raw.githubusercontent.com/spiritLHLS/addswap/main/addswap.sh -o addswap.sh && chmod +x addswap.sh && bash addswap.sh
                        sleep 1
                        curl -L https://raw.githubusercontent.com/spiritLHLS/addswap/main/addswap.sh -o addswap.sh && chmod +x addswap.sh && bash addswap.sh
                        echo -e "${yellow}开始进行PVE主体安装${re}"
                        curl -L https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
                        sleep 1
                        echo -e "${yellow}请等待20秒后重启后运行第2步${re}"
                        read -p $'\033[1;96m需要立即重启吗？ [y/n]: \033[0m' confirm
                        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                            sleep 1
                            reboot
                        else 
                            break_end
                        fi
                    else
                        echo -e "${yellow}已取消操作...${re}"
                        sleep 2
                        main_menu
                    fi

                elif echo "$output" | grep -q "宿主机的环境无apt包管理器命令，请检查系统"; then
                    echo ""
                    echo -e "${red}你的vps系统暂不支持，请更换Debian12或Ubuntu22.04后重试${re}"
                    sleep 3
                    main_menu
                else 
                    echo -e "${red}暂不能判定你的服务器状态，无法开设kvm小鸡，可以考虑使用LXC模式开小鸡，正在退出...${re}"
                    rm -rf /root/check_kernal.sh
                    sleep 3
                    main_menu
                fi
            ;;

            2)
                clear

                read -p $'\033[1;96m确认你已执行完第1步，是否继续 [y/n]: \033[0m' confirm
                if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then

                    sleep 1
                    curl -L https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
                    sleep 1
                    echo -e "${yellow}开始配置环境...${re}"
                    bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/build_backend.sh)
                    sleep 1
                    echo -e "${yellow}开始自动配置宿主机的网关...${re}"
                    bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/build_nat_network.sh)
                    sleep 1
                    echo -e "${yellow}KVM虚拟化开设出的虚拟机，默认生成的用户名不是root，请确保你已在root下运行及修改root密码${re}"

                    while true; do
                        read -p $'\033[1;96m你需要手动开设kvm小鸡还是批量开设kvm小鸡？(1：手动开设  2：自动批量开设) \033[0m' choose

                        if [ "$choose" == "1" ]; then
                            sleep 1
                            curl -L https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/buildvm.sh -o buildvm.sh && chmod +x buildvm.sh
                            sleep 2
                            echo -e "${purple}手动开设请执行以下命令，参数对照如下可自行修改${re}"
                            echo ""
                            echo -e "${purple}./buildvm.sh VMID 用户名 密码 CPU核数 内存 硬盘 SSH端口 80端口 443端口 外网端口起 外网端口止 系统 存储盘 独立IPV6地址(留空默认N)${re}"
                            echo -e "${purple}./buildvm.sh 102 test1 oneclick123 1 512 10 40001 40002 40003 50000 50025 debian11 local N${re}"
                            sleep 3
                            break_end
                            break  # 跳出循环
                        elif [ "$choose" == "2" ]; then
                            sleep 1
                            echo -e "${red}注意: KVM开设出的NAT小鸡，默认生成的用户名不是root，默认的root密码部分类型是${green}password${red},需要sudo -i手动切换为root${re}"
                            sleep 2
                            curl -L https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/create_vm.sh -o create_vm.sh && chmod +x create_vm.sh && bash create_vm.sh
                            sleep 2
                            break_end
                            break  # 跳出循环
                        else
                            echo -e "${red}输入错误，请输入1或2${re}"
                        fi
                    done
                else 
                    break_end
                fi
            ;;

            3)
                clear
                for vmid in $(qm list | awk '{if(NR>1) print $1}'); do qm stop $vmid; qm destroy $vmid; rm -rf /var/lib/vz/images/$vmid*; done
                iptables -t nat -F
                iptables -t filter -F
                service networking restart
                systemctl restart networking.service
                systemctl restart ndpresponder.service
                iptables-save | awk '{if($1=="COMMIT"){delete x}}$1=="-A"?!x[$0]++:1' | iptables-restore
                iptables-save > /etc/iptables/rules.v4
                rm -rf vmlog
                rm -rf vm*
                sleep 2
                break_end
            ;;

            4)
                clear
                echo -e "${yellow}开始进行环境检测...${re}"
                install wget 

                output=$(bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/oneclickvirt/lxd/main/scripts/pre_check.sh))
                echo "$output"
                if echo "$output" | grep -q "本机符合作为LXC母鸡的要求，可以批量开设LXC容器"; then
                    echo ""
                    echo -e "${green}你的vps已通过检测，可以开设LXC小鸡${re}"

                    read -p $'\033[1;35m确定要开设LXC小鸡吗？ [y/n]: \033[0m' confirm

                        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then

                            echo -e "${yellow}开始进行安装LXD主体...${re}"
                            sleep 1
                            curl -L https://raw.githubusercontent.com/oneclickvirt/lxd/main/scripts/lxdinstall.sh -o lxdinstall.sh && chmod +x lxdinstall.sh && bash lxdinstall.sh
                            sleep 3
                            # 检查LXD是否安装成功
                            check_lxc(){
                                if command lxc -h &> /dev/null; then
                                    echo -e "${green}LXD主体已安装完成${re}"
                                    # lxc --version 2>/dev/null
                                    sleep 1
                                    return 0
                                else
                                    echo -e "${yellow}lxc没有软连接上，正在为你修复...${re}"
                                    apt update -y
                                    ! lxc -h >/dev/null 2>&1 && echo 'alias lxc="/snap/bin/lxc"' >> /root/.bashrc && source /root/.bashrc
                                    export PATH=$PATH:/snap/bin

                                    if command lxc -h &> /dev/null; then
                                        sleep 1
                                        return 0
                                    else
                                        echo -e "${yellow}lxc没有软连接上，请重启系统后重新运行${re}"
                                        sleep 2
                                        main_menu
                                    fi
                                fi
                            }
                            check_lxc
                            while true; do
                                clear
                                echo ""
                                echo -e "${yellow}温馨提醒:如果你开设的小鸡数量较多建议reboot重启一次系统使配置生效，再进入管理LXC小鸡菜单${purple}新增即可${re}"
                                echo ""
                                read -p $'\033[1;35m选择哪种方式开设LXC小鸡？\n1:普通批量生成(256RAM+1G+上下行限制300Mb)  \n2:自定义配置批量生成  \n3:取消开小鸡 \n4:重启系统 \n请选择： \033[0m' confirm

                                case $confirm in
                                    1)
                                        echo -e "${green}开始运行普通版本批量生成小鸡${yellow}(1核256MB内存1GB硬盘限速300Mbit)${re}"
                                        sleep 1
                                        install screen wget sudo dos2unix jq
                                        curl -L https://raw.githubusercontent.com/oneclickvirt/lxd/main/scripts/init.sh -o init.sh && chmod +x init.sh && dos2unix init.sh
                                        
                                        read -p $'\033[1;35m请输入你要生成小鸡的数量：\033[0m' number
                                        sleep 1
                                        install screen
                                        echo -e "${green}正在后台自动为你开设小鸡中，可关闭SSH，完成后运行cat log查看信息${re}"
                                        sleep 3
                                        screen bash init.sh lxc $number 
                                        sleep 3
                                        cat log
                                        break
                                        ;;
                                    2)
                                        echo -e "${green}开始运行自定义批量生成小鸡(自定义配置)${re}"
                                        sleep 1
                                        install screen wget sudo dos2unix jq
                                        echo -e "${green}输入配置后，自动进入后台生成小鸡(可直接关闭SSH连接，完成后运行cat log查看小鸡信息)${re}"
                                        sleep 3
                                        curl -L https://github.com/oneclickvirt/lxd/raw/main/scripts/add_more.sh -o add_more.sh && chmod +x add_more.sh && screen bash add_more.sh
                                        cat log
                                        break
                                        ;;
                                    3)
                                        echo -e "${yellow}你已取消了开设小鸡的操作${re}"
                                        exit 0
                                        ;;
                                    4)
                                        reboot
                                        ;;
                                    *)
                                        echo -e "${red}输入错误，请输入1~4${re}"
                                        ;;
                                esac
                            done

                        else
                            echo -e "${yellow}取消开设LXC小鸡，正在退出...${re}"
                            sleep 2
                            main_menu
                            
                        fi                        
                else
                    echo -e "${red}你的vps不符合开设LXC母鸡要求，请选择incus或Docker方式开设小鸡${re}"
                    sleep 3
                    main_menu
                fi
            ;;


            5)
                clear
                install wget
                wget -N --no-check-certificate https://raw.githubusercontent.com/eooce/lxdpro/main/lxdpro.sh && chmod +x lxdpro.sh && bash lxdpro.sh

                break_end
            
            ;;                   

            6)
              while true; do
                clear
                echo -e "${purple}▶ 管理LXC小鸡${re}"
                echo "------------------------"
                echo -e "${skyblue}1. 查看所有LXC小鸡${re}"
                echo "------------------------"
                echo -e "${skyblue}2. 暂停所有LXC小鸡${re}"
                echo -e "${skyblue}3. 启动所有LXC小鸡${re}"
                echo "------------------------"
                echo -e "${skyblue}4. 暂停指定LXC小鸡${re}"
                echo -e "${skyblue}5. 启动指定LXC小鸡${re}"
                echo -e "${skyblue}6. 给指定小鸡重装系统${re}"
                echo "------------------------"
                echo -e "${skyblue}7. 新增开设LXC小鸡${re}"
                echo -e "${red}8. 删除指定LXC小鸡${re}" 
                echo -e "${red}9. 删除所有LXC小鸡和配置${re}" 
                echo "------------------------"
                echo -e "${white}0. 返回上一级菜单${re}"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                case $sub_choice in
                    1)
                        clear
                        echo -e "${green}所有LXC小鸡运行状态：${re}"
                        lxc list
                        echo -e "${green}所有LXC小鸡密码端口信息${re}"
                        cat log
                        break_end
                    ;;

                    2)
                        clear
                        lxc stop --all
                        break_end
                    ;;

                    3)
                        clear
                        lxc start --all
                        break_end
                    ;;

                    4)
                        clear
                        read -p $'\033[1;35m请输入要暂停的小鸡的名字（如ex1，nat1等）：\033[0m' nat
                        lxc stop $nat
                        info_output=$(lxc info $nat)

                        # 检查指定暂停的小鸡状态
                        if echo "$info_output" | grep -q "Status: STOPPED"; then
                            echo -e "${green}已暂停${nat}小鸡${re}"
                            sleep 2
                            break_end
                        elif echo "$info_output" | grep -q "Status: RUNNING"; then
                            echo -e "${yellow}${nat}仍在运行，请重试${re}"
                            sleep 2
                        else
                            echo -e "${red}未知${nat}状态${re}"
                            sleep 2
                        fi
                    ;;

                    5)
                        clear
                        read -p $'\033[1;35m请输入要启动的小鸡的名字（如ex1，nat1等）: \033[0m' nat
                        lxc start $nat
                        info_output=$(lxc info ${nat})

                        # 检查指定启动的小鸡状态
                        if echo "$info_output" | grep -q "Status: RUNNING"; then
                            echo -e "${green}启动成功${nat}小鸡${re}"
                            sleep 2
                            break_end
                        elif echo "$info_output" | grep -q "Status: STOPPED"; then
                            echo -e "${yellow}${nat}暂停状态，请重新启动${re}"
                            sleep 2
                        else
                            echo -e "${red}未知${nat}状态${re}"
                            sleep 2
                        fi

                    ;;

                    6)
                        clear
                        read -p $'\033[1;35m请输入要重装系统的小鸡的名字（如ex1，nat1等）: \033[0m' nat
                        lxc stop $nat && lxc rebuild images:debian/11 $nat
                        sleep 2
                        lxc start $nat
                        echo -e "${green}${nat}小鸡已重装系统完成${re}"
                        sleep 2
                        break_end
                    ;;

                    7)
                        read -p $'\033[1;35m确定要新增LXC小鸡吗？ [y/n]: \033[0m' confirm

                        if [[ "$confirm" =~ ^[Yy]$ ]]; then   
                            echo -e "${green}输入配置后将进入后台为你新增，可关闭SSH，完成后cat log查看信息${re}"
                            install screen wget sudo dos2unix jq
                            curl -L https://github.com/oneclickvirt/lxd/raw/main/scripts/add_more.sh -o add_more.sh && chmod +x add_more.sh && screen bash add_more.sh

                        else 
                            echo -e "${green}已取消${re}"
                            break_end
                        fi
                    ;;

                    8)
                        clear
                        read -p $'\033[1;35m请输入要删除的小鸡的名字（如ex1，nat1等）: \033[0m' nat
                        lxc delete -f $nat
                        sleep 2
                        echo -e "${green}${nat}小鸡已删除${re}"
                        sleep 2
                        break_end
                    ;;

                    9)
                        clear
                        read -p $'\033[1;35m删除后无法恢复，确定要继续删除所有Lxc小鸡吗 [y/n]: \033[0m' confirm

                        if [[ "$confirm" =~ ^[Yy]$ ]]; then   
                            lxc list -c n --format csv | xargs -I {} lxc delete -f {}

                            sudo find /var/log -type f -delete
                            sudo find /var/tmp -type f -delete
                            sudo find /tmp -type f -delete
                            sudo find /var/cache/apt/archives -type f -delete

                            # 删除配置
                            rm -rf /usr/local/bin/ssh_sh.sh
                            rm -rf /usr/local/bin/config.sh
                            rm -rf /usr/local/bin/ssh_bash.sh
                            rm -rf /usr/local/bin/check-dns.sh
                            rm -rf /root/ssh_sh.sh
                            rm -rf /root/config.sh
                            rm -rf /root/ssh_bash.sh
                            rm -rf /root/buildone.sh
                            rm -rf /root/add_more.sh
                            rm -rf /root/build_ipv6_network.sh

                            echo -e "${green}已删除所有Lxc小鸡${re}"
                            break_end
                        else 
                            echo -e "${green}已取消删除${re}"
                            break_end
                        fi    
                    ;;                    
                    
                    0)
                        break
                    ;;
                    *)
                        echo -e "${red}无效选择，请重新输入。${re}"
                    ;;
                esac
              done
            ;;

            7)
                clear
                echo -e "${yellow}开设虚拟内存(Swap),请先输入2移除原来的，会重新执行一次，再输入1添加虚拟内存${re}"
                curl -L https://raw.githubusercontent.com/spiritLHLS/addswap/main/addswap.sh -o addswap.sh && chmod +x addswap.sh && bash addswap.sh
                sleep 1
                curl -L https://raw.githubusercontent.com/spiritLHLS/addswap/main/addswap.sh -o addswap.sh && chmod +x addswap.sh && bash addswap.sh
                sleep 1
                echo -e "${yellow}开始安装docker配置环境${re}"
                curl -L https://raw.githubusercontent.com/spiritLHLS/docker/main/scripts/dockerinstall.sh -o dockerinstall.sh && chmod +x dockerinstall.sh && bash dockerinstall.sh
                sleep 2

                while true; do
                    read -p $'\033[1;96m你需要单独开设Docker小鸡还是批量开设Docker小鸡？(1：单个开设  2：批量开设 3：重启系统) \033[0m' choose

                    if [ "$choose" == "1" ]; then
                        sleep 1
                        install screen
                        curl -L https://raw.githubusercontent.com/spiritLHLS/docker/main/scripts/onedocker.sh -o onedocker.sh && chmod +x onedocker.sh && screen bash onedocker.sh
                        sleep 2
                        break_end
                        break  # 跳出循环
                    elif [ "$choose" == "2" ]; then
                        sleep 1
                        curl -L https://raw.githubusercontent.com/spiritLHLS/docker/main/scripts/create_docker.sh -o create_docker.sh && chmod +x create_docker.sh && screen bash create_docker.sh
                        sleep 2
                        break_end
                        break  # 跳出循环
                    elif  [ "$choose" == "3" ]; then
                        reboot
                    else
                        echo -e "${red}输入错误，请输入1或2${re}"
                    fi
                done
            ;;

            8)
                clear
                docker ps -aq --format '{{.Names}}' | grep -E '^ndpresponder' | xargs -r docker rm -f
                docker images -aq --format '{{.Repository}}:{{.Tag}}' | grep -E '^ndpresponder' | xargs -r docker rmi
                rm -rf dclog
                ls

                sleep 2
                break_end
            ;;

            9)
                clear
                echo -e "${yellow}开始进行环境检测...${re}"
                install wget 

                output=$(bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/oneclickvirt/incus/main/scripts/pre_check.sh))
                echo "$output"
                if echo "$output" | grep -q "本机符合作为incus母鸡的要求，可以批量开设incus容器"; then

                    echo -e "${green}你的vps符合开设incus要求，可以开设incus小鸡${re}"

                    read -p $'\033[1;35m确定要开设incus小鸡吗？ [y/n]: \033[0m' confirm

                        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then

                            # 固定 dns，防止修改导致失败开小鸡失败
                            systemctl disable systemd-resolved --now > /dev/null 2>&1
                            rm -rf /etc/resolv.conf > /dev/null 2>&1
                            cat >/etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
nameserver 2606:4700:4700::1111
nameserver 2001:4860:4860::8888
EOF
                            chattr +i /etc/resolv.conf > /dev/null 2>&1
                            
                            echo -e "${yellow}开始进行安装incus主体...${re}"
                            sleep 1
                            curl -L https://raw.githubusercontent.com/oneclickvirt/incus/main/scripts/incus_install.sh -o incus_install.sh && chmod +x incus_install.sh && bash incus_install.sh
                            sleep 2
                            # 检查incus是否安装成功
                            check_incus(){
                                if which incus >/dev/null; then
                                    echo -e "${green}Incus主体已安装完成${re}"
                                    # incus --version 2>/dev/null
                                    sleep 1
                                    return 0
                                
                                else
                                    echo "Incus主体已安装失败，请更新系统后重试，正在清理缓存..."
                                    rm -rf /root/incus_install.sh
                                    sleep 2
                                    main_menu

                                fi
                            }

                            while true; do
                                clear
                                echo ""
                                echo -e "${yellow}温馨提醒:如果你开设的小鸡数量较多建议reboot重启一次系统使配置生效，再进入管理incus小鸡菜单${purple}新增即可${re}"
                                echo ""
                                read -p $'\033[1;35m选择哪种方式开设incus小鸡？\n1:普通批量生成(256RAM+1G+上下行300Mb)  \n2:自定义配置批量生成  \n3:取消开小鸡 \n4:重启系统 \n请选择： \033[0m' confirm

                                case $confirm in
                                    1)
                                        echo -e "${green}开始运行普通版本批量生成小鸡${yellow}(1核256MB内存1GB硬盘限速300Mbit)${re}"
                                        sleep 1
                                        curl -L https://raw.githubusercontent.com/oneclickvirt/incus/main/scripts/init.sh -o init.sh && chmod +x init.sh && dos2unix init.sh
                                        
                                        read -p $'\033[1;35m请输入你要生成小鸡的数量：\033[0m' number
                                        sleep 1
                                        install screen
                                        echo -e "${green}正在后台自动为你开设小鸡中，可关闭SSH，完成后运行cat log查看小鸡信息${re}"
                                        sleep 3
                                        screen bash init.sh nat $number 
                                        sleep 3
                                        cat log
                                        break
                                        ;;
                                    2)
                                        echo -e "${green}开始运行自定义批量生成小鸡${re}"
                                        sleep 1
                                        install screen curl wget sudo dos2unix jq > /dev/null 2>&1
                                        echo -e "${green}正在后台自动为你开设小鸡中，可关闭SSH，完成后运行cat log查看小鸡信息${re}"
                                        sleep 3
                                        curl -L https://github.com/oneclickvirt/incus/raw/main/scripts/add_more.sh -o add_more.sh && chmod +x add_more.sh && screen bash add_more.sh
                                        cat log
                                        break
                                        ;;
                                    3)
                                        echo -e "${green}你已取消了开设小鸡的操作${re}"
                                        exit 0
                                        ;;
                                    4)
                                        reboot
                                        ;;
                                    *)
                                        echo -e "${red}输入错误，请输入 1至4的数字${re}"
                                        ;;
                                esac
                            done

                        else
                            echo -e "${yellow}取消开设incus小鸡，正在退出...${re}"
                            sleep 2
                            main_menu
                            
                        fi
                else
                    echo ""
                    echo -e "${red}你的vps不符合开设incus要求，请选择LXD或Docker方式开设小鸡${re}"
                    sleep 2
                    break_end
                fi
            ;;

            10)
              while true; do
                clear
                echo -e "${purple}▶ 管理incus小鸡${re}"
                echo "------------------------"
                echo -e "${skyblue}1. 查看所有incus小鸡运行状态${re}"
                echo "------------------------"
                echo -e "${skyblue}2. 暂停所有incus小鸡${re}"
                echo -e "${skyblue}3. 启动所有incus小鸡${re}"
                echo "------------------------"
                echo -e "${skyblue}4. 暂停指定incus小鸡${re}"
                echo -e "${skyblue}5. 启动指定incus小鸡${re}"
                echo -e "${skyblue}6. 给指定小鸡重装系统${re}"
                echo "------------------------"
                echo -e "${skyblue}7. 新增开设incus小鸡${re}"
                echo -e "${red}8. 删除指定incus小鸡${re}"
                echo -e "${red}9. 删除所有incus小鸡和配置${re}" 
                echo "------------------------"
                echo -e "${white}0. 返回上一级菜单${re}"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                case $sub_choice in
                    1)
                        clear
                        echo -e "${green}所有incus小鸡运行状态：${re}"
                        incus list
                        echo -e "${green}所有incus小鸡密码端口信息${re}"
                        cat log
                        break_end
                    ;;

                    2)
                        clear
                        incus stop --all
                        break_end
                    ;;

                    3)
                        clear
                        incus start --all
                        break_end
                    ;;

                    4)
                        clear
                        read -p $'\033[1;35m请输入要暂停的小鸡的名字（如ex1，nat1等）：\033[0m' nat
                        incus stop $nat
                        info_output=$(incus info $nat)

                        # 检查指定暂停的小鸡状态
                        if echo "$info_output" | grep -q "Status: STOPPED"; then
                            echo -e "${green}已暂停${nat}小鸡${re}"
                            sleep 2
                            break_end
                        elif echo "$info_output" | grep -q "Status: RUNNING"; then
                            echo -e "${yellow}${nat}仍在运行，请重试${re}"
                            sleep 2
                        else
                            echo -e "${red}未知${nat}状态${re}"
                            sleep 2
                        fi
                    ;;

                    5)
                        clear
                        read -p $'\033[1;35m请输入要启动的小鸡的名字（如ex1，nat1等）: \033[0m' nat
                        incus start $nat
                        info_output=$(incus info ${nat})

                        # 检查指定启动的小鸡状态
                        if echo "$info_output" | grep -q "Status: RUNNING"; then
                            echo -e "${green}启动成功${nat}小鸡${re}"
                            sleep 2
                            break_end
                        elif echo "$info_output" | grep -q "Status: STOPPED"; then
                            echo -e "${yellow}${nat}暂停状态，请重新启动${re}"
                            sleep 2
                        else
                            echo -e "${red}未知${nat}状态${re}"
                            sleep 2
                        fi

                    ;;

                    6)
                        clear
                        read -p $'\033[1;35m请输入要重装系统的小鸡的名字（如ex1，nat1等）: \033[0m' nat
                        incus stop $nat && incus rebuild images:debian/11 $nat
                        sleep 2
                        incus start $nat
                        echo -e "${green}${nat}小鸡已重装系统完成${re}"
                        sleep 2
                        break_end
                    ;;
                    7)
                        read -p $'\033[1;35m确定要新增incus小鸡吗？ [y/n]: \033[0m' confirm

                        if [[ "$confirm" =~ ^[Yy]$ ]]; then   
                            echo -e "${green}输入配置后将进入后台为你新增incus小鸡，可关闭SSH，完成后cat log查看信息${re}"
                            install screen curl wget sudo dos2unix jq > /dev/null 2>&1
                            curl -L https://github.com/oneclickvirt/incus/raw/main/scripts/add_more.sh -o add_more.sh && chmod +x add_more.sh && screen bash add_more.sh
                            cat log
                        else 
                            echo -e "${green}已取消${re}"
                            break_end
                        fi
                    ;;
                    8)
                        clear
                        read -p $'\033[1;35m请输入要删除的小鸡的名字（如ex1，nat1等）: \033[0m' nat
                        incus delete -f $nat
                        sleep 2
                        echo -e "${green}${nat}小鸡已删除${re}"
                        sleep 2
                        break_end
                    ;;

                    9)
                        clear
                        read -p $'\033[1;35m删除后无法恢复，确定要继续删除所有incus小鸡吗 [y/n]: \033[0m' confirm

                        if [[ "$confirm" =~ ^[Yy]$ ]]; then   
                            incus list -c n --format csv | xargs -I {} incus delete -f {}

                            sudo find /var/log -type f -delete
                            sudo find /var/tmp -type f -delete
                            sudo find /tmp -type f -delete
                            sudo find /var/cache/apt/archives -type f -delete

                            # 删除配置
                            rm -rf /usr/local/bin/ssh_sh.sh
                            rm -rf /usr/local/bin/config.sh
                            rm -rf /usr/local/bin/ssh_bash.sh
                            rm -rf /usr/local/bin/check-dns.sh
                            rm -rf /root/ssh_sh.sh
                            rm -rf /root/config.sh
                            rm -rf /root/ssh_bash.sh
                            rm -rf /root/buildone.sh
                            rm -rf /root/add_more.sh
                            rm -rf /root/build_ipv6_network.sh

                            echo -e "${green}已删除所有incus小鸡${re}"
                            break_end
                        else 
                            echo -e "${green}已取消删除${re}"
                            break_end
                        fi 
                    ;;

                    0)
                        break
                    ;;
                    *)
                        echo -e "${red}无效选择，请重新输入。${re}"
                    ;;
                esac
              done
            ;;

            0)
                main_menu
            ;;
        esac
    done
    ;; 

  00)
    cd ~
    curl -sS -O https://raw.githubusercontent.com/eooce/ssh_tool/main/update_log.sh && chmod +x update_log.sh && ./update_log.sh
    rm update_log.sh
    echo ""
    echo -e "${green}脚本已更新到最新版本！${re}"
    sleep 1
    main_menu
    ;;

  88)
    clear
    exit
    ;;

  *)
    echo -e "${purple}无效的输入!${re}"
    ;;
esac
    break_end
done

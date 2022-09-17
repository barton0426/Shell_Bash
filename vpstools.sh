#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: VPS Tools
#	Version: 2022.09.17_03
#	Author: ChennHaoo
#	Blog: https://github.com/Chennhaoo
#=================================================

sh_ver="2022.09.17_03"
filepath=$(cd "$(dirname "$0")"; pwd)
file=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
BBR_file="${file}/bbr.sh"
SSH_file="${file}/ssh_port.sh"
BH_file="${file}/bench.sh"
UB_file="${file}/unixbench.sh"
YB_file="${file}/yabs.sh"
LMT_file="${file}/check.sh"
SB_file="${file}/superbench.sh"
lkl_Haproxy_C_file="${file}/tcp_nanqinlang-haproxy-centos.sh"
lkl_Haproxy_D_file="${file}/tcp_nanqinlang-haproxy-debian.sh"
lkl_Rinetd_C_file="${file}/tcp_nanqinlang-rinetd-centos.sh"
lkl_Rinetd_D_file="${file}/tcp_nanqinlang-rinetd-debianorubuntu.sh"
BT_Panel="/www/server/panel"
Kern_Ver=$( uname -r )

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}
#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"	
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}

#安装常用依赖
SYS_Tools(){
	echo -e "${Info} 开始安装常用依赖...."
	echo -e "${Info} 开始更新软件源...."
	Update_SYS_Y
	if [[ ${release} == "centos" ]]; then
		echo -e "${Info} 开始安装常用软件...."
		Centos_yum
	else
		echo -e "${Info} 开始安装常用软件...."
		Debian_apt
	fi
	[[ ! -e "/usr/bin/unzip" ]] && echo -e "${Error} 依赖 unzip(解压压缩包) 安装失败，多半是软件包源的问题，请检查 !" && exit 1
	Check_python
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	echo "nameserver 1.1.1.1" >> /etc/resolv.conf
	\cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	if [[ ${release} == "centos" ]]; then
		/etc/init.d/crond restart
	else
		/etc/init.d/cron restart
	fi
	echo -e "${Info} 常用软件安装完毕...."
}
Check_python(){
	python_ver=`python -h`
	if [[ -z ${python_ver} ]]; then
		echo -e "${Info} 没有安装Python，开始安装..."
		if [[ ${release} == "centos" ]]; then
			yum install -y python
		else
			apt-get install -y python
		fi
	fi
}
Centos_yum(){
	cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
	if [[ $? = 0 ]]; then
		yum install -y vim unzip crond net-tools git nano ca-certificates curl
	else
		yum install -y vim unzip crond git nano ca-certificates curl
	fi
}
Debian_apt(){
	cat /etc/issue |grep 9\..*>/dev/null
	if [[ $? = 0 ]]; then
		apt-get install -y vim unzip cron net-tools git nano ca-certificates curl
	else
		apt-get install -y vim unzip cron git nano ca-certificates curl
	fi
}
#依赖完毕

#检查VPS虚拟状态，{if [[ ${virt} == "openvz" ]];}判断
VPS_Virt(){
	Update_SYS_Y
	if [[ ${release} == "centos" ]]; then
		virt=`virt-what`
		virt=`virt-what`
		if [[ -z ${virt} ]]; then
			yum install virt-what -y
			virt=`virt-what`
		fi
	else
		virt=`virt-what`
		if [[ -z ${virt} ]]; then
			apt-get install virt-what -y
			virt=`virt-what`
		fi
	fi
}

#修改SSH端口
Install_SSHPor(){
	[[ ${release} = "centos" ]] && echo -e "${Error} 本脚本不支持 CentOS系统 !" && exit 1
	echo "确定更改SSH端口吗 ？[y/N]" && echo
	stty erase '^H' && read -p "(默认: y):" unyn 
	if [[ ${unyn} == [Nn] ]]; then
		echo && echo -e "${Info} 已取消..." && exit 1
		else
		if [[ ! -e ${SSH_file} ]]; then
			echo -e "${Error} 没有发现 SSH修改端口脚本，开始下载..."
			cd "${file}"
			if ! wget -N --no-check-certificate https://raw.githubusercontent.com/Chennhaoo/Shell_Bash/master/ssh_port.sh; then
				echo -e "${Error} SSH 修改端口脚本下载失败 !" && exit 1
			else
				echo -e "${Info} SSH 修改端口脚本下载完成 !"
				chmod +x ssh_port.sh
			fi
		fi
	fi
	echo -e "${Info} 开始修改..."
	bash "${SSH_file}"
}

#安装BBR时进行系统判断
Configure_BBR(){	
	if [[ ${release} == "centos" ]]; then
		read -e -p "请问您的系统是否为 ${release}，正确请继续 [y/N]（默认取消）：" unyn
		[[ -z "${unyn}" ]] && echo "已取消..." && exit 1
		if [[ ${unyn} == [Nn] ]]; then
			echo && echo -e "${Info} 已取消..." && exit 1
		else
			clear
			CENTOS_BBR
		fi	
	else
		read -e -p "请问您的系统是否为 ${release}，正确请继续 [y/N]（默认取消）：" unyn
		[[ -z "${unyn}" ]] && echo "已取消..." && exit 1
		if [[ ${unyn} == [Nn] ]]; then
			echo && echo -e "${Info} 已取消..." && exit 1
		else
			clear
			DEBIAN_BBR
		fi
	fi
}

#CentOS安装BBR
CENTOS_BBR(){
echo -e "  
您的系统为 ${release}，您当前的内核版本为：${Green_font_prefix}$Kern_Ver${Font_color_suffix}，您要做什么？
	
 ${Green_font_prefix}1.${Font_color_suffix} 安装最新版内核并开启 BBR
————————
 ${Green_font_prefix}2.${Font_color_suffix} 查看 BBR 状态" && echo
echo -e "${Green_font_prefix} [安装前 请注意] ${Font_color_suffix}
1. 安装开启BBR，需要更换内核，存在更换失败等风险(重启后无法开机)，请备份重要文件
2. 本脚本仅支持 CentOS 系统更换内核，OpenVZ/Docker/LXC 不支持更换内核
3. 系统识别错误请选择取消" && echo
	stty erase '^H' && read -p "(默认: 取消):" bbr_num
	[[ -z "${bbr_num}" ]] && echo "已取消..." && exit 1
	if [[ ${bbr_num} == "1" ]]; then
		Auto_BBR
	elif [[ ${bbr_num} == "2" ]]; then
		BBR_installation_status
		bash "${BBR_file}" cntos_status
	else
		echo -e "${Error} 请输入正确的数字(1-2)" && exit 1
	fi
}

# Debian/Ubuntu安装BBR
DEBIAN_BBR(){
echo -e "  
您的系统为 ${release}，您当前的内核版本为：${Green_font_prefix}$Kern_Ver${Font_color_suffix}，您要做什么？
	
 ${Green_font_prefix}1.${Font_color_suffix} 直接开启 BBR
 ${Green_font_prefix}2.${Font_color_suffix} 安装最新版内核并开启 BBR
————————
 ${Green_font_prefix}3.${Font_color_suffix} 停止 BBR
 ${Green_font_prefix}4.${Font_color_suffix} 查看 BBR 状态" && echo
echo -e "${Green_font_prefix} [安装前 请注意] ${Font_color_suffix}
1. 若使用Debian 9、Ubuntu 18.04 等内核版本在${Green_font_prefix} 4.9.0 ${Font_color_suffix}及其之上的，可直接选择开启BBR而不需更换内核
2. 安装开启BBR，需要更换内核，存在更换失败等风险(重启后无法开机)
3. 本脚本仅支持 Debian/Ubuntu 系统更换内核，OpenVZ/Docker/LXC 不支持更换内核
4. Debian/Ubuntu 更换内核过程中会提示 [ 是否终止卸载内核 ] ，请选择 ${Green_font_prefix} NO ${Font_color_suffix}
5. 系统识别错误请选择取消" && echo
	stty erase '^H' && read -p "(默认: 取消):" bbr_num
	[[ -z "${bbr_num}" ]] && echo "已取消..." && exit 1
	if [[ ${bbr_num} == "1" ]]; then
		Start_BBR
	elif [[ ${bbr_num} == "2" ]]; then
		Auto_BBR
	elif [[ ${bbr_num} == "3" ]]; then
		Stop_BBR
	elif [[ ${bbr_num} == "4" ]]; then
		Status_BBR		
	else
		echo -e "${Error} 请输入正确的数字(1-4)" && exit 1
	fi
}

Start_BBR(){
	BBR_installation_status
	bash "${BBR_file}" start
}
Stop_BBR(){
	BBR_installation_status
	bash "${BBR_file}" stop
}
Status_BBR(){
	BBR_installation_status
	bash "${BBR_file}" status
}
#CentOS系统和其他系统直接自动升级到最新内核后自动开启
Auto_BBR(){
	VPS_Virt
	if [[ ${virt} == "openvz" ]]; then
		echo -e "${Error} BBR 不支持 OpenVZ 虚拟化(不支持更换内核) !" && exit 1
	fi
	BBR_installation_status
	bash "${BBR_file}" auto
}

BBR_installation_status(){
	if [[ -e ${BBR_file} ]]; then
		rm -rf "${BBR_file}" && echo -e "${Info} 已删除原始脚本，准备重新下载..."
	else	
		echo -e "${Error} 没有发现 BBR脚本，开始下载..."
	fi
	cd "${file}"
	if ! wget -N --no-check-certificate https://raw.githubusercontent.com/Chennhaoo/Shell_Bash/master/bbr.sh; then
		echo -e "${Error} BBR 脚本下载失败 !" && exit 1
	else
		echo -e "${Info} BBR 脚本下载完成 !"
		chmod +x bbr.sh
	fi
}

#OpenVZ BBR
Configure_BBR_OV(){
	echo -e "${Info} "
	cat /dev/net/tun
	echo -e "————————"
	echo -e "若显示${Red_font_prefix} cat: /dev/net/tun: File descriptor in bad state ${Font_color_suffix}，则表示你的VPS支持此脚本，否则请发工单开启${Red_font_prefix} TUN/TAP 支持${Font_color_suffix}
	"
	read -e -p "若VPS支持请继续 [y/N]（默认取消）：" unyn
	[[ -z "${unyn}" ]] && echo "已取消..." && exit 1
	if [[ ${unyn} == [Nn] ]]; then
		echo && echo -e "${Info} 已取消..." && exit 1
		else
		clear
		echo -e "
 ${Red_font_prefix}Lkl-haproxy ${Font_color_suffix}与${Red_font_prefix} Lkl-rinetd ${Font_color_suffix}只能二选一，两者同时安装后果自负！！
 本脚本来自于南琴浪（https://github.com/tcp-nanqinlang/wiki/wiki），使用本脚本带有一定风险，请做好数据备份！ 
————————

 ${Green_font_prefix}1.${Font_color_suffix} Lkl-Haproxy（建议）
 
 ${Green_font_prefix}2.${Font_color_suffix} Lkl-Rinetd
 
———————— 
 Lkl-Haproxy
   端口修改文件：/home/tcp_nanqinlang
   支持：单端口、端口段
   若需要修改转发端口，请将 /home/tcp_nanqinlang/haproxy.cfg 中的端口号和 /home/tcp_nanqinlang/redirect.sh 中的端口号改为你想要的端口或端口段，修改完成后重启服务器。
  
 Lkl-Rinetd
   端口修改文件：/home/tcp_nanqinlang
   支持：单端口，多个端口号用空格隔开 " && echo
		stty erase '^H' && read -p "请输入数字 (默认: 取消):" bbr_ov_num
		[[ -z "${bbr_ov_num}" ]] && echo "已取消..." && exit 1
		if [[ ${bbr_ov_num} == "1" ]]; then
			Lkl-Haproxy
		elif [[ ${bbr_ov_num} == "2" ]]; then
			Lkl-Rinetd
		else
			echo -e "${Error} 请输入正确的数字(1-2)" && exit 1
		fi	
	fi
}

#OpenVZ BBR lkl-Haproxy
Lkl-Haproxy(){
	VPS_Virt
	if [[ ${virt} == "kvm" ]]; then
		echo -e "${Error} OpenVZ BBR 不支持 KVM 虚拟化!" && exit 1
	fi
	if [[ ${release} == "centos" ]]; then
		if [[ ! -e ${lkl_Haproxy_C_file} ]]; then
			echo -e "${Error} 没有发现 Lkl-Haproxy for CentOS 脚本，开始下载..."
			cd "${file}"
			if ! wget -N --no-check-certificate https://github.com/Chennhaoo/Shell_Bash/raw/master/other/lkl-haproxy/tcp_nanqinlang-haproxy-centos.sh; then
				echo -e "${Error} Lkl-Haproxy for CentOS 脚本下载失败 !" && exit 1
			else
				echo -e "${Info} Lkl-Haproxy for CentOS 脚本下载完成 !"
				chmod +x tcp_nanqinlang-haproxy-centos.sh
			fi
		fi
		bash "${lkl_Haproxy_C_file}"
	else
		if [[ ! -e ${lkl_Haproxy_D_file} ]]; then
			echo -e "${Error} 没有发现 Lkl-Haproxy for Debian 脚本，开始下载..."
			cd "${file}"
			if ! wget -N --no-check-certificate https://github.com/Chennhaoo/Shell_Bash/raw/master/other/lkl-haproxy/tcp_nanqinlang-haproxy-debian.sh; then
				echo -e "${Error} Lkl-Haproxy for Debian 脚本下载失败 !" && exit 1
			else
				echo -e "${Info} Lkl-Haproxy for Debian 脚本下载完成 !"
				chmod +x tcp_nanqinlang-haproxy-debian.sh
			fi
		fi
		bash "${lkl_Haproxy_D_file}"
	fi
}
#OpenVZ BBR lkl-Rinetd
Lkl-Rinetd(){
	VPS_Virt
	if [[ ${virt} == "kvm" ]]; then
		echo -e "${Error} OpenVZ BBR 不支持 KVM 虚拟化!" && exit 1
	fi
	if [[ ${release} == "centos" ]]; then
		if [[ ! -e ${lkl_Rinetd_C_file} ]]; then
			echo -e "${Error} 没有发现 Lkl-Rinetd for CentOS 脚本，开始下载..."
			cd "${file}"
			if ! wget -N --no-check-certificate https://github.com/Chennhaoo/Shell_Bash/raw/master/other/lkl-rinetd/tcp_nanqinlang-rinetd-centos.sh; then
				echo -e "${Error} Lkl-Rinetd for CentOS 脚本下载失败 !" && exit 1
			else
				echo -e "${Info} Lkl-Rinetd for CentOS 脚本下载完成 !"
				chmod +x tcp_nanqinlang-rinetd-centos.sh
			fi
		fi
		bash "${lkl_Rinetd_C_file}"
	else
		if [[ ! -e ${lkl_Rinetd_D_file} ]]; then
			echo -e "${Error} 没有发现 Lkl-Rinetd for Debian 脚本，开始下载..."
			cd "${file}"
			if ! wget -N --no-check-certificate https://raw.githubusercontent.com/Chennhaoo/Shell_Bash/master/other/lkl-rinetd/tcp_nanqinlang-rinetd-debianorubuntu.sh; then
				echo -e "${Error} Lkl-Rinetd for Debian 脚本下载失败 !" && exit 1
			else
				echo -e "${Info} Lkl-Rinetd for Debian 脚本下载完成 !"
				chmod +x tcp_nanqinlang-rinetd-debianorubuntu.sh
			fi
		fi
		bash "${lkl_Rinetd_D_file}"
	fi
}


#更新系统时间
SYS_Time(){
	echo -e "${Info} 开始同步系统时间...."
	if [[ ${release} == "centos" ]]; then
		yum -y install ntp ntpdate
		tzselect
		ntpdate cn.pool.ntp.org
	else
		dpkg-reconfigure tzdata
		apt-get install ntpdate -y
		ntpdate cn.pool.ntp.org
	fi
	echo -e "${Info} 系统时间修改完毕，请使用 date 命令查看！"
}
#更新系统及软件
Update_SYS(){
	echo -e "${Info} 升级前请做好备份，如有内核升级请慎重考虑 ！"
	echo "确定要升级系统软件吗 ？[y/N]" && echo
	stty erase '^H' && read -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && echo && echo "已取消..." && exit 1
	if [[ ${unyn} == [Yy] ]]; then		
		if [[ ${release} == "centos" ]]; then
			echo -e "${Info} 开始更新软件，请手动确认是否升级 ！"
			yum clean all
			yum makecache
			yum update
		else
			echo -e "${Info} 开始更新软件源...."
			apt-get update
			echo -e "${Info} 软件源更新完毕！"
			echo -e "${Info} 开始更新软件，请手动确认是否升级 ！"
			apt-get upgrade
		fi		
		echo -e "${Info} 更新软件及系统完毕，请稍后自行重启 ！"
	fi
}

#更新软件源
Update_SYS_Y(){		
	if [[ ${release} == "centos" ]]; then
		echo -e "${Info} 清空源缓存... "
		yum clean all
		echo -e "${Info} 更新源缓存... "
		yum makecache
	elif cat /etc/issue | grep -q -E "Debian GNU/Linux 10"; then
		echo -e "${Info} 您使用的是Debian 10系统，开始更新软件源...."
		apt-get --allow-releaseinfo-change update
		apt-get update
		else
		echo -e "${Info} 您使用的是非Debian 10系统，开始更新软件源...."
		apt-get update
	fi		
	echo -e "${Info} 软件源更新完毕..."
}


#宝塔5.9面板
BT_Panel_5.9(){
	clear
	[[ -e ${BT_Panel} ]] && echo -e "${Error} 宝塔面板已安装，请访问https://www.bt.cn/btcode.html查询卸载方法" && exit 1
	echo -e "${Info} 开始安装..."
	if [[ ${release} == "centos" ]]; then
		echo "请确定您是 CentOS 系统吗?[y/N]" && echo
		stty erase '^H' && read -p "(默认: y):" unyn 
		if [[ ${unyn} == [Nn] ]]; then
			echo && echo -e "${Info} 已取消..." && exit 1
			else
			wget -O install.sh http://download.bt.cn/install/install.sh && sh install.sh
		fi
	elif [[ ${release} == "debian" ]]; then
		echo "请确定您是 Debian 系统吗？[y/N]" && echo
		stty erase '^H' && read -p "(默认: y):" unyn 
		if [[ ${unyn} == [Nn] ]]; then
			echo && echo -e "${Info} 已取消..." && exit 1
			else
			wget -O install.sh http://download.bt.cn/install/install-ubuntu.sh && bash install.sh
		fi
	elif [[ ${release} == "ubuntu" ]]; then
		echo "请确定您是 Ubuntu 系统吗?[y/N]" && echo
		stty erase '^H' && read -p "(默认: y):" unyn 
		if [[ ${unyn} == [Nn] ]]; then
			echo && echo -e "${Info} 已取消..." && exit 1
			else
			wget -O install.sh http://download.bt.cn/install/install-ubuntu.sh && sudo bash install.sh
		fi
	echo -e "${Error} 您的系统无法探测到，请访问宝塔官网安装！" && exit 1
	fi
}

#宝塔7.7修改面板
BT_Panel_7.7(){
	clear
	[[ -e ${BT_Panel} ]] && echo -e "${Error} 宝塔面板已安装，请访问https://www.bt.cn/btcode.html查询卸载方法" && exit 1
echo -e "${Green_font_prefix} [安装前 请注意] ${Font_color_suffix}
 本脚本为宝塔迷修改版，详细信息：https://www.baota.me/post-1.html
 安装时会安装3.7版本Python，存在兼容风险。修改版存在一定风险或后门，安装前请备份好重要数据
 请多关注作者网站，如有漏洞更新可通过本脚本中${Green_font_prefix} 升级到宝塔7.7面板 ${Font_color_suffix}命令更新
———————— 
 请问是否需要安装? [y/N]
	 "
	stty erase '^H' && read -p "(默认: y):" unyn 
	if [[ ${unyn} == [Nn] ]]; then
	echo && echo -e "${Info} 已取消..." && exit 1
	else
		echo -e "${Info} 开始安装..."
		if [[ ${release} == "centos" ]]; then
			echo "请确定您是 CentOS 系统吗?[y/N]" && echo
			stty erase '^H' && read -p "(默认: y):" unyn 
			if [[ ${unyn} == [Nn] ]]; then
				echo && echo -e "${Info} 已取消..." && exit 1
				else
				wget -N --no-check-certificate https://download.btpanel.cm/optimization/install_panel.sh && sh install_panel.sh
			fi
		elif [[ ${release} == "debian" ]]; then
			echo "请确定您是 Debian 系统吗？[y/N]" && echo
			stty erase '^H' && read -p "(默认: y):" unyn 
			if [[ ${unyn} == [Nn] ]]; then
				echo && echo -e "${Info} 已取消..." && exit 1
				else
				wget -N --no-check-certificate https://download.btpanel.cm/optimization/install_panel.sh && bash install_panel.sh
			fi
		elif [[ ${release} == "ubuntu" ]]; then
			echo "请确定您是 Ubuntu 系统吗?[y/N]" && echo
			stty erase '^H' && read -p "(默认: y):" unyn 
			if [[ ${unyn} == [Nn] ]]; then
				echo && echo -e "${Info} 已取消..." && exit 1
				else
				wget -N --no-check-certificate https://download.btpanel.cm/optimization/install_panel.sh && sudo bash install_panel.sh
			fi
		echo -e "${Error} 您的系统无法探测到，请访问宝塔官网安装！" && exit 1
		fi		
	fi	
}

#升级到宝塔7.7修改面板（更新）
UPDATE_BT_Panel_7.7(){
	clear
echo -e "${Green_font_prefix} [安装前 请注意] ${Font_color_suffix}
 本脚本为宝塔迷修改版，详细信息：https://www.baota.me/post-1.html
 安装时会安装3.7版本Python，存在兼容风险。修改版存在一定风险或后门，安装前请备份好重要数据
 请多关注作者网站，如有漏洞更新可通过本脚本中${Green_font_prefix} 升级到宝塔7.7面板 ${Font_color_suffix}命令更新
 本脚本仅支持${Red_font_prefix} 由低版本升级或更新7.7版本 ${Font_color_suffix}，不支持降级，降版本请访问：https://www.baota.me/post-37.html
———————— 
 请问是否需要升级? [y/N]
	 "
	stty erase '^H' && read -p "(默认: y):" unyn 
	if [[ ${unyn} == [Nn] ]]; then
	echo && echo -e "${Info} 已取消..." && exit 1
	else
		echo -e "${Info} 开始安装..."
		if [[ ${release} == "centos" ]]; then
			echo "请确定您是 CentOS 系统吗?[y/N]" && echo
			stty erase '^H' && read -p "(默认: y):" unyn 
			if [[ ${unyn} == [Nn] ]]; then
				echo && echo -e "${Info} 已取消..." && exit 1
				else
				wget -N --no-check-certificate https://download.btpanel.cm/optimization/update_panel.sh && sh update_panel.sh
			fi
		elif [[ ${release} == "debian" ]]; then
			echo "请确定您是 Debian 系统吗？[y/N]" && echo
			stty erase '^H' && read -p "(默认: y):" unyn 
			if [[ ${unyn} == [Nn] ]]; then
				echo && echo -e "${Info} 已取消..." && exit 1
				else
				wget -N --no-check-certificate https://download.btpanel.cm/optimization/update_panel.sh && bash update_panel.sh
			fi
		elif [[ ${release} == "ubuntu" ]]; then
			echo "请确定您是 Ubuntu 系统吗?[y/N]" && echo
			stty erase '^H' && read -p "(默认: y):" unyn 
			if [[ ${unyn} == [Nn] ]]; then
				echo && echo -e "${Info} 已取消..." && exit 1
				else
				wget -N --no-check-certificate https://download.btpanel.cm/optimization/update_panel.sh && sudo bash update_panel.sh
			fi
		echo -e "${Error} 您的系统无法探测到，请访问宝塔官网安装！" && exit 1
		fi		
	fi	
}

#修改当前用户密码
PASSWORD(){
echo -e "
 ${Info} 请在下方输入新的密码，密码不会显示，输入完毕后回车确认！
 如不想修改，请使用 Ctrl+C 取消！ 
———————— 
 "
passwd
}

#Bench测试
Install_BH(){
	if [[ -e ${BH_file} ]]; then
		rm -rf "${BH_file}" && echo -e "${Info} 已删除原始脚本，准备重新下载..."
	else	
		echo -e "${Error} 没有发现 Bench 测试脚本，开始下载..."
	fi
	cd "${file}"
	if ! wget -N --no-check-certificate https://raw.githubusercontent.com/teddysun/across/master/bench.sh; then
		echo -e "${Error} Bench 测试脚本下载失败 !" && exit 1
	else
		echo -e "${Info} Bench 测试脚本下载完成 !"
		chmod +x bench.sh
	fi
	bash "${BH_file}"
}


#Yabs 测试(跑分)
Install_YB(){
	if [[ -e ${YB_file} ]]; then
		rm -rf "${YB_file}" && echo -e "${Info} 已删除原始脚本，准备重新下载..."
	else	
		echo -e "${Error} 没有发现 Yabs 测试脚本，开始下载..."
	fi
	cd "${file}"
	if ! wget -N --no-check-certificate https://raw.githubusercontent.com/masonr/yet-another-bench-script/master/yabs.sh; then
		echo -e "${Error} Yabs 测试脚本下载失败 !" && exit 1
	else
		echo -e "${Info} Yabs 测试脚本下载完成 !"
		chmod +x yabs.sh
	fi
	bash "${YB_file}"
}

#SuperBench 测试(含基础信息、跑分、国际国内线路来回程)
SuperBench_FULL(){
	if [[ -e ${SB_file} ]]; then
		rm -rf "${SB_file}" && echo -e "${Info} 已删除原始脚本，准备重新下载..."
	else	
		echo -e "${Error} 没有发现 SuperBench 测试脚本，开始下载..."
	fi
	cd "${file}"
	if ! wget -N --no-check-certificate https://down.vpsaff.net/linux/speedtest/superbench.sh; then
		echo -e "${Error} SuperBench 测试脚本下载失败 !" && exit 1
	else
		echo -e "${Info} SuperBench 测试脚本下载完成 !"
		chmod +x "${SB_file}"
	fi
	bash "${SB_file}" 
}

#SuperBench 测试(仅测试基础信息、国内线路来回程)
SuperBench_CN(){
	if [[ -e ${SB_file} ]]; then
		rm -rf "${SB_file}" && echo -e "${Info} 已删除原始脚本，准备重新下载..."
	else	
		echo -e "${Error} 没有发现 SuperBench 测试脚本，开始下载..."
	fi
	cd "${file}"
	if ! wget -N --no-check-certificate https://down.vpsaff.net/linux/speedtest/superbench.sh; then
		echo -e "${Error} SuperBench 测试脚本下载失败 !" && exit 1
	else
		echo -e "${Info} SuperBench 测试脚本下载完成 !"
		chmod +x "${SB_file}"
	fi
	bash "${SB_file}" -f
}

#流媒体解锁检测
Install_LMT(){
	if [[ -e ${LMT_file} ]]; then
		rm -rf "${LMT_file}" && echo -e "${Info} 已删除原始脚本，准备重新下载..."
	else	
		echo -e "${Error} 没有发现流媒体测试脚本，开始下载..."
	fi
	cd "${file}"
	if ! wget -N --no-check-certificate https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh; then
		echo -e "${Error} 流媒体测试脚本下载失败 !" && exit 1
	else
		echo -e "${Info} 流媒体测试脚本下载完成 !"
		chmod +x check.sh
	fi
	bash "${LMT_file}"
}

#UnixBench测试
Install_UB(){
	if [[ -e ${UB_file} ]]; then
		rm -rf "${UB_file}" && echo -e "${Info} 已删除原始脚本，准备重新下载..."
	else	
		echo -e "${Error} 没有发现 UnixBench 测试脚本，开始下载..."
	fi
	cd "${file}"
	if ! wget -N --no-check-certificate https://github.com/teddysun/across/raw/master/unixbench.sh; then
		echo -e "${Error} UnixBench 测试脚本下载失败 !" && exit 1
	else
		echo -e "${Info} UnixBench 测试脚本下载完成 !"
		chmod +x unixbench.sh
	fi
	echo "确定开始 UnixBench 测试吗 ？[y/N]" && echo
	stty erase '^H' && read -p "(默认: y):" unyn 
	if [[ ${unyn} == [Nn] ]]; then
		echo && echo -e "${Info} 已取消..." && exit 1
		else
			if [[ ${release} == "centos" ]]; then
				yum install libc6-dev -y
			else
				apt-get install libc6-dev -y
			fi		
		bash "${UB_file}"
	fi
}




#显示菜单
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
echo -e " VPS工具包 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | ChennHaoo --
  
 ${Green_font_prefix} 1.${Font_color_suffix} 安装常用依赖
 ${Green_font_prefix} 2.${Font_color_suffix} 更新软件源
 ${Green_font_prefix} 3.${Font_color_suffix} 更新系统及软件（慎重）
 ${Green_font_prefix} 4.${Font_color_suffix} 修改系统时间
 ${Green_font_prefix} 5.${Font_color_suffix} 修改当前用户登录密码 
————————————
 ${Green_font_prefix} 6.${Font_color_suffix} 配置 KVM BBR
 ${Green_font_prefix} 7.${Font_color_suffix} 配置 OpenVZ BBR
 ${Green_font_prefix} 8.${Font_color_suffix} 安装宝塔5.9面板（官方版，不强制绑定）
 ${Green_font_prefix} 9.${Font_color_suffix} 安装宝塔7.7面板（修改版，不强制绑定）
 ${Green_font_prefix} 10.${Font_color_suffix} 升级到/更新 宝塔7.7面板（修改版，不强制绑定，只能由低版本升级）
 ${Green_font_prefix} 11.${Font_color_suffix} 修改 SSH端口（宝塔用户请在面板中修改）
————————————
 ${Green_font_prefix} 12.${Font_color_suffix} Bench 测试
 ${Green_font_prefix} 13.${Font_color_suffix} Yabs 测试(快速跑分)
 ${Green_font_prefix} 14.${Font_color_suffix} SuperBench 修改版测试(含基础信息、跑分、国际国内线路来回程)
 ${Green_font_prefix} 15.${Font_color_suffix} SuperBench 修改版测试(仅测试基础信息，推荐)
 ${Green_font_prefix} 16.${Font_color_suffix} 流媒体解锁检测
 ${Green_font_prefix} 17.${Font_color_suffix} UnixBench_V4 测试（时间较长）


 ${Info} 任何时候都可以通过 Ctrl+C 终止命令 !
" && echo
read -e -p " 请输入数字 [1-17]:" num
case "$num" in
	1)
	SYS_Tools
	;;
	2)
	Update_SYS_Y
	;;
	3)
	Update_SYS
	;;
	4)
	SYS_Time
	;;
	5)
	PASSWORD
	;;
	6)
	Configure_BBR
	;;
	7)
	Configure_BBR_OV
	;;
	8)
	BT_Panel_5.9
	;;
	9)
	BT_Panel_7.7
	;;
	10)
	UPDATE_BT_Panel_7.7
	;;
	11)
	Install_SSHPor
	;;	
	12)
	Install_BH
	;;
	13)
	Install_YB
	;;
	14)
	SuperBench_FULL
	;;
	15)
	SuperBench_CN
	;;
	16)
	Install_LMT
	;;
	17)
	Install_UB
	;;
	*)
	echo "请输入正确数字 [1-17]"
	;;
esac
#!/bin/bash
[[ $(id -u) != 0 ]] && echo -e "使用su命令切换到root用户再运行" && exit 1

cmd="apt-get"
if [[ $(command -v apt-get) || $(command -v yum) ]] && [[ $(command -v systemctl) ]]; then
    if [[ $(command -v yum) ]]; then
        cmd="yum"
    fi
else
    echo "不支持此系统" && exit 1
fi

install() {
    if [ -d "/root/vtProxy" ]; then
        echo -e "您已下载了vtProxy，重新运行此脚本，并选2.卸载->1.安装" && exit 1
    fi
    if screen -list | grep -q "vtProxy"; then
        echo -e "vtProxy已在运行中，请选6.停止->2.卸载->1.安装" && exit 1
    fi

    $cmd apt update -y
    $cmd apt install curl wget screen -y
    mkdir /root/vtProxy
    chmod 777 /root/vtProxy

    wget https://raw.githubusercontent.com/victorMinerProxy/vtMinerProxy/master/vtProxy -O /root/vtProxy/vtProxy
	
	
    chmod 777 /root/vtProxy/vtProxy

    start
}

uninstall() {
    read -p "是否确认删除vtProxy[yes/no]：" flag
    if [ -z $flag ]; then
        echo "输入错误" && exit 1
    else
        if [ "$flag" = "yes" -o "$flag" = "ye" -o "$flag" = "y" ]; then
            screen -X -S vtProxy quit
            rm -rf /root/vtProxy
            echo "卸载vtProxy成功"
        fi
    fi
}

update() {
    stop
	uninstall
	install
	start
}

start() {
    if screen -list | grep -q "vtProxy"; then
        echo -e "vtProxy已启动" && exit 1
    fi
    echo "正在启动..."
    screen -dmS vtProxy
    sleep 0.2s
    screen -r vtProxy -p 0 -X stuff "cd /root/vtProxy"
    screen -r vtProxy -p 0 -X stuff $'\n'
    screen -r vtProxy -p 0 -X stuff "./vtProxy"
    screen -r vtProxy -p 0 -X stuff $'\n'
    sleep 5s
    cat /root/vtProxy/config.json
    echo "已启动web后台 您可: screen -r vtProxy 查看程序输出;CTRL+A+D退出screen"
}

restart() {
    stop
    start
}

stop() {
    if screen -list | grep -q "vtProxy"; then
        screen -X -S vtProxy quit
    fi
    echo "vtProxy 已停止"
}

change_limit(){
    echo -n "当前连接数限制："
    num="n"
    if [ $(grep -c "root soft nofile" /etc/security/limits.conf) -eq '0' ]; then
        echo "root soft nofile 102400" >>/etc/security/limits.conf
        num="y"
    fi

    if [[ "$num" = "y" ]]; then
        echo "连接数限制已修改为102400,重启服务器后生效"
    else
        echo -n "当前连接数限制："
        ulimit -n
    fi
}


echo "======================================================="
echo "vinerProxy 一键工具"
echo "  1、安装(默认安装到/root/vtProxy)"
echo "  2、卸载"
echo "  3、更新"
echo "  4、启动"
echo "  5、重启"
echo "  6、停止"
echo "  7、解除连接数限制"
echo "======================================================="
read -p "$(echo -e "请选择[1-8]：")" choose
case $choose in
1)
    install
    ;;
2)
    uninstall
    ;;
3)
    update
    ;;
4)
    start
    ;;
5)
    restart
    ;;
6)
    stop
    ;;
7)
    change_limit
    ;;
*)
    echo "输入错误请重新输入！"
    ;;
esac

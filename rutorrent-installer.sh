#!/bin/bash
echo "## nwgat.ninja rutorrent installer ##"
echo ""
ip=`hostname -I`
echo "rutorrent Username"
read -e user
echo "rutorrent Password"
read -e pass

# Install packages
echo "Installing Packages"
apt-get update > /dev/null
apt-get -qq install php7.0-fpm supervisor git rtorrent curl wget ffmpeg mediainfo unrar nano unzip ufw -y > /dev/null

# supervisor configs
mkdir -p /etc/supervisor/conf.d/
mkdir -p /var/log/supervisor/

cp conf/supervisord.conf /etc/supervisor/supervisord.conf 
cp conf/caddy.conf /etc/supervisor/conf.d/
cp conf/rtorrent.conf /etc/supervisor/conf.d/

# Install caddy
echo "Installing caddy"
wget -q https://github.com/mholt/caddy/releases/download/v0.8.2/caddy_linux_amd64.tar.gz -O caddy_linux_amd64.tar.gz
tar xvf caddy_linux_amd64.tar.gz caddy >> /dev/null
install caddy /usr/bin

# setup rtorrent
useradd -m -p --disabled-password -s /bin/bash rtorrent
su -c 'mkdir $HOME/.session/ $HOME/.caddy' rtorrent
su -c 'mkdir -p $HOME/www/rtdl' rtorrent

cp conf/Caddyfile /home/rtorrent/.caddy/Caddyfile
sed -e "s/"user"/"$user"/g" /home/rtorrent/.caddy/Caddyfile -i.bkp
sed -e "s/"pass"/"$pass"/g" /home/rtorrent/.caddy/Caddyfile -i.bkp
cp conf/rtorrent.rc /home/rtorrent/.rtorrent.rc

# ruTorrent & php
echo "installing rutorrent"
git clone -q https://github.com/Novik/ruTorrent /home/rtorrent/www/rutorrent

# small fixes like starting supvisor on startup and caddy on port 80/443
sed '/exit 0/i setcap cap_net_bind_service=+ep /usr/bin/caddy' /etc/rc.local -i.bkp
sed '/exit 0/i supervisord -c /etc/supervisor/supervisord.conf' /etc/rc.local -i.bkp

# setup ufw
ufw --force enable
ufw allow 80
ufw allow 443
ufw allow 6922

# allow caddy for port 80
setcap cap_net_bind_service=+ep /usr/bin/caddy

# premisison hell
usermod -a -G www-data rtorrent
chown rtorrent:www-data /home/rtorrent 

# start services
service php7.0-fpm restart
supervisord -c /etc/supervisor/supervisord.conf

# Details
echo ""
echo "Login Details"
echo ""
sleep 5
supervisorctl status
echo ""
echo "Username: $user"
echo "Password: $pass"
echo "ip: http://$ip"

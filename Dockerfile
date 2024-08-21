FROM rockylinux:9.3.20231119
MAINTAINER Anchi Cheng <anchi.cheng@czii.org>
LABEL authors="Neil Voss, Carl Negro, Alex Noble, Anchi Cheng"

COPY startup.sh /sw/startup.sh
RUN dnf -y install epel-release && dnf -y --skip-broken install \
 wget sudo passwd rsync tar openssh-clients \
 python3 python3-pip python3-wxpython4 \
 python3-scipy python3-PyMySQL python3-requests \
 gcc-c++ mlocate nc screen \
 git mariadb mariadb-server \
 httpd php firefox \
 php-cli php-gd php-curl php-zip php-mbstring php-mysqlnd \
 tigervnc-server xterm xsetroot \
&& dbus-uuidgen > /var/lib/dbus/machine-id \
&& updatedb


RUN dnf -y groupinstall "Xfce" "base-x" \
&& rm -f /etc/systemd/system/default.target \
&& ln -sf /lib/systemd/system/graphical.target /etc/systemd/system/default.target \
&& systemctl unmask graphical.target \
&& mkdir -p /emg/data/leginon /emg/data/frames /emg/data/appion /sw/sql \
&& chmod 777 -R /emg

### MariaDB setup

### Apache setup
COPY config/sinedon.cfg config/leginon.cfg config/instruments.cfg config/pyami.cfg config/appion.cfg config/redux.cfg /etc/myami/
COPY config/vncserver.users /etc/tigetvnc/
COPY config/php.ini config/bashrc /etc/
COPY config/info.php /var/www/html/info.php
COPY sql/ /sw/sql/
EXPOSE 80 5901

### transfer myami-tutorial data
RUN git clone -b myami-tutorial https://github.com/leginon-org/leginon.git /sw/myami \
&& cp -rf /sw/myami/tutorial_data/simimages /emg \
&& mkdir /etc/init.d \
&& cp -v /sw/myami/redux/init.d/reduxd /etc/init.d/reduxd

### checkout the branch we really want to use
RUN cd /sw/myami \
&& git checkout myami-python3 \
&& cd \
&& wget https://emg.nysbc.org/redmine/attachments/download/11662/ctffind-4.1.13.tgz \
&& tar -xzvf ctffind-4.1.13.tgz -C /sw && rm ctffind-4.1.13.tgz \
&& ln -sv /sw/ctffind4/ctffind-4.1.13 /usr/bin/ctffind4 \
&& ln -s /bin/python3 /bin/python \
### Myami setup
&& chmod 444 /var/www/html/info.php \
&& ln -sv /sw/myami/myamiweb /var/www/html/myamiweb \
&& mkdir -p /etc/myami /var/cache/myami/redux/ && chmod 777 /var/cache/myami/redux/ \
&& ln -sv /sw/myami/appion/appionlib /usr/lib64/python3.9/site-packages/ \
&& ln -sv /sw/myami/redux/bin/reduxd /usr/bin/ && chmod 755 /usr/bin/reduxd \
&& for i in pyami myami_test imageviewer leginon pyscope sinedon redux; \
    do ln -sv /sw/myami/$i /usr/lib64/python3.9/site-packages/; done \
#
### Compile numextension and redux
&& cd /sw/myami/modules/numextension \
&& python ./setup.py install \
&& rm -rf /usr/local/lib64/python3.9/site-packages/numextension \
&& cd /sw/myami/redux \
&& python ./setup.py install \
#
&& useradd -d /home/leginonuser -g 100 -p 'leginon-tutorial' -s /bin/bash leginonuser && usermod -aG wheel leginonuser \
&& chmod 777 /home/leginonuser \
&& chown -R leginonuser:users /home/leginonuser /emg/data \
&& mkdir -p /home/leginonuser/.vnc /home/leginonuser/.config/fbpanel \
&& touch /home/leginonuser/.Xauthority \
&& chmod 777 /home/leginonuser/.vnc \
&& echo leginon-tutorial | vncpasswd -f > /home/leginonuser/.vnc/passwd \
&& echo "root:leginon-tutorial" | chpasswd \
&& chmod 600 /home/leginonuser/.vnc/passwd

ENV HOME /home/leginonuser
USER root
COPY config/xstartup /home/leginonuser/.vnc/xstartup
COPY config/vnc-config /home/leginonuser/.vnc/config
COPY config/fbpanel-default /home/leginonuser/.config/fbpanel/default
COPY config/config.php /sw/myami/myamiweb/config.php
RUN chown -R leginonuser:users /home/leginonuser /emg/data \
&& mkdir -p /emg/data/ \
&& chmod -R 777 /emg/ \
&& chmod 700 /home/leginonuser/.vnc/xstartup \
&& rm -rf root/.cache/ /anaconda-post.log \
&& sed -i -e '/rctv/d' /sw/myami/myamiweb/index.php \
&& updatedb

#  Last: start up and keep it running.
COPY resetdata.sh /sw/resetdata.sh
COPY startup.sh /sw/startup.sh
CMD chmod 755 /sw/startup.sh && /sw/startup.sh
CMD /sw/startup.sh

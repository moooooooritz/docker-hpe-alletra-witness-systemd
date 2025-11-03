# rockylinux systemd basis
FROM rockylinux/rockylinux:8.4

ENV container=docker
ENV WITNESS_PORT=5395

# systemd aufräumen (klassisches pattern für systemd-in-docker)
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ "$i" = systemd-tmpfiles-setup.service ] || rm -f "$i"; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*

# Pakete
RUN yum -y update && \
    yum -y install passwd net-tools psmisc mlocate epel-release openssl openssl-libs

# Witness-RPM ins Image legen (Name im Build-Kontext!)
COPY hpe-alletra-witness-*.rpm /root/

# RPM installieren
RUN yum -y install /root/hpe-alletra-witness-*.rpm && \
    systemctl enable nimble-witnessd.service

# für systemd im Container
VOLUME ["/sys/fs/cgroup"]
EXPOSE 5395

ENTRYPOINT ["/usr/sbin/init"]

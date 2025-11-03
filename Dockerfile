# Rocky Linux systemd base
FROM rockylinux/rockylinux:8.4

LABEL maintainer="HPE" \
      description="HPE Alletra Witness Docker Container" \
      version="1.0"

ENV container=docker
ENV WITNESS_PORT=5395

# Clean up systemd (classic pattern for systemd in docker)
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ "$i" = systemd-tmpfiles-setup.service ] || rm -f "$i"; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*

# Copy Witness RPM
COPY hpe-alletra-witness*.rpm /root/

# Packages and Witness RPM installation
RUN yum -y update && \
    yum -y install passwd net-tools psmisc mlocate epel-release openssl openssl-libs && \
    yum -y install /root/hpe-alletra-witness-*.rpm && \
    systemctl enable nimble-witnessd.service && \
    yum clean all && \
    rm -f /root/hpe-alletra-witness-*.rpm

# For systemd in container
VOLUME ["/sys/fs/cgroup"]
EXPOSE 5395

ENTRYPOINT ["/usr/sbin/init"]

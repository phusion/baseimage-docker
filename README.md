
    # Use phusion/baseimage as base image. To make your builds reproducible, make
    # sure you lock down to a specific version, not to `latest`!
    FROM phusion/baseimage:<VERSION>
    
    # Remove authentication rights for insecure_key.
    RUN rm -f /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys
    
    # Use baseimage-docker's init process.
    CMD ["/sbin/my_init"]
    
    # ...put other build instructions here...
    
    # Clean up APT when done.
    RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

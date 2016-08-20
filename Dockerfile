FROM r-base:latest


#ENV http_proxy='http://10.35.34.39:8080'
#ENV https_proxy='http://10.35.34.39:8080'


# Downloads URLs
ENV MS_ODBC_URL https://download.microsoft.com/download/B/C/D/BCDD264C-7517-4B7D-8159-C99FC5535680/RedHat6/msodbcsql-11.0.2270.0.tar.gz
ENV FIX_SCRIPT Microsoft--SQL-Server--ODBC-Driver-1.0-for-Linux-Fixed-Install-Scripts
ENV FIX_SCRIPT_URL https://github.com/Andrewpk/${FIX_SCRIPT}/archive/master.zip

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update && apt-get -y install aptitude wget unzip make gcc lsb-release libkrb5-3 libgssapi-krb5-2

# Download ODBC install files & scripts
RUN cd /tmp && wget -O msodbcsql.tar.gz ${MS_ODBC_URL} && wget -O odbc-fixed.zip ${FIX_SCRIPT_URL}

RUN cd /tmp && wget -O unixODBC-2.3.4.tar.gz  http://www.unixodbc.org/unixODBC-2.3.4.tar.gz

# Unzip downloaded files
RUN cd /tmp && tar -xzf ./msodbcsql.tar.gz && unzip -o ./odbc-fixed.zip && cp ./${FIX_SCRIPT}-master/* ./msodbcsql-11.0.2270.0

# Run install scripts
RUN cd /tmp/msodbcsql-11.0.2270.0 && yes YES | ./build_dm.sh --download-url=file:///tmp/unixODBC-2.3.4.tar.gz  --accept-warning --libdir=/usr/lib/x86_64-linux-gnu && ./install.sh install --accept-license --force

# Clean installation files
#RUN apt-get remove -y aptitude wget unzip make gcc && apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y -t unstable \
    sudo \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev/unstable \
    libxt-dev

# Download and install libssl 0.9.8
RUN wget --no-verbose http://security.debian.org/pool/updates/main/o/openssl/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb && \
    dpkg -i libssl0.9.8_0.9.8o-4squeeze14_amd64.deb && \
    rm -f libssl0.9.8_0.9.8o-4squeeze14_amd64.deb

# Download and install shiny server
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb

RUN R -e "install.packages(c('shiny', 'rmarkdown', 'tm', 'wordcloud', 'memoise'), repos='http://cran.rstudio.com/')"

COPY shiny-server.conf  /etc/shiny-server/shiny-server.conf
COPY /myapp/* /srv/shiny-server/

COPY odbc.ini /etc/odbc.ini

EXPOSE 80

COPY shiny-server.sh /usr/bin/shiny-server.sh
RUN chmod +x /usr/bin/shiny-server.sh
CMD ["/usr/bin/shiny-server.sh"]

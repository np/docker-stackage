FROM d.ail/arch

#ENV GHC_VERSION 7.4.2
#ENV GHC_VERSION 7.6.3
#ENV CABAL_VERSION 1.16.0.2
#ENV CABAL_VERSION 1.18.0.3

RUN pacman --noconfirm -Syu zsh vim &&\
    pacman -D --asdeps systemd-sysvcompat cronie \
                       device-mapper dhcpcd \
                       licenses logrotate netctl \
                       nano texinfo usbutils &&\
    pacman --noconfirm -Ru `pacman -Qqd` &&\
    pacman --needed --noconfirm -Syu \
      base-devel autoconf automake bison ed flex gcc gettext make \
      pkg-config git zip bash coreutils diffutils file wget \
      findutils gawk grep sed which procps-ng gzip \
      ncurses gmp zlib libedit freeglut mesa-libgl glib2 cairo pango gtk2 \
      postgresql-libs libmariadbclient devil judy glu icu llvm \
      ghc cabal-install &&\
    pacman --noconfirm -Scc &&\
    \
    chown daemon:daemon /opt

WORKDIR /opt
USER daemon
ENV HOME /opt
ENV PATH /opt/.cabal/bin:/usr/bin

# The one from ArchLinux [extra] repo is fine while this one is depending on libgmp.so.3
#RUN wget http://www.haskell.org/ghc/dist/$GHC_VERSION/ghc-$GHC_VERSION-x86_64-unknown-linux.tar.bz2 &&\
#    tar jxfv ghc-$GHC_VERSION-x86_64-unknown-linux.tar.bz2 &&\
#    cd ghc-$GHC_VERSION &&\
#    ./configure --prefix=/opt/ghc &&\
#    make install &&\
#    echo 'export PATH=/opt/ghc/bin:~/.cabal/bin:$PATH' >> ~/.bashrc

#RUN cd /tmp &&\
#    wget http://hackage.haskell.org/packages/archive/cabal-install/$CABAL_VERSION/cabal-install-$CABAL_VERSION.tar.gz &&\
#    tar zxfv cabal-install-$CABAL_VERSION.tar.gz &&\
#    cd cabal-install-$CABAL_VERSION/ &&\
#    bash bootstrap.sh

#ENV PATH /opt/ghc/bin:~/.cabal/bin:/usr/bin

# OR git clone -b my https://github.com/np/stackage .

RUN git clone -b master https://github.com/fpco/stackage
WORKDIR /opt/stackage

RUN cabal update

# NP had to trash part of js patch
RUN cd patching && ./scripts/create-tarballs.sh

RUN cabal install

RUN cabal install Cabal-1.20.0.0
ENV LC_ALL en_US.UTF-8

RUN stackage select --no-platform
  # --no-platform --use-global-db | tee np.select.log
RUN stackage check
  #                | tee np.check.log
RUN stackage build
RUN stackage test
  #                 | tee np.test.log
RUN ./create-stackage-tarball.sh

NAME          := btw-server
VERSION       := 4.16
ARCH          := noarch
OS            := el6
MEDIAFIRE_URL := http://www.mediafire.com/?y4xk0ufq42lmha2

ITERATION    := 1
DESCRIPTION  := [pschultz] Better Than Wolves is a single-player Minecraft mod that not only adds new items and blocks, but also provides incredible functionality for engineering and design while maintaining the original feel of Minecraft.
MAINTAINER   := Peter Schultz <schultz.peter@hotmail.com>

PACKAGE        := $(NAME)-$(VERSION)-$(ITERATION).$(OS).$(ARCH).rpm

INSTALL_ROOT   := inst_root
JARBALL        := $(NAME).jar
MC_JARBALL     := minecraft_server.jar
ZIPBALL        := btw-mod.zip
JARBALL_URL    := https://s3.amazonaws.com/MinecraftDownload/launcher/$(MC_JARBALL)

INST_PREFIX  := opt/$(NAME)
INIT_SCRIPT  := etc/init.d/$(NAME)
SYSCONFIG    := etc/sysconfig/$(NAME)

INIT_SCRIPT_SRC := https://github.com/pschultz/minecraft_server.init/raw/master/init.d/minecraft_server
SYSCONFIG_SRC   := https://github.com/pschultz/minecraft_server.init/raw/master/sysconfig/minecraft_server

BUILDDIR   := build
SOURCEDIR  := MINECRAFT_SERVER-JAR
CONFIGFILE := BTWConfig.txt
RUNDIR     := /var/run/$(NAME)

.PHONY: all clean distclean
.NOTPARALLEL:

all: $(PACKAGE)

$(PACKAGE): $(INSTALL_ROOT)/$(INST_PREFIX)/$(JARBALL) $(INSTALL_ROOT)/$(INIT_SCRIPT) $(INSTALL_ROOT)/$(SYSCONFIG) $(INSTALL_ROOT)/$(RUNDIR)/$(CONFIGFILE)
	fpm -s dir -t rpm -a all -n $(NAME) -p $(PACKAGE) -v $(VERSION) -C '$(INSTALL_ROOT)' \
		--iteration $(ITERATION) \
		--description '$(DESCRIPTION)' \
		--maintainer '$(MAINTAINER)' \
		--exclude '.git*' \
		--exclude '*/.git*' \
		-d jre -d mcwrapper \
		opt etc var

$(INSTALL_ROOT)/$(INST_PREFIX)/$(JARBALL): $(JARBALL) $(INSTALL_ROOT)/$(INST_PREFIX) 
	cp '$<' '$@'

$(INSTALL_ROOT)/$(INST_PREFIX):
	mkdir -p '$@'

$(INSTALL_ROOT)/$(INIT_SCRIPT):
	mkdir -p '$(dir $@)'
	wget '$(INIT_SCRIPT_SRC)' -O '$@'
	chmod +x '$@'

$(INSTALL_ROOT)/$(SYSCONFIG):
	mkdir -p '$(dir $@)'
	wget '$(SYSCONFIG_SRC)' -O - | sed \
		-e 's/MINECRAFT_MOTD=.*/MINECRAFT_MOTD="A Better Than Wolves Server"/' \
		-e 's@MINECRAFT_HOME=.*@MINECRAFT_HOME=$(RUNDIR)@' \
		-e 's@JAR=.*@JAR=/$(INST_PREFIX)/$(JARBALL)@' \
	> '$@'

$(JARBALL): $(MC_JARBALL) $(BUILDDIR)/$(SOURCEDIR)
	cp '$(MC_JARBALL)' '$@'
	jar uf '$@' -C '$(BUILDDIR)/$(SOURCEDIR)' .

$(BUILDDIR)/$(SOURCEDIR): $(BUILDDIR) $(ZIPBALL)
	unzip -q -d '$(BUILDDIR)' '$(ZIPBALL)' '$(SOURCEDIR)/*'

# Poor mans screen scraper, because mediafire doesn't provide static urls.
# Not sure if greping after some js variable is future proof though.
$(ZIPBALL):
	export ZIPBALL_URL='$(shell curl '$(MEDIAFIRE_URL)' | grep -Eo 'kNO = ".*"' | grep -Eo 'http://.*zip')'; \
		wget "$$ZIPBALL_URL" -O '$@'

$(BUILDDIR):
	mkdir -p '$@'

$(MC_JARBALL):
	wget '$(JARBALL_URL)' -O '$@'

$(INSTALL_ROOT)/$(RUNDIR)/$(CONFIGFILE): $(INSTALL_ROOT)/$(RUNDIR) $(ZIPBALL)
	unzip -q -d '$(INSTALL_ROOT)/$(RUNDIR)' $(ZIPBALL) '$(CONFIGFILE)'

$(INSTALL_ROOT)/$(RUNDIR):
	mkdir -p '$@'

clean: 
	rm -f '$(PACKAGE)'

distclean: clean
	rm -rf '$(JARBALL)' '$(ZIPBALL)' '$(MC_JARBALL)' \
	       '$(INSTALL_ROOT)/etc' '$(INSTALL_ROOT)/var' \
	       '$(INSTALL_ROOT)/$(INST_PREFIX)/$(JARBALL)' '$(BUILDDIR)'

# set the default rule
build:

# OS detection, cut at 7 chars for mingw
ifndef PLATFORM
UNAME := $(shell uname | cut -c 1-7)
ifeq ($(UNAME), Linux)
PLATFORM := LINUX
EXE_SUFFIX := .bin
endif
ifeq ($(UNAME), Darwin)
PLATFORM := MACOSX
EXE_SUFFIX := .bin
endif
ifeq ($(UNAME), MINGW32)
PLATFORM := MINGW
EXE_SUFFIX := .exe
#force gcc on mingw, because the default, cc, doesn't exist
CC=gcc
endif
endif


# initialize variables, load project settings
PROJECT_NAME := unnamed
LIBRARIES :=
C_SRC :=
OBJS :=
CFLAGS :=
LDFLAGS :=
LINUX_CFLAGS :=
LINUX_LDFLAGS :=
MACOSX_CFLAGS :=
MACOSX_LDFLAGS :=
MINGW_CFLAGS :=
MINGW_LDFLAGS :=
LUA_SRC :=
LUA_NATIVE_MODULES :=

include project.dd
TARGET_DIR := build
TARGET_EXE := $(TARGET_DIR)/$(PROJECT_NAME)$(EXE_SUFFIX)

include $(LIBRARIES:%=%/project.dd)

# now initialize other variables from the project settings

OBJS := $(C_SRC:.c=.o) $(CXX_SRC:.cpp=.o)
DEPS := $(C_SRC:.c=.P) $(CXX_SRC:.cpp=.P)
LUA_TARGETS=$(LUA_SRC:%=$(TARGET_DIR)/%)
RESOURCE_TARGETS=$(RESOURCES:%=$(TARGET_DIR)/%)

# start the actual rules
build: $(TARGET_EXE) resources $(LIBRARY_RESOURCES)
resources: $(LUA_TARGETS) $(RESOURCE_TARGETS)

$(TARGET_EXE): $(OBJS)
	@echo linking $@
	@mkdir -p `dirname $@`
	@$(CXX) -o $@ $^ $(LDFLAGS) $($(PLATFORM)_LDFLAGS)

%.o: %.c
	@echo compiling $@
	@$(CC) -MD -o $@ $< -c $(CFLAGS) $($(PLATFORM)_CFLAGS)
	@cp $*.d $*.P;
	@sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
	     -e '/^$$/ d' -e 's/$$/ :/' < $*.d >> $*.P
	@rm -f $*.d

%.o: %.cpp
	@echo compiling $@
	@$(CXX) -MD -o $@ $< -c $(CFLAGS) $($(PLATFORM)_CFLAGS)
	@cp $*.d $*.P;
	@sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
	     -e '/^$$/ d' -e 's/$$/ :/' < $*.d >> $*.P
	@rm -f $*.d

$(RESOURCE_TARGETS): $(TARGET_DIR)/%: %
	@echo copying $@...
	@mkdir -p `dirname $@`
	@cp $^ $@

# TARGET_EXE is a dependency because we need luac to be built
$(LUA_TARGETS): $(TARGET_DIR)/%: % $(TARGET_EXE)
	@echo verifying $@...
	@dokidoki/lua/src/luac -p $<
	@echo copying $@...
	@mkdir -p `dirname $@`
	@cp $< $@

clean:
	rm -f $(OBJS) $(DEPS)
	rm -rf $(TARGET_DIR)

clean-all: clean

-include $(DEPS)

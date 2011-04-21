#ifndef DOKIDOKI_LOG_H
#define DOKIDOKI_LOG_H

#include <lua.h>

void log_init(int use_logfile);
void log_message(const char *message);
void log_messagef(const char *fmt, ...);

int luaopen_log(lua_State *L);

#endif

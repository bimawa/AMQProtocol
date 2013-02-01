#ifndef librabbitmq_unix_socket_h
#define librabbitmq_unix_socket_h

//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#include <errno.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/uio.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>
#include <netinet/tcp.h>

static inline int amqp_socket_init(void)
{
	return 0;
}

extern int amqp_socket_socket(int domain, int type, int proto);

#define amqp_socket_setsockopt setsockopt
#define amqp_socket_close close
#define amqp_socket_writev writev

static inline int amqp_socket_error()
{
	return errno | ERROR_CATEGORY_OS;
}

#endif

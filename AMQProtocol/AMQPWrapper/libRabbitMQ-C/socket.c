//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#include <sys/socket.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdint.h>
#include <string.h>

#include "amqp.h"
#include "amqp_private.h"
#include "socket.h"

int amqp_socket_socket(int domain, int type, int proto)
{
	int flags;

	int s = socket(domain, type, proto);
	if (s < 0)
		return s;

	/* Always enable CLOEXEC on the socket */
	flags = fcntl(s, F_GETFD);
	if (flags == -1
	    || fcntl(s, F_SETFD, (long)(flags | FD_CLOEXEC)) == -1) {
		int e = errno;
		close(s);
		errno = e;
		return -1;
	}

	return s;
}	

char *amqp_os_error_string(int err)
{
	return strdup(strerror(err));
}

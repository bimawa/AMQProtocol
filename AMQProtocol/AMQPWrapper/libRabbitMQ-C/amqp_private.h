//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#ifndef librabbitmq_amqp_private_h
#define librabbitmq_amqp_private_h
#ifdef __cplusplus
extern "C" {
#endif

#define ERROR_CATEGORY_MASK (1 << 29)

#define ERROR_CATEGORY_CLIENT (0 << 29) /* librabbitmq error codes */
#define ERROR_CATEGORY_OS (1 << 29) /* OS-specific error codes */


#define ERROR_NO_MEMORY 1
#define ERROR_BAD_AMQP_DATA 2
#define ERROR_UNKNOWN_CLASS 3
#define ERROR_UNKNOWN_METHOD 4
#define ERROR_GETHOSTBYNAME_FAILED 5
#define ERROR_INCOMPATIBLE_AMQP_VERSION 6
#define ERROR_CONNECTION_CLOSED 7
#define ERROR_MAX 7

extern char *amqp_os_error_string(int err);

typedef enum amqp_connection_state_enum_ {
  CONNECTION_STATE_IDLE = 0,
  CONNECTION_STATE_WAITING_FOR_HEADER,
  CONNECTION_STATE_WAITING_FOR_BODY,
  CONNECTION_STATE_WAITING_FOR_PROTOCOL_HEADER
} amqp_connection_state_enum;

/* 7 bytes up front, then payload, then 1 byte footer */
#define HEADER_SIZE 7
#define FOOTER_SIZE 1

typedef struct amqp_link_t_ {
  struct amqp_link_t_ *next;
  void *data;
} amqp_link_t;

struct amqp_connection_state_t_ {
  amqp_pool_t frame_pool;
  amqp_pool_t decoding_pool;

  amqp_connection_state_enum state;

  int channel_max;
  int frame_max;
  int heartbeat;
  amqp_bytes_t inbound_buffer;

  size_t inbound_offset;
  size_t target_size;

  amqp_bytes_t outbound_buffer;

  int sockfd;
  amqp_bytes_t sock_inbound_buffer;
  size_t sock_inbound_offset;
  size_t sock_inbound_limit;

  amqp_link_t *first_queued_frame;
  amqp_link_t *last_queued_frame;

  amqp_rpc_reply_t most_recent_api_result;
};

#define CHECK_LIMIT(b, o, l, v) ({ if ((o + l) > (b).len) { return -ERROR_BAD_AMQP_DATA; } (v); })
#define BUF_AT(b, o) (&(((uint8_t *) (b).bytes)[o]))

#define D_8(b, o) CHECK_LIMIT(b, o, 1, * (uint8_t *) BUF_AT(b, o))
#define D_16(b, o) CHECK_LIMIT(b, o, 2, ({uint16_t v; memcpy(&v, BUF_AT(b, o), 2); ntohs(v);}))
#define D_32(b, o) CHECK_LIMIT(b, o, 4, ({uint32_t v; memcpy(&v, BUF_AT(b, o), 4); ntohl(v);}))
#define D_64(b, o) ({				\
  uint64_t hi = D_32(b, o);			\
  uint64_t lo = D_32(b, o + 4);			\
  hi << 32 | lo;				\
})

#define D_BYTES(b, o, l) CHECK_LIMIT(b, o, l, BUF_AT(b, o))

#define E_8(b, o, v) CHECK_LIMIT(b, o, 1, * (uint8_t *) BUF_AT(b, o) = (v))
#define E_16(b, o, v) CHECK_LIMIT(b, o, 2, ({uint16_t vv = htons(v); memcpy(BUF_AT(b, o), &vv, 2);}))
#define E_32(b, o, v) CHECK_LIMIT(b, o, 4, ({uint32_t vv = htonl(v); memcpy(BUF_AT(b, o), &vv, 4);}))
#define E_64(b, o, v) ({					\
      E_32(b, o, (uint32_t) (((uint64_t) v) >> 32));		\
      E_32(b, o + 4, (uint32_t) (((uint64_t) v) & 0xFFFFFFFF));	\
    })

#define E_BYTES(b, o, l, v) CHECK_LIMIT(b, o, l, memcpy(BUF_AT(b, o), (v), (l)))

extern int amqp_decode_table(amqp_bytes_t encoded,
			     amqp_pool_t *pool,
			     amqp_table_t *output,
			     int *offsetptr);

extern int amqp_encode_table(amqp_bytes_t encoded,
			     amqp_table_t *input,
			     int *offsetptr);

#define amqp_assert(condition, ...)		\
  ({						\
    if (!(condition)) {				\
      fprintf(stderr, __VA_ARGS__);		\
      fputc('\n', stderr);			\
      abort();					\
    }						\
  })

#define AMQP_CHECK_RESULT_CLEANUP(expr, stmts)	\
  ({						\
    int _result = (expr);			\
    if (_result < 0) { stmts; return _result; }	\
    _result;					\
  })

#define AMQP_CHECK_RESULT(expr) AMQP_CHECK_RESULT_CLEANUP(expr, )

#ifndef NDEBUG
extern void amqp_dump(void const *buffer, size_t len);
#else
#define amqp_dump(buffer, len) ((void) 0)
#endif

#ifdef __cplusplus
}
#endif

#endif

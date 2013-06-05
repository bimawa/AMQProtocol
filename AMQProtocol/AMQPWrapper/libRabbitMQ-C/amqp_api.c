//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "amqp.h"
#include "amqp_framing.h"
#include "amqp_private.h"

#include <assert.h>
#include <MacTypes.h>

static const char *client_error_strings[ERROR_MAX] = {
  "could not allocate memory", /* ERROR_NO_MEMORY */
  "received bad AMQP data", /* ERROR_BAD_AQMP_DATA */
  "unknown AMQP class id", /* ERROR_UNKOWN_CLASS */
  "unknown AMQP method id", /* ERROR_UNKOWN_METHOD */
  "unknown host", /* ERROR_GETHOSTBYNAME_FAILED */
  "incompatible AMQP version", /* ERROR_INCOMPATIBLE_AMQP_VERSION */
  "connection closed unexpectedly", /* ERROR_CONNECTION_CLOSED */
};

char *amqp_error_string(int err)
{
  const char *str;
  int category = (err & ERROR_CATEGORY_MASK);
  err = (err & ~ERROR_CATEGORY_MASK);

  switch (category) {
  case ERROR_CATEGORY_CLIENT:
    if (err < 1 || err > ERROR_MAX)
      str = "(undefined librabbitmq error)";
    else
      str = client_error_strings[err - 1];
    break;

  case ERROR_CATEGORY_OS:
    return amqp_os_error_string(err);
    
  default:
    str = "(undefined error category)";
  }

  return strdup(str);
}

#define RPC_REPLY(replytype)						\
  (state->most_recent_api_result.reply_type == AMQP_RESPONSE_NORMAL	\
   ? (replytype *) state->most_recent_api_result.reply.decoded		\
   : NULL)

amqp_channel_open_ok_t *amqp_channel_open(amqp_connection_state_t state,
					  amqp_channel_t channel)
{
  state->most_recent_api_result =
    AMQP_SIMPLE_RPC(state, channel, CHANNEL, OPEN, OPEN_OK,
		    amqp_channel_open_t,
		    AMQP_EMPTY_BYTES);
  return RPC_REPLY(amqp_channel_open_ok_t);
}

int amqp_basic_publish(amqp_connection_state_t state,
		       amqp_channel_t channel,
		       amqp_bytes_t exchange,
		       amqp_bytes_t routing_key,
		       amqp_boolean_t mandatory,
		       amqp_boolean_t immediate,
		       amqp_basic_properties_t const *properties,
		       amqp_bytes_t body)
{
  amqp_frame_t f;
  size_t body_offset;
  if (state== nil)return 0;
  size_t usable_body_payload_size = state->frame_max - (HEADER_SIZE + FOOTER_SIZE);

  amqp_basic_publish_t m =
    (amqp_basic_publish_t) {
      .exchange = exchange,
      .routing_key = routing_key,
      .mandatory = mandatory,
      .immediate = immediate
    };

  amqp_basic_properties_t default_properties;

  AMQP_CHECK_RESULT(amqp_send_method(state, channel, AMQP_BASIC_PUBLISH_METHOD, &m));

  if (properties == NULL) {
    memset(&default_properties, 0, sizeof(default_properties));
    properties = &default_properties;
  }

  f.frame_type = AMQP_FRAME_HEADER;
  f.channel = channel;
  f.payload.properties.class_id = AMQP_BASIC_CLASS;
  f.payload.properties.body_size = body.len;
  f.payload.properties.decoded = (void *) properties;
  AMQP_CHECK_RESULT(amqp_send_frame(state, &f));

  body_offset = 0;
  while (1) {
    int remaining = body.len - body_offset;
    assert(remaining >= 0);

    if (remaining == 0)
      break;

    f.frame_type = AMQP_FRAME_BODY;
    f.channel = channel;
    f.payload.body_fragment.bytes = BUF_AT(body, body_offset);
    if (remaining >= usable_body_payload_size) {
      f.payload.body_fragment.len = usable_body_payload_size;
    } else {
      f.payload.body_fragment.len = remaining;
    }

    body_offset += f.payload.body_fragment.len;
    AMQP_CHECK_RESULT(amqp_send_frame(state, &f));
  }

  return 0;
}

amqp_rpc_reply_t amqp_channel_close(amqp_connection_state_t state,
				    amqp_channel_t channel,
				    int code)
{
  char codestr[13];
  snprintf(codestr, sizeof(codestr), "%d", code);
  return AMQP_SIMPLE_RPC(state, channel, CHANNEL, CLOSE, CLOSE_OK,
			 amqp_channel_close_t,
			 code, amqp_cstring_bytes(codestr), 0, 0);
}

amqp_rpc_reply_t amqp_connection_close(amqp_connection_state_t state,
				       int code)
{
  char codestr[13];
  snprintf(codestr, sizeof(codestr), "%d", code);
  return AMQP_SIMPLE_RPC(state, 0, CONNECTION, CLOSE, CLOSE_OK,
			 amqp_connection_close_t,
			 code, amqp_cstring_bytes(codestr), 0, 0);
}

amqp_exchange_declare_ok_t *amqp_exchange_declare(amqp_connection_state_t state,
						  amqp_channel_t channel,
						  amqp_bytes_t exchange,
						  amqp_bytes_t type,
						  amqp_boolean_t passive,
						  amqp_boolean_t durable,
						  amqp_boolean_t auto_delete,
						  amqp_table_t arguments)
{
  state->most_recent_api_result =
    AMQP_SIMPLE_RPC(state, channel, EXCHANGE, DECLARE, DECLARE_OK,
		    amqp_exchange_declare_t,
		    0, exchange, type, passive, durable, auto_delete, 0, 0, arguments);
  return RPC_REPLY(amqp_exchange_declare_ok_t);
}
amqp_exchange_delete_ok_t *amqp_exchange_delete(amqp_connection_state_t state,
        amqp_channel_t channel,
        amqp_bytes_t exchange,
        amqp_boolean_t if_unused,
        amqp_boolean_t nowait)
{
    AMQP_SIMPLE_RPC(state, channel, EXCHANGE, DELETE, DELETE_OK,
            amqp_exchange_delete_t,
            0, exchange, if_unused, nowait);
    return RPC_REPLY(amqp_exchange_delete_ok_t);
}


amqp_queue_declare_ok_t *amqp_queue_declare(amqp_connection_state_t state,
					    amqp_channel_t channel,
					    amqp_bytes_t queue,
					    amqp_boolean_t passive,
					    amqp_boolean_t durable,
					    amqp_boolean_t exclusive,
					    amqp_boolean_t auto_delete,
					    amqp_table_t arguments)
{
  state->most_recent_api_result =
    AMQP_SIMPLE_RPC(state, channel, QUEUE, DECLARE, DECLARE_OK,
		    amqp_queue_declare_t,
		    0, queue, passive, durable, exclusive, auto_delete, 0, arguments);
  return RPC_REPLY(amqp_queue_declare_ok_t);
}

amqp_queue_delete_ok_t *amqp_queue_delete(amqp_connection_state_t state,
					  amqp_channel_t channel,
					  amqp_bytes_t queue,
					  amqp_boolean_t if_unused,
					  amqp_boolean_t if_empty)
{
  state->most_recent_api_result =
    AMQP_SIMPLE_RPC(state, channel, QUEUE, DELETE, DELETE_OK,
		    amqp_queue_delete_t,
		    0, queue, if_unused, if_empty, 0);
  return RPC_REPLY(amqp_queue_delete_ok_t);
}

amqp_queue_bind_ok_t *amqp_queue_bind(amqp_connection_state_t state,
				      amqp_channel_t channel,
				      amqp_bytes_t queue,
				      amqp_bytes_t exchange,
				      amqp_bytes_t routing_key,
				      amqp_table_t arguments)
{
  state->most_recent_api_result =
    AMQP_SIMPLE_RPC(state, channel, QUEUE, BIND, BIND_OK,
		    amqp_queue_bind_t,
		    0, queue, exchange, routing_key, 0, arguments);
  return RPC_REPLY(amqp_queue_bind_ok_t);
}

amqp_queue_unbind_ok_t *amqp_queue_unbind(amqp_connection_state_t state,
					  amqp_channel_t channel,
					  amqp_bytes_t queue,
					  amqp_bytes_t exchange,
					  amqp_bytes_t binding_key,
					  amqp_table_t arguments)
{
  state->most_recent_api_result =
    AMQP_SIMPLE_RPC(state, channel, QUEUE, UNBIND, UNBIND_OK,
		    amqp_queue_unbind_t,
		    0, queue, exchange, binding_key, arguments);
  return RPC_REPLY(amqp_queue_unbind_ok_t);
}

amqp_basic_consume_ok_t *amqp_basic_consume(amqp_connection_state_t state,
					    amqp_channel_t channel,
					    amqp_bytes_t queue,
					    amqp_bytes_t consumer_tag,
					    amqp_boolean_t no_local,
					    amqp_boolean_t no_ack,
					    amqp_boolean_t exclusive)
{
  state->most_recent_api_result =
    AMQP_SIMPLE_RPC(state, channel, BASIC, CONSUME, CONSUME_OK,
		    amqp_basic_consume_t,
		    0, queue, consumer_tag, no_local, no_ack, exclusive, 0);
  return RPC_REPLY(amqp_basic_consume_ok_t);
}

int amqp_basic_ack(amqp_connection_state_t state,
		   amqp_channel_t channel,
		   uint64_t delivery_tag,
		   amqp_boolean_t multiple)
{
  amqp_basic_ack_t m =
    (amqp_basic_ack_t) {
      .delivery_tag = delivery_tag,
      .multiple = multiple
    };
  AMQP_CHECK_RESULT(amqp_send_method(state, channel, AMQP_BASIC_ACK_METHOD, &m));
  return 0;
}

amqp_basic_qos_ok_t *amqp_basic_qos(amqp_connection_state_t state,
        amqp_channel_t channel,
        long size,
        short count,
        amqp_boolean_t global)
{
    state->most_recent_api_result =
            AMQP_SIMPLE_RPC(state, channel, BASIC, QOS, QOS_OK,
            amqp_basic_qos_t,
            size, count, global);
    return RPC_REPLY(amqp_queue_purge_ok_t);
}

amqp_queue_purge_ok_t *amqp_queue_purge(amqp_connection_state_t state,
					amqp_channel_t channel,
					amqp_bytes_t queue,
					amqp_boolean_t no_wait)
{
  state->most_recent_api_result =
    AMQP_SIMPLE_RPC(state, channel, QUEUE, PURGE, PURGE_OK,
		    amqp_queue_purge_t,
		    0, queue, no_wait);
  return RPC_REPLY(amqp_queue_purge_ok_t);
}

amqp_rpc_reply_t amqp_basic_get(amqp_connection_state_t state,
				amqp_channel_t channel,
				amqp_bytes_t queue,
				amqp_boolean_t no_ack)
{
  amqp_method_number_t replies[] = { AMQP_BASIC_GET_OK_METHOD,
				     AMQP_BASIC_GET_EMPTY_METHOD,
				     0 };
  state->most_recent_api_result =
    AMQP_MULTIPLE_RESPONSE_RPC(state, channel, BASIC, GET, replies,
			       amqp_basic_get_t,
			       0, queue, no_ack);
  return state->most_recent_api_result;
}

amqp_tx_select_ok_t *amqp_tx_select(amqp_connection_state_t state,
				    amqp_channel_t channel)
{
  state->most_recent_api_result =
    AMQP_SIMPLE_RPC(state, channel, TX, SELECT, SELECT_OK,
		    amqp_tx_select_t);
  return RPC_REPLY(amqp_tx_select_ok_t);
}

amqp_tx_commit_ok_t *amqp_tx_commit(amqp_connection_state_t state,
				    amqp_channel_t channel)
{
  state->most_recent_api_result =
    AMQP_SIMPLE_RPC(state, channel, TX, COMMIT, COMMIT_OK,
		    amqp_tx_commit_t);
  return RPC_REPLY(amqp_tx_commit_ok_t);
}

amqp_tx_rollback_ok_t *amqp_tx_rollback(amqp_connection_state_t state,
					amqp_channel_t channel)
{
  state->most_recent_api_result =
    AMQP_SIMPLE_RPC(state, channel, TX, ROLLBACK, ROLLBACK_OK,
		    amqp_tx_rollback_t);
  return RPC_REPLY(amqp_tx_rollback_ok_t);
}

amqp_rpc_reply_t amqp_get_rpc_reply(amqp_connection_state_t state)
{
  return state->most_recent_api_result;
}


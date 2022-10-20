#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <errno.h>
#include <systemd/sd-bus.h>
#include <pthread.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#define ERR_PRINT(fmt, ...)     fprintf(stderr, fmt, ##__VA_ARGS__)

#ifdef DEBUG
#define DBG_PRINT(fmt, ...)     fprintf(stdout, fmt, ##__VA_ARGS__)
#else
#define DBG_PRINT(fmt, ...)
#endif

#define SERIVCE_NAME		"com.gxmicro.HostInfo"
#define OBJECT_NAME		"/com/gxmicro/host_info"
#define INTERFACE_NAME		"com.gxmicro.HostInfo"

/*  */
#define METHOD_GET_INFO		"GetInfo"
#define METHOD_UPDATA_INFO	"UpdateInfo"

#define PROPERTY_DDR_TOTAL	"DDRTotal"
#define PROPERTY_DDR_UTE	"DDRUte"
#define PROPERTY_CPUT_NUM	"CPUNum"
#define PROPERTY_CPUT_UTE	"CPUUte"


#define ASPEED_ALERT		"/dev/asp-alert"        /* write(fd, "\0", 1); 触发alert */
#define ASPEED_DEV		"/dev/asp-slave"        /* read(fd, buf, sizeof(struct asp_recv_msg)) 获取host端信息 */

/* kernel space begin */
/* reserve */
#define CPU_MSG_LEN		(16 + 2)
#define DDR_MSG_LEN		(16 + 2)
#define MSG_LEN			(16 + 2)

enum cpu_msg_pos {
	POS_CPU_MSG_LEN,
	POS_CPU_NUM,
	POS_CPU_UTE,
};

#define DDR_TOTAL_LO_SHIFT	0
#define DDR_TOTAL_HI_SHIFT	8

enum ddr_msg_pos {
	POS_DDR_MSG_LEN,
	POS_DDR_TOTAL_HI,
	POS_DDR_TOTAL_LO,
	POS_DDR_TOTAL_UTE,
};

/*
 * 消息格式
 *
 * xxx_msg[0] = 后续数据长度
 * xxx_msg[1 ~ n] = 自定义数据格式payload
 */
struct asp_recv_msg {
	uint8_t cpu_msg[MSG_LEN];
	uint8_t ddr_msg[MSG_LEN];
}__attribute__((packed));

/* kernel space end */

struct host_info {
        uint16_t ddr_total;
        uint8_t ddr_ute;

        uint8_t cpu_num;
        uint8_t cpu_ute[MSG_LEN];
};


static int method_get_host_info(sd_bus_message *m, void *userdata, sd_bus_error *ret_error)
{
        struct host_info *hinfo = (struct host_info *)userdata;
        int ret = 0;
        int fd_alert;

        fd_alert = open(ASPEED_ALERT, O_RDWR);
        if (fd_alert < 0) {
                ERR_PRINT("open %s fail\n", ASPEED_ALERT);
		return fd_alert;
        }

        ret = write(fd_alert, "\0", 1);
        if (ret < 0)
		ERR_PRINT("enable smbus alert fail\n");

        close(fd_alert);

        return sd_bus_reply_method_return(m, "i", ret);
}

static inline void handle_cpu_msg(struct host_info *hinfo, struct asp_recv_msg *hmsg)
{
        int i;

        hinfo->cpu_num = hmsg->cpu_msg[POS_CPU_NUM];

        for (i = 0; i < hinfo->cpu_num; i++)
                hinfo->cpu_ute[i] = hmsg->cpu_msg[POS_CPU_UTE + i];
}

static inline void handle_ddr_msg(struct host_info *hinfo, struct asp_recv_msg *hmsg)
{
        hinfo->ddr_total = (hmsg->ddr_msg[POS_DDR_TOTAL_HI] << DDR_TOTAL_HI_SHIFT) | (hmsg->ddr_msg[POS_DDR_TOTAL_LO] << DDR_TOTAL_LO_SHIFT);
        hinfo->ddr_ute = hmsg->ddr_msg[POS_DDR_TOTAL_UTE];
}

static inline void handle_msg(struct host_info *hinfo, struct asp_recv_msg *hmsg)
{
        handle_cpu_msg(hinfo, hmsg);
        handle_ddr_msg(hinfo, hmsg);
}

static int method_update_host_info(sd_bus_message *m, void *userdata, sd_bus_error *ret_error)
{
        struct host_info *hinfo = (struct host_info *)userdata;
        struct asp_recv_msg hmsg;
        int ret = 0;
        int fd_slave;

	memset(&hmsg, 0, sizeof(struct asp_recv_msg));

        fd_slave = open(ASPEED_DEV, O_RDWR);
        if (fd_slave < 0) {
		ERR_PRINT("open %s fail\n", ASPEED_DEV);
                return fd_slave;
        }

	ret = read(fd_slave, &hmsg, sizeof(struct asp_recv_msg));
	if (ret < 0) {
		ERR_PRINT("read host information fail\n");
		goto out_update_info;
	}


#if 0
        hmsg.cpu_msg[0] = 0x02;
        hmsg.cpu_msg[1] = 0x05;
        hmsg.cpu_msg[2] = 0x2c;
        hmsg.cpu_msg[3] = 0x5a;
        hmsg.cpu_msg[4] = 0x8b;
        hmsg.cpu_msg[5] = 0xff;
        hmsg.cpu_msg[6] = 0x63;

        hmsg.ddr_msg[0] = 0x03;
        hmsg.ddr_msg[1] = 0x78;
        hmsg.ddr_msg[2] = 0x23;
        hmsg.ddr_msg[3] = 0x1a;
#endif
	handle_msg(hinfo, &hmsg);

	DBG_PRINT("call method inferface\n");

out_update_info :
	close(fd_slave);
	/* Reply with the response */
        return sd_bus_reply_method_return(m, "i", ret);
}


static int property_get_cpu_ute(sd_bus *bus, const char *path, const char *interface, const char *property,
                sd_bus_message *reply, void *userdata, sd_bus_error *error)
{
	struct host_info *hinfo = (struct host_info *)userdata;
	uint8_t *cpu_ute = hinfo->cpu_ute;
	int r;
	int i;

	r = sd_bus_message_open_container(reply, 'a', "y");
        if (r < 0)
                return r;

	for (i = 0; i < hinfo->cpu_num; i++) {
		r = sd_bus_message_append(reply, "y", *(cpu_ute + i));
                if (r < 0)
                        return r;
        }

	return sd_bus_message_close_container(reply);

}

/* The vtable of our little object, implements the net.poettering.Calculator interface */
static const sd_bus_vtable host_info_vtable[] = {
        SD_BUS_VTABLE_START(0),
        SD_BUS_METHOD(METHOD_GET_INFO, NULL, "i", method_get_host_info, SD_BUS_VTABLE_HIDDEN),
        SD_BUS_METHOD(METHOD_UPDATA_INFO, NULL, "i", method_update_host_info, SD_BUS_VTABLE_UNPRIVILEGED),
        SD_BUS_PROPERTY(PROPERTY_DDR_TOTAL, "q", NULL, offsetof(struct host_info, ddr_total), SD_BUS_VTABLE_PROPERTY_CONST),
        SD_BUS_PROPERTY(PROPERTY_DDR_UTE, "y", NULL, offsetof(struct host_info, ddr_ute), SD_BUS_VTABLE_PROPERTY_CONST),
        SD_BUS_PROPERTY(PROPERTY_CPUT_NUM, "y", NULL, offsetof(struct host_info, cpu_num), SD_BUS_VTABLE_PROPERTY_CONST),
        SD_BUS_PROPERTY(PROPERTY_CPUT_UTE, "ay", property_get_cpu_ute, 0, SD_BUS_VTABLE_PROPERTY_CONST),
        SD_BUS_VTABLE_END
};

int main(int argc, char *argv[]) {
        sd_bus_slot *slot = NULL;
        sd_bus *bus = NULL;
        int r;

        struct host_info hinfo;

        memset(&hinfo, 0, sizeof(struct host_info));

        /* Connect to the user bus this time */
#if 0   /* 虚拟机调试使用 */
        r = sd_bus_open_user(&bus);
#endif
        r = sd_bus_open_system(&bus);
        if (r < 0) {
                ERR_PRINT("Failed to connect to system bus: %s\n", strerror(-r));
                goto finish;
        }


        /* Install the object */
        r = sd_bus_add_object_vtable(bus,
                                     &slot,
                                     OBJECT_NAME,  /* object path */
                                     INTERFACE_NAME,   /* interface name */
                                     host_info_vtable,
                                     &hinfo);
        if (r < 0) {
                ERR_PRINT("Failed to issue method call: %s\n", strerror(-r));
                goto finish;
        }

        /* Take a well-known service name so that clients can find us */
        r = sd_bus_request_name(bus, SERIVCE_NAME, 0);
        if (r < 0) {
                ERR_PRINT("Failed to acquire service name: %s\n", strerror(-r));
                goto finish;
        }

        for (;;) {
                /* Process requests */
                r = sd_bus_process(bus, NULL);
                if (r < 0) {
                        ERR_PRINT("Failed to process bus: %s\n", strerror(-r));
                        goto finish;
                }
                if (r > 0) /* we processed a request, try to process another one, right-away */
                        continue;

                /* Wait for the next request to process */
                r = sd_bus_wait(bus, (uint64_t) -1);
                if (r < 0) {
                        ERR_PRINT("Failed to wait on bus: %s\n", strerror(-r));
                        goto finish;
                }
        }

finish:
        sd_bus_slot_unref(slot);
        sd_bus_unref(bus);

        return r < 0 ? EXIT_FAILURE : EXIT_SUCCESS;
}

#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <unistd.h>
#include <systemd/sd-bus.h>

#define SERIVCE_NAME		"com.gxmicro.HostInfo"
#define OBJECT_NAME		"/com/gxmicro/host_info"
#define INTERFACE_NAME		"com.gxmicro.HostInfo"
#define METHOD_GET_INFO         "GetInfo"


int main (int argc, char *argv[])
{
	sd_bus_error error = SD_BUS_ERROR_NULL;
        sd_bus_message *m = NULL;
        sd_bus *bus = NULL;
	uint32_t seconds = 0;
        const char *path;

	if (argc >= 2)
		seconds = atoi(argv[1]);

	if (seconds < 5)
		seconds = 5;

        /* Connect to the system bus */
        if (sd_bus_open_system(&bus) < 0) {
                fprintf(stderr, "Failed to connect to system bus\n");
                goto finish;
        }

        /* Issue the method call and store the respons message in m */
	while (1) {
		sd_bus_call_method(bus,
			SERIVCE_NAME,		/* service to contact */
			OBJECT_NAME,		/* object path */
			INTERFACE_NAME,   	/* interface name */
			METHOD_GET_INFO,	/* method name */
			&error,			/* object to return error in */
			&m,			/* return message on success */
			NULL);			/* input signature */

		sleep(seconds);
	}


finish:
        sd_bus_error_free(&error);
        sd_bus_message_unref(m);
        sd_bus_unref(bus);

        return 0;

}


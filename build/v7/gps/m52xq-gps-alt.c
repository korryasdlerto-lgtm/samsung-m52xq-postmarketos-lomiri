/* M52XQ (убунтутач24/003 в7, 2026-11-09): LD_PRELOAD shim for lomiri-location-serviced (gpsd::Provider).
 * lomiri-location-service 3.4.1 hands a gpsd fix on only if isfinite(fix.altitude) (provider.cpp: "GPSD could not get a
 * GPS fix."), but since gpsd 3.20 that field is "DEPRECATED, undefined" (gps.h): the altitude is in altHAE / altMSL, so no
 * position ever reached the apps (no position updates on D-Bus with a 3D fix in gpsd). After every read the deprecated field
 * is filled from altMSL (else altHAE); a 2D fix without any altitude gets 0 (the provider sets the altitude only for 3D).
 * Both entry points are wrapped: gps_read() and the C++ gpsmm::read() the provider calls. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <math.h>
#include <gps.h>
#include <libgpsmm.h>

static void fix_alt(struct gps_data_t *g)
{
	if (!g || isfinite(g->fix.altitude))
		return;
	if (isfinite(g->fix.altMSL))
		g->fix.altitude = g->fix.altMSL;
	else if (isfinite(g->fix.altHAE))
		g->fix.altitude = g->fix.altHAE;
	else if (g->fix.mode >= MODE_2D && isfinite(g->fix.latitude) && isfinite(g->fix.longitude))
		g->fix.altitude = 0.0;
}

extern "C" int gps_read(struct gps_data_t *g, char *message, int message_len)
{
	static int (*real)(struct gps_data_t *, char *, int);
	if (!real)
		real = (int (*)(struct gps_data_t *, char *, int))dlsym(RTLD_NEXT, "gps_read");
	int r = real ? real(g, message, message_len) : -1;
	if (r > 0)
		fix_alt(g);
	return r;
}

struct gps_data_t *gpsmm::read(void)
{
	typedef struct gps_data_t *(*rd_t)(gpsmm *);
	static rd_t real;
	if (!real)
		real = (rd_t)dlsym(RTLD_NEXT, "_ZN5gpsmm4readEv");
	struct gps_data_t *g = real ? real(this) : nullptr;
	fix_alt(g);
	return g;
}

/* m52xq в6: LD_PRELOAD shim for GTK4 applications under Lomiri (Mir).
 * Mir announces output scale 3 / fractional scale 2.625, but sends xdg_toplevel sizes and touch coordinates in pixels and
 * takes the surface size (viewport destination) as pixels: a GTK window then got touches only in its top-left corner.
 * The shim makes the client see scale 1 everywhere (logical unit = pixel, like the Qt applications of Lomiri):
 *  - wl_registry: the wp_fractional_scale_manager_v1 and zxdg_output_manager_v1 globals are hidden;
 *  - wl_output.scale and wl_surface.preferred_buffer_scale are reported as 1.
 * The application enlarges its UI itself. Build: gcc -O2 -fPIC -shared -o libm52xq-wl-scale1.so m52xq-wl-scale1.c -lwayland-client -ldl */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <pthread.h>
#include <wayland-client-core.h>

/* the user data of the proxy stays the application's own (GTK finds its objects through it): the original listener
 * is looked up by the proxy */
struct wrap { struct wl_proxy *proxy; void (**orig)(void); void (*impl[8])(void); struct wrap *next; };
static struct wrap *wraps;
static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
static int (*real_add_listener)(struct wl_proxy *, void (**)(void), void *);

static void (*orig_of(void *proxy, int i))(void)
{
	void (*f)(void) = NULL;
	pthread_mutex_lock(&lock);
	for (struct wrap *w = wraps; w; w = w->next)
		if (w->proxy == proxy) { f = w->orig[i]; break; }
	pthread_mutex_unlock(&lock);
	return f;
}

typedef void (*fn8)(void *, void *, void *, void *, void *, void *, void *, void *);
#define PASS(n) static void pass##n(void *d, void *p, void *b, void *c, void *e, void *f, void *g, void *h) \
	{ fn8 o = (fn8)orig_of(p, n); if (o) o(d, p, b, c, e, f, g, h); }
PASS(0) PASS(1) PASS(2) PASS(3) PASS(4) PASS(5)
static void (*passes[])(void) = { (void (*)(void))pass0, (void (*)(void))pass1, (void (*)(void))pass2,
				   (void (*)(void))pass3, (void (*)(void))pass4, (void (*)(void))pass5 };

static void reg_global(void *d, struct wl_proxy *reg, uint32_t name, const char *iface, uint32_t ver)
{
	/* zxdg_output_manager_v1: Mir reports the logical size at its own 2.625 (411x914); without it GTK takes the
	 * wl_output mode (1080x2400) as the monitor at scale 1 */
	if (!strcmp(iface, "wp_fractional_scale_manager_v1") || !strcmp(iface, "zxdg_output_manager_v1"))
		return;
	((void (*)(void *, struct wl_proxy *, uint32_t, const char *, uint32_t))orig_of(reg, 0))(d, reg, name, iface, ver);
}
static void out_scale(void *d, struct wl_proxy *o, int32_t s)	/* wl_output event 3 */
{
	((void (*)(void *, struct wl_proxy *, int32_t))orig_of(o, 3))(d, o, 1);
}
static void surf_scale(void *d, struct wl_proxy *sf, int32_t f)	/* wl_surface event 2 */
{
	void (*o)(void) = orig_of(sf, 2);
	if (o)
		((void (*)(void *, struct wl_proxy *, int32_t))o)(d, sf, 1);
}

/* only this process: the helpers it starts (postprocess.sh saving the photo, the gallery, …) must not inherit the shim
 * (it failed to load in programs without libwayland-client and they died: no photo was saved) */
__attribute__((constructor)) static void m52xq_drop_preload(void)
{
	unsetenv("LD_PRELOAD");
}

int wl_proxy_add_listener(struct wl_proxy *proxy, void (**impl)(void), void *data)
{
	if (!real_add_listener)
		real_add_listener = dlsym(RTLD_NEXT, "wl_proxy_add_listener");
	const char *cls = wl_proxy_get_class(proxy);
	int count = !strcmp(cls, "wl_registry") ? 2 : !strcmp(cls, "wl_output") ? 6 : !strcmp(cls, "wl_surface") ? 4 : 0;
	if (!count)
		return real_add_listener(proxy, impl, data);
	struct wrap *w = calloc(1, sizeof(*w));
	w->proxy = proxy;
	w->orig = impl;
	for (int i = 0; i < count; i++)
		w->impl[i] = impl[i] ? passes[i] : NULL;
	if (!strcmp(cls, "wl_registry")) w->impl[0] = (void (*)(void))reg_global;
	else if (!strcmp(cls, "wl_output")) w->impl[3] = (void (*)(void))out_scale;
	else w->impl[2] = (void (*)(void))surf_scale;
	pthread_mutex_lock(&lock);
	w->next = wraps;
	wraps = w;
	pthread_mutex_unlock(&lock);
	return real_add_listener(proxy, w->impl, data);
}

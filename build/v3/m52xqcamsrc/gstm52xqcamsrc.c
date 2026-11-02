/* M52XQ (убунтутач24/003): video source for QtMultimedia camerabin (lomiri-camera-app).
 * Qt reads QT_GSTREAMER_CAMERABIN_VIDEOSRC as a gst-launch description but splits it at '=' and ',' (its
 * "driver=element" syntax), so "libcamerasrc camera-name=..." cannot be given there and libcamerasrc opened just the
 * first libcamera camera. This bin holds a libcamerasrc whose camera comes from M52XQ_CAMERA (front / rear, read when
 * the element is created: camerabin creates a new one every time it builds its source), always as BGRx. */
#include <gst/gst.h>
#include <string.h>

#define REAR_ID "/base/soc/cci@ac4a000/i2c-bus@0/camera@2d"	/* s5kgw3, main 64 MP */
#define FRONT_ID "/base/soc/cci@ac4b000/i2c-bus@0/camera@1a"	/* imx616 */

typedef struct { GstBin parent; } M52xqCamSrc;
typedef struct { GstBinClass parent_class; } M52xqCamSrcClass;

G_DEFINE_TYPE(M52xqCamSrc, m52xq_cam_src, GST_TYPE_BIN)

static GstStaticPadTemplate src_template = GST_STATIC_PAD_TEMPLATE("src", GST_PAD_SRC, GST_PAD_ALWAYS, GST_STATIC_CAPS_ANY);

static void m52xq_cam_src_init(M52xqCamSrc *self)
{
	const char *which = g_getenv("M52XQ_CAMERA");
	GstElement *src = gst_element_factory_make("libcamerasrc", "libcamerasrc");
	if (!src) {
		g_warning("m52xqcamsrc: no libcamerasrc");
		return;
	}
	g_object_set(src, "camera-name", which && !strcmp(which, "front") ? FRONT_ID : REAR_ID, NULL);
	/* The software ISP gives the right colours only as XRGB8888 (GStreamer BGRx): for the photo sizes camerabin
	 * negotiated XBGR8888 and red / blue came out swapped (indoor light turned blue). Keep BGRx, converters after us
	 * do the rest. */
	GstElement *filter = gst_element_factory_make("capsfilter", "bgrx");
	GstCaps *caps = gst_caps_from_string("video/x-raw,format=BGRx");
	g_object_set(filter, "caps", caps, NULL);
	gst_caps_unref(caps);
	gst_bin_add_many(GST_BIN(self), src, filter, NULL);
	gst_element_link(src, filter);
	GstPad *target = gst_element_get_static_pad(filter, "src");
	GstPad *ghost = gst_ghost_pad_new_from_template("src", target, gst_static_pad_template_get(&src_template));
	gst_object_unref(target);
	gst_element_add_pad(GST_ELEMENT(self), ghost);
}

static void m52xq_cam_src_class_init(M52xqCamSrcClass *klass)
{
	GstElementClass *element_class = GST_ELEMENT_CLASS(klass);
	gst_element_class_add_static_pad_template(element_class, &src_template);
	gst_element_class_set_static_metadata(element_class, "M52XQ camera source", "Source/Video",
		"libcamerasrc with the camera from M52XQ_CAMERA (front/rear)", "m52xq");
}

static gboolean plugin_init(GstPlugin *plugin)
{
	return gst_element_register(plugin, "m52xqcamsrc", GST_RANK_NONE, m52xq_cam_src_get_type());
}

#define PACKAGE "m52xqcamsrc"
GST_PLUGIN_DEFINE(GST_VERSION_MAJOR, GST_VERSION_MINOR, m52xqcamsrc, "M52XQ camera source", plugin_init, "1.0",
	"LGPL", PACKAGE, "https://postmarketos.org")

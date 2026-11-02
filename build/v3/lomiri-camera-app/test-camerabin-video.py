import gi, sys, time
gi.require_version('Gst', '1.0'); gi.require_version('GstPbutils', '1.0')
from gi.repository import Gst, GLib, GstPbutils
Gst.init(None)
cb = Gst.ElementFactory.make('camerabin', 'cb')
src = Gst.ElementFactory.make('wrappercamerabinsrc', 'ws')
src.set_property('video-source', Gst.ElementFactory.make('m52xqcamsrc', 'm'))
cb.set_property('camera-source', src)
cb.set_property('viewfinder-sink', Gst.ElementFactory.make('fakesink', 'vf'))
prof = GstPbutils.EncodingContainerProfile.new('mp4', None, Gst.Caps.from_string('video/quicktime,variant=iso'), None)
prof.add_profile(GstPbutils.EncodingVideoProfile.new(Gst.Caps.from_string('video/x-h264'), None, None, 0))
cb.set_property('video-profile', prof)
cb.set_property('mode', 2)
cb.set_property('video-capture-caps', Gst.Caps.from_string('video/x-raw,width=1920,height=1080'))
cb.set_property('location', '/tmp/camvid.mp4')
loop = GLib.MainLoop()
def msg(bus, m):
    t = m.type
    if t == Gst.MessageType.ERROR:
        e, d = m.parse_error(); print('ERROR', m.src.get_name(), e.message, d[:300] if d else ''); loop.quit()
    elif t == Gst.MessageType.ELEMENT and m.get_structure() and 'video-done' in m.get_structure().get_name():
        print('video-done'); loop.quit()
bus = cb.get_bus(); bus.add_signal_watch(); bus.connect('message', msg)
cb.set_state(Gst.State.PLAYING)
def start():
    print('start-capture'); cb.emit('start-capture'); GLib.timeout_add_seconds(4, stop); return False
def stop():
    print('stop-capture'); cb.emit('stop-capture'); return False
GLib.timeout_add_seconds(3, start)
GLib.timeout_add_seconds(20, loop.quit)
loop.run()
cb.set_state(Gst.State.NULL)
it = cb.iterate_recurse(); 

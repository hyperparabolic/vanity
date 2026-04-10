using GtkLayerShell;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/osd.ui")]
public class Vanity.OSD : Astal.Window {
  public string monitor_connector { get; private set; }

  public VanityIdle.Inhibitor vi { get; private set; }

  public VanityYubikey.Detector yd { get; private set; }

  private uint? idle_timeout;

  private Mutex idle_mutex = Mutex();

  [GtkChild]
  private unowned Gtk.Box idle;

  [GtkChild]
  private unowned Gtk.Image idle_icon;

  [GtkChild]
  private unowned Gtk.Box yubikey;

  [GtkChild]
  private unowned Gtk.Label yubikey_subtext;

  public OSD(Gdk.Monitor monitor) {
    Object(
      application: Vanity.Application.instance,
      // uncrustify bug, being interpreted as a namespace and applying an
      // incorrect rule, disable here.
      // *INDENT-OFF*
      namespace: @"osd-$(monitor.get_connector())",
      // *INDENT-ON*
      name: @"osd-$(monitor.get_connector())",
      gdkmonitor: monitor,
      anchor: Astal.WindowAnchor.BOTTOM,
      visible: false
    );
    this.monitor_connector = monitor.get_connector();
  }

  construct {
    this.vi = VanityIdle.Inhibitor.get_default();
    this.yd = VanityYubikey.Detector.get_default();

    this.vi.bind_property("status_icon", idle_icon, "icon-name",
                          GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);
    this.vi.notify["inhibit"].connect(() => {
      idle_mutex.lock();
      if (idle_timeout != null) {
        GLib.Source.remove(idle_timeout);
      }
      idle_mutex.unlock();

      idle.visible = true;
      idle_timeout = GLib.Timeout.add_seconds_once(2, () => {
        idle.visible = false;
        idle_mutex.lock();
        idle_timeout = null;
        idle_mutex.unlock();
      });
    });

    this.yd.bind_property("subtext", yubikey_subtext, "label",
                          GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);
    this.yd.bind_property("press", yubikey, "visible", GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);

    this.idle.notify["visible"].connect(update_window);
    this.yubikey.notify["visible"].connect(update_window);
  }

  private void update_window() {
    // a little hacky, needs something better if this widget grows
    if (yubikey.visible || idle.visible) {
      this.visible = true;
    } else {
      this.visible = false;
    }
    // shrink if necessary as children are no longer visible
    this.set_default_size(-1, -1);
  }
}

using GtkLayerShell;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/osd.ui")]
public class Vanity.OSD : Astal.Window {
  public string monitor_connector { get; private set; }

  public VanityYubikey.Detector yd { get; private set; }

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
    this.yd = VanityYubikey.Detector.get_default();

    this.yd.bind_property("subtext", yubikey_subtext, "label",
                          GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);
    this.yd.bind_property("press", yubikey, "visible", GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);
    this.yd.bind_property("press", this, "visible", GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);
  }
}

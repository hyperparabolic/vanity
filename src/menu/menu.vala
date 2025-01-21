using GtkLayerShell;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu.ui")]
public class Vanity.Menu : Astal.Window {
  public AstalWp.Wp wp { get; private set; }

  public string monitor_connector { get; private set; }

  [GtkCallback]
  public void toggle_mute_source() {
    this.wp.audio.default_speaker.mute = !this.wp.audio.default_speaker.mute;
  }

  [GtkChild]
  private unowned Gtk.Adjustment source_volume;

  public Menu(Gdk.Monitor monitor, bool is_sidecar) {
    Object(
      application: Vanity.Application.instance,
      namespace: @"menu-$(monitor.get_connector())",
      name: @"menu-$(monitor.get_connector())",
      gdkmonitor: monitor,
      anchor: Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.BOTTOM
    );

    this.monitor_connector = monitor.get_connector();
    if (is_sidecar) {
      this.add_css_class ("sidecar");
    }

    present();
  }

  construct {
    this.wp = AstalWp.get_default();

    this.wp.audio.default_speaker.bind_property("volume", source_volume, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
    init_watch_active();
  }

  private void init_watch_active() {
    GLib.Timeout.add(100, () => {
      if (this.is_active == false) {
        Vanity.Application.instance.toggle_menu();
        return false;
      }
      return true;
    });
  }
}

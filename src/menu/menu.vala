using GtkLayerShell;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu.ui")]
public class Vanity.Menu : Astal.Window {
  public AstalWp.Wp wp { get; private set; }
  public VanityBrightness.Device vbs { get; private set; }

  public string monitor_connector { get; private set; }

  [GtkCallback]
  public void toggle_mute_source() {
    this.wp.audio.default_speaker.mute = !this.wp.audio.default_speaker.mute;
  }

  [GtkChild]
  private unowned Gtk.Adjustment source_volume;

  [GtkChild]
  private unowned Gtk.Scale backlight_brightness_control;

  [GtkChild]
  private unowned Gtk.Button backlight_brightness_button;

  [GtkChild]
  private unowned Gtk.Adjustment backlight_brightness;

  public Menu(Gdk.Monitor monitor, bool is_sidecar) {
    Object(
      application: Vanity.Application.instance,
      // uncrustify bug, being interpreted as a namespace and applying an
      // incorrect rule, disable here.
      // *INDENT-OFF*
      namespace: @"menu-$(monitor.get_connector())",
      // *INDENT-ON*
      name: @"menu-$(monitor.get_connector())",
      gdkmonitor: monitor,
      anchor: Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.BOTTOM
    );

    this.monitor_connector = monitor.get_connector();
    if (is_sidecar) {
      this.add_css_class("sidecar");
    }

    present();
  }

  construct {
    this.wp = AstalWp.get_default();
    this.wp.audio.default_speaker.bind_property("volume", source_volume, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);

    this.vbs = VanityBrightness.get_default_screen();
    if (vbs != null) {
      backlight_brightness.upper = this.vbs.max_brightness;
      this.vbs.bind_property("brightness", backlight_brightness, "value", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
    } else {
      backlight_brightness_button.sensitive = false;
      backlight_brightness_control.sensitive = false;
    }
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

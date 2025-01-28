using GtkLayerShell;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu.ui")]
public class Vanity.Menu : Astal.Window {
  public AstalWp.Wp wp { get; private set; }
  public VanityBrightness.Device vbs { get; private set; }

  /**
   * Automatically close menu on losing window focus
   */
  public bool close_inactive { get; set; }

  private static uint? active_timeout;

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

  public Menu() {
    Object(
      application: Vanity.Application.instance,
      // uncrustify bug, being interpreted as a namespace and applying an
      // incorrect rule, disable here.
      // *INDENT-OFF*
      namespace: "menu",
      // *INDENT-ON*
      name: "menu",
      anchor: Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.BOTTOM,
      visible: false
    );

    this.close_inactive = true;
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
  }

  public void open_menu() {
    this.gdkmonitor = Application.instance.get_active_monitor();
    if (Application.is_sidecar_monitor(this.gdkmonitor)) {
      this.add_css_class("sidecar");
    } else {
      this.remove_css_class("sidecar");
    }
    present();

    // I'm not sure why, but notify["is_active"] doesn't ever emit events, despite the state changing.
    // work around this with a timeout, and cancel in close if necessary.
    if (this.close_inactive) {
      active_timeout = GLib.Timeout.add(100, () => {
        if (this.is_active == false) {
          this.close_menu();
        }
        return true;
      });
    }
  }

  public void close_menu() {
    if (active_timeout != null) {
      GLib.Source.remove(active_timeout);
    }
    this.visible = false;
  }
}

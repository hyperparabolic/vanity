using GtkLayerShell;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu.ui")]
public class Vanity.Menu : Astal.Window {
  public static Menu instance;

  public AstalWp.Wp wp { get; private set; }
  public VanityBrightness.Device vbs { get; private set; }
  public VanityIdle.Inhibitor vii { get; private set; }

  /**
   * Automatically close menu on losing window focus
   */
  public bool close_inactive { get; set; }

  private static uint? active_timeout;

  [GtkChild]
  private unowned Gtk.Adjustment sink_volume;

  [GtkChild]
  private unowned Gtk.Adjustment source_volume;

  [GtkChild]
  private unowned Gtk.Scale backlight_brightness_control;

  [GtkChild]
  private unowned Gtk.Button backlight_brightness_button;

  [GtkChild]
  private unowned Gtk.Adjustment backlight_brightness;

  [GtkChild]
  private unowned Gtk.Button navigate_back;

  [GtkChild]
  private unowned Adw.NavigationView nav_view;

  [GtkChild]
  private unowned Vanity.MenuSelector selector_idle;

  [GtkCallback]
  public void navigate_hud() {
    if (nav_view.visible_page.tag != "hud") {
      nav_view.pop_to_tag("hud");
    }
  }

  private void navigate_non_root(string tag) {
    if (nav_view.visible_page.tag == tag) {
      return;
    }
    if (nav_view.visible_page.tag != "hud") {
      var tags = new string[2];
      tags[0] = "hud";
      tags[1] = tag;
      nav_view.replace_with_tags(tags);
    } else {
      nav_view.push_by_tag(tag);
    }
  }

  [GtkCallback]
  public void navigate_audio() {
    navigate_non_root("audio");
  }

  [GtkCallback]
  public void navigate_network() {
    navigate_non_root("network");
  }

  [GtkCallback]
  public void navigate_bluetooth() {
    navigate_non_root("bluetooth");
  }

  [GtkCallback]
  public void navigate_notifications() {
    navigate_non_root("notifications");
  }

  [GtkCallback]
  public void navigate_idle() {
    navigate_non_root("idle");
  }

  [GtkCallback]
  public void navigate_sunset() {
    navigate_non_root("sunset");
  }

  [GtkCallback]
  public void toggle_mute_sink() {
    this.wp.audio.default_speaker.mute = !this.wp.audio.default_speaker.mute;
  }

  [GtkCallback]
  public void toggle_mute_source() {
    this.wp.audio.default_microphone.mute = !this.wp.audio.default_microphone.mute;
  }

  [GtkCallback]
  public void toggle_idle() {
    if (this.vii.inhibit) {
      this.vii.disable();
      return;
    }

    // default toggle sets inhibitor to disable at 2:00AM, just in case I
    // forget to disable it.
    var time_now = new DateTime.now_local();

    // let datetime handle date rollover complexity
    var tomorrow = time_now.add_days(1);
    var tomorrow_two_am = new DateTime.local(
      tomorrow.get_year(),
      tomorrow.get_month(),
      tomorrow.get_day_of_month(),
      2,
      0,
      0);
    var d_seconds = (tomorrow_two_am.to_unix() - time_now.to_unix()) % 86400;

    this.vii.enable((int)d_seconds);
  }

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
    instance = this;
  }

  construct {
    this.wp = AstalWp.get_default();
    this.wp.audio.default_speaker.bind_property("volume", sink_volume, "value",
                                                GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
    this.wp.audio.default_microphone.bind_property("volume", source_volume, "value",
                                                   GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);

    this.vbs = VanityBrightness.get_default_screen();
    if (vbs != null) {
      backlight_brightness.upper = this.vbs.max_brightness;
      this.vbs.bind_property("brightness", backlight_brightness, "value",
                             GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
    } else {
      backlight_brightness_button.sensitive = false;
      backlight_brightness_control.sensitive = false;
    }

    this.vii = VanityIdle.Inhibitor.get_default();

    init_signals();
  }

  private void init_signals() {
    nav_view.pushed.connect(() => {
      navigate_back.sensitive = true;
    });

    nav_view.popped.connect(() => {
      navigate_back.sensitive = false;
    });

    this.vii.notify["inhibit"].connect(() => {
      selector_idle.active = this.vii.inhibit;
      selector_idle.icon = this.vii.status_icon;
    });
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

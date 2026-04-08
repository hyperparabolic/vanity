using GtkLayerShell;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/bar.ui")]
public class Vanity.Bar : Astal.Window {
  public static Bar instance { get; private set; }

  public string monitor_connector { get; private set; }

  public AstalBattery.Device battery { get; set; }

  public Vanity.NotificationManager notification_manager { get; set; }

  [GtkChild]
  public unowned Gtk.Label clock;

  [GtkChild]
  public unowned Gtk.Image notification_button_icon;

  [GtkChild]
  public unowned Gtk.Box notification_preview;

  [GtkChild]
  public unowned Gtk.Label notification_label;

  [GtkCallback]
  public void toggle_menu() {
    Vanity.Menu.instance.toggle_menu();
  }

  [GtkCallback]
  public void toggle_notifications() {
    this.notification_manager.toggle_notifications();
  }

  [GtkCallback]
  public void toggle_previews() {
    this.notification_manager.toggle_previews();
  }

  // icon state tracking
  private int notifications_count = 0;
  private int unread_notification_count = 0;

  public Bar(Gdk.Monitor monitor) {
    Object(
      application: Vanity.Application.instance,
      // uncrustify bug, being interpreted as a namespace and applying an
      // incorrect rule, disable here.
      // *INDENT-OFF*
      namespace: @"bar-$(monitor.get_connector())",
      // *INDENT-ON*
      name: @"bar-$(monitor.get_connector())",
      gdkmonitor: monitor,
      anchor: Astal.WindowAnchor.LEFT | Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT
    );
    this.monitor_connector = monitor.get_connector();
    present();
  }

  construct {
    // Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION is lower priority than the theme styles,
    // and generally I think this is correct. Ignore window.background from that here though.
    this.remove_css_class("background");
    this.battery = AstalBattery.Device.get_default();
    this.notification_manager = Vanity.NotificationManager.get_default();

    init_clock();
    init_notifications();
    instance = this;
  }

  private void init_notifications() {
    this.notification_manager.open_notifications.connect(() => {
      this.unread_notification_count = 0;
      update_notifications();
    });

    this.notification_manager.new_notification.connect(() => {
      notifications_count++;
      unread_notification_count++;
      update_notifications();
    });

    this.notification_manager.resolved_notification.connect(() => {
      notifications_count--;
      if (unread_notification_count > 0) {
        // always interacting with unread through popups or using keyboard shortcuts
        unread_notification_count--;
      }
      update_notifications();
    });

    this.notification_manager.notify["snoozed"].connect(() => {
      update_notifications();
    });

    this.notification_manager.notify["show_previews"].connect(() => {
      update_notifications();
    });
  }

  private void update_notifications() {
    var n = this.notification_manager.active_notification;

    // update label
    if (n == null) {
      notification_label.label = "";
    } else {
      notification_label.label = @"$(n.summary) - $(n.body)";
    }

    // show preview?
    if (!notification_manager.snoozed
        && notification_manager.show_previews
        && notification_label.label != "") {
      notification_preview.visible = true;
    } else {
      notification_preview.visible = false;
    }

    // update icon
    if (notification_manager.snoozed) {
      this.notification_button_icon.icon_name = "action-unavailable-symbolic";
    } else if (notifications_count == 0) {
      this.notification_button_icon.icon_name = "switch-off-symbolic";
    } else if (unread_notification_count > 0) {
      this.notification_button_icon.icon_name = "color-management-symbolic";
    } else {
      this.notification_button_icon.icon_name = "draw-circle-symbolic";
    }
  }

  private void update_clock() {
    var clock_time = new DateTime.now_local();
    clock.label = clock_time.format("%I:%M %p %b %e");
  }

  private void init_clock() {
    update_clock();
    GLib.Timeout.add(60000, () => {
      update_clock();
      return true;
    });
  }
}

using GtkLayerShell;

// All in one management for notification display, and vanity's state
// management of notification previews.  State management can be externalized
// if dependency management gets messy, but this is fine for now.
[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/notifications.ui")]
public class Vanity.Notifications : Astal.Window {
  public static Notifications instance;

  public AstalNotifd.Notifd notifd { get; set; }

  /**
   * Show notification preview text in external components
   */
  public bool show_previews { get; set; }

  /**
   * Disable all external notification indicators
   */
  public bool snoozed { get; set; }

  /**
   * Total number of un-actioned and un-dismissed notifications
   */
  public int notifications_count { get; set; }

  /**
   * Number of unread notifications (since window last opened)
   */
  public int unread_count { get; set; }

  private static uint? snooze_timeout;

  private static DateTime? snooze_until;

  public Notifications() {
    Object(
      application : Vanity.Application.instance,
      // uncrustify bug, being interpreted as a namespace and applying an
      // incorrect rule, disable here.
      // *INDENT-OFF*
      namespace: "notifications",
      // *INDENT-ON*
      name: "notifications",
      anchor: Astal.WindowAnchor.TOP,
      visible: false
    );

    instance = this;
    this.show_previews = true;
    this.snoozed = false;
    this.unread_count = 0;
  }

  construct {
    this.notifd = AstalNotifd.Notifd.get_default();
  }

  public void open_notifications() {
    this.gdkmonitor = Application.instance.get_active_monitor();
    present();
  }

  public void close_notifications() {
    this.visible = false;
  }

  public void toggle_notifications() {
    if (this.visible) {
      this.close_notifications();
    } else {
      this.open_notifications();
    }
  }

  public void toggle_previews() {
    this.show_previews = !this.show_previews;
  }

  public void snooze(int timeout_seconds) {
    if (this.snoozed) {
      return;
    }

    this.snoozed = true;

    var timeout_final = timeout_seconds == 0 ? VanityTime.Util.seconds_until_two_am() : timeout_seconds;
    if (timeout_final >= 0) {
      GLib.Timeout.add_seconds_once(
        timeout_final,
        () => { this.unsnooze(); });
      var now = new DateTime.now_local();
      snooze_until = now.add_seconds(timeout_final);
    }

    return;
  }

  public void unsnooze() {
    if (!this.snoozed) {
      return;
    }

    this.snoozed = false;
    if (snooze_timeout != null) {
      GLib.Source.remove(snooze_timeout);
    }
    snooze_until = null;

    return;
  }

  public void toggle_snooze() {
    if (this.snoozed) {
      this.unsnooze();
    } else {
      this.snooze(0);
    }
    return;
  }

  public string snooze_status() {
    var until_string = snooze_until == null ? "cancelled" : snooze_until.format("%I:%M %p");
    var snooze_string = this.snoozed ? @"snoozed until $(until_string)" : "enabled";

    return @"Notifications $(snooze_string)";
  }
}

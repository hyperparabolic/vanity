[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/notification.ui")]
public class Vanity.Notification : Gtk.ListBoxRow {
  public AstalNotifd.Notification notification { get; construct; }

  [GtkChild]
  private unowned Gtk.Image notification_icon;

  [GtkCallback]
  public void close() {
    this.notification.dismiss();
  }

  public Notification(AstalNotifd.Notification notification) {
    Object(notification: notification);
    // suppress ListBoxRow behavior,
    this.activatable = false;
    if (notification.app_icon != null && notification.app_icon != "") {
      this.notification_icon.icon_name = notification.app_icon;
    }
  }
}

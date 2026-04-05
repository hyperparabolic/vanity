using GtkLayerShell;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/notification.ui")]
public class Vanity.Notification : Astal.Window {
  public AstalNotifd.Notification notification { get; construct; }

  [GtkChild]
  private unowned Gtk.Image notification_icon;

  [GtkCallback]
  public void dismiss() {
    this.notification.dismiss();
  }

  public Notification(AstalNotifd.Notification notification) {
    Object(
      application: Vanity.Application.instance,
      // uncrustify bug, being interpreted as a namespace and applying an
      // incorrect rule, disable here.
      // *INDENT-OFF*
      namespace: "notifications",
      // *INDENT-ON*
      anchor: Astal.WindowAnchor.TOP,
      visible: false,
      notification: notification
    );

    if (notification.app_icon != null && notification.app_icon != "") {
      this.notification_icon.icon_name = notification.app_icon;
    }
  }

  construct {
  }

  public void show_notification(Gdk.Monitor monitor) {
    this.gdkmonitor = monitor;
    present();
  }

  public void hide_notification() {
    this.visible = false;
  }
}

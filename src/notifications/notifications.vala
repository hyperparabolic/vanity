using GtkLayerShell;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/notifications.ui")]
public class Vanity.Notifications : Astal.Window {
  public static Notifications instance;

  public AstalNotifd.Notifd notifd { get; set; }


  public Notifications() {
    Object(
      application: Vanity.Application.instance,
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
}

using GtkLayerShell;

const int BASE_OFFSET = 15;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/notification.ui")]
public class Vanity.Notification : Astal.Window {
  public AstalNotifd.Notification notification { get; construct; }

  public Vanity.Notification? above_notification { get; set; }

  public Vanity.Notification? below_notification { get; set; }

  [GtkChild]
  private unowned Gtk.Image notification_icon;

  [GtkChild]
  private unowned Gtk.Box actions;

  [GtkCallback]
  public void dismiss() {
    this.notification.dismiss();
  }

  private void setup_actions() {
    notification.actions.@foreach((a) => {
      Gtk.Button action = new Gtk.Button();
      action.label = a.label;
      action.halign = Gtk.Align.END;
      action.hexpand = true;
      action.add_css_class("notification_action");
      action.clicked.connect(() => { this.notification.invoke(a.id); });
      this.actions.append(action);
    });
  }

  public void refresh_position() {
    if (above_notification == null || above_notification.get_height() == 0) {
      this.margin_top = BASE_OFFSET;
      this.add_css_class("active");
      return;
    }
    this.remove_css_class("active");
    this.margin_top = above_notification.margin_top + above_notification.get_height() + BASE_OFFSET;
  }

  public Notification(AstalNotifd.Notification notification) {
    Object(
      application : Vanity.Application.instance,
      // uncrustify bug, being interpreted as a namespace and applying an
      // incorrect rule, disable here.
      // *INDENT-OFF*
      namespace: "notifications",
      // *INDENT-ON*
      anchor : Astal.WindowAnchor.TOP,
      visible: false,
      margin_top: BASE_OFFSET,
      notification: notification
    );

    if (notification.app_icon != null && notification.app_icon != "") {
      this.notification_icon.icon_name = notification.app_icon;
    }
    setup_actions();
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

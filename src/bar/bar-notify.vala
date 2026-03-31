[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/bar-notify.ui")]
class Vanity.BarNotify : Gtk.Box {
  public AstalNotifd.Notifd notifd { get; set; }

  [GtkCallback]
  public void toggle_notifications() {
    Vanity.Notifications.instance.toggle_notifications();
  }

  construct {
    this.notifd = AstalNotifd.Notifd.get_default();
  }
}

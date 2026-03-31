[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/bar-notify.ui")]
class Vanity.BarNotify : Gtk.Box {
  public AstalNotifd.Notifd notifd { get; set; }

  construct {
    this.notifd = AstalNotifd.Notifd.get_default();
  }
}

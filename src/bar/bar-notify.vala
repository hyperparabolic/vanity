[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/bar-notify.ui")]
class Vanity.BarNotify : Gtk.Box {
  private Vanity.Notifications notifications;

  [GtkChild]
  private unowned Gtk.Box preview_container;

  [GtkChild]
  private unowned Gtk.Image button_icon;

  [GtkCallback]
  public void toggle_notifications() {
    Vanity.Notifications.instance.toggle_notifications();
  }

  [GtkCallback]
  public void toggle_previews() {
    Vanity.Notifications.instance.toggle_previews();
    // self triggered updates do not trigger notify callback
    update();
  }

  private void update() {
    if (this.notifications.snoozed) {
      // snooze takes absolute priority, hide all and override icon
      this.preview_container.visible = false;
      this.button_icon.icon_name = "gnome-disks-state-standby-symbolic";
      return;
    }

    this.preview_container.visible = this.notifications.show_previews && this.notifications.notifications_count > 0;
    // TODO: icon tweaks based on unread and total notification count
    this.button_icon.icon_name = "switch-off-symbolic";
    // TODO: preview text
  }

  construct {
    this.notifications = Vanity.Notifications.instance;

    this.notifications.notify["snoozed"].connect(() => {
      update();
    });
    this.notifications.notify["show_previews"].connect(() => {
      update();
    });
    this.notifications.notify["notifications_count"].connect(() => {
      update();
    });
    this.notifications.notify["unread_count"].connect(() => {
      update();
    });

    update();
  }
}

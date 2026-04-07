// Manager for notification windows and application level
// notification state.
public class Vanity.NotificationManager : Object {
  private static NotificationManager default_manager;

  public AstalNotifd.Notifd notifd { get; set; }

  private Gee.LinkedList<Vanity.Notification> notifications;

  private Mutex notifications_mutex = Mutex();

  // Show notification preview text
  public bool show_previews { get; set; }

  // Disable all external notification indicators
  public bool snoozed { get; set; }

  private uint? snooze_timeout;

  private DateTime? snooze_until;

  private Gdk.Monitor? display_monitor;

  public static NotificationManager get_default() {
    if (default_manager != null) {
      return default_manager;
    }

    return new NotificationManager();
  }

  private NotificationManager() {
    this.notifd = AstalNotifd.Notifd.get_default();
    this.notifications = new Gee.LinkedList<Vanity.Notification>();
    this.show_previews = true;
    this.snoozed = false;

    this.notifd.notified.connect(handle_notified);
    this.notifd.resolved.connect(handle_resolved);
  }

  ~NotificationManager() {
    // clean up all owned notificaiton windows
    Vanity.Notification notification = notifications.poll();

    while (notification != null) {
      notification.close();
      notification = notifications.poll();
    }
  }

  private void handle_notified(uint id, bool replaced) {
    if (replaced) {
      this.handle_resolved(id, AstalNotifd.ClosedReason.UNDEFINED);
      return;
    }

    var a_notif = notifd.get_notification(id);
    if (a_notif == null) {
      message(@"received null notification, id: $(id)");
      return;
    }

    var notification = new Vanity.Notification(a_notif);
    Vanity.Application.instance.add_window(notification);
    notifications_mutex.lock();
    notifications.offer_head(notification);
    if (this.display_monitor != null) {
      notification.show_notification(this.display_monitor);
    }
    notifications_mutex.unlock();
  }

  private void handle_resolved(uint id, AstalNotifd.ClosedReason reason) {
    notifications_mutex.lock();
    Vanity.Notification? notification = notifications.first_match((n) => {
      return id == n.notification.id;
    });
    if (notification == null) {
      notifications_mutex.unlock();
      return;
    }

    notifications.remove(notification);
    notification.hide_notification();
    notification.close();
    Vanity.Application.instance.remove_window(notification);
    notifications_mutex.unlock();
  }

  public void show_all_notifications() {
    notifications_mutex.lock();
    if (this.display_monitor == null) {
      this.display_monitor = Vanity.Application.instance.get_active_monitor();
    }
    notifications.@foreach((n) => {
      // TODO cancel popup timeout once that exists
      n.show_notification(this.display_monitor);
      return true;
    });
    notifications_mutex.unlock();
  }

  public void hide_all_notifications() {
    notifications_mutex.lock();
    this.display_monitor = null;
    notifications.@foreach((n) => {
      n.hide_notification();
      return true;
    });
    notifications_mutex.unlock();
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

// Manager for notification windows and application level
// notification state.
public class Vanity.NotificationManager : Object {
  private static NotificationManager default_manager;

  public AstalNotifd.Notifd notifd { get; set; }

  public AstalNotifd.Notification? active_notification { get; private set; default = null; }

  private Gee.LinkedList<Vanity.Notification> notifications;

  // FIFO queue for managing popups by AstalNotifd.Notification.id
  private Gee.LinkedList<uint> popup_ids;

  // Not currently doing anything, but keeping this possible to run in a dedicated
  // thread if necessary. Could be split into visibility and list mutexes if necessary
  // but currently handles changes in both.
  private Mutex notifications_mutex = Mutex();

  // Show notification preview text
  public bool show_previews { get; set; }

  // Disable all external notification indicators
  public bool snoozed { get; set; }

  private uint? snooze_timeout;

  private DateTime? snooze_until;

  private enum NotificationVisibility {
    // no notifications are actively being shown
    NONE,
    // notifications have been explicitly toggled visible
    SHOW,
    // notification popups are currently present
    SHOW_TEMP,
  }

  // notifications are bound to a monitor while being shown, this includes
  // temporary notification popups.
  private NotificationVisibility visibility = NotificationVisibility.NONE;

  // currently bound monitor, may only be nulled / modified in NONE state
  private Gdk.Monitor? display_monitor;

  // #TODO menu controls
  // #TODO bar preview
  // #TODO icons

  public static NotificationManager get_default() {
    if (default_manager != null) {
      return default_manager;
    }

    default_manager = new NotificationManager();
    return default_manager;
  }

  private NotificationManager() {
    this.notifd = AstalNotifd.Notifd.get_default();
    this.notifications = new Gee.LinkedList<Vanity.Notification>();
    this.popup_ids = new Gee.LinkedList<uint>();
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

  private void refresh_positions() {
    // needs to wait a moment for `present()` and height requests to settle
    // 50 ms seems more than fast enough for animation length and consistent
    GLib.Timeout.add_once(50, () => {
      notifications_mutex.lock();
      notifications.@foreach((n) => {
        n.refresh_position();
        return true;
      });
      notifications_mutex.unlock();
    });
  }

  // Display a notification (or don't) appropriately for current visibility and state.
  // This handles all state checks, and refreshes positions as necessary.
  private void popup(Vanity.Notification notification) {
    if (!this.show_previews || this.snoozed) {
      return;
    }

    notifications_mutex.lock();
    if (this.visibility == NotificationVisibility.SHOW) {
      notification.show_notification(this.display_monitor);
      refresh_positions();
      notifications_mutex.unlock();
      return;
    }

    if (this.visibility == NotificationVisibility.NONE) {
      // transition to SHOW_TEMP
      this.display_monitor = Vanity.Application.instance.get_active_monitor();
      this.visibility = NotificationVisibility.SHOW_TEMP;
    }

    // SHOW_TEMP behavior
    notification.show_notification(this.display_monitor);
    popup_ids.offer(notification.notification.id);
    GLib.Timeout.add_once(5000, () => {
      hide_next_popup();
    });

    refresh_positions();
    notifications_mutex.unlock();
  }

  private void hide_next_popup() {
    if (this.visibility != NotificationVisibility.SHOW_TEMP) {
      // user triggered state transition, ignore
      return;
    }

    notifications_mutex.lock();
    var id = popup_ids.poll();
    Vanity.Notification? notification = notifications.first_match((n) => {
      return id == n.notification.id;
    });
    if (notification == null) {
      notifications_mutex.unlock();
      return;
    }

    notification.hide_notification();
    if (notification.above_notification == null) {
      // this is the last temporary popup
      this.visibility = NotificationVisibility.NONE;
      this.display_monitor = null;
    }
    notifications_mutex.unlock();
    return;
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
    var below = !notifications.is_empty ? notifications.get(0) : null;
    if (below != null) {
      below.above_notification = notification;
      notification.below_notification = below;
    }
    Vanity.Application.instance.add_window(notification);

    notifications_mutex.lock();
    notifications.offer_head(notification);
    // most recent notification is always active
    this.active_notification = notification.notification;
    notifications_mutex.unlock();

    popup(notification);
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

    var above = notification.above_notification;
    var below = notification.below_notification;
    if (above != null) {
      above.below_notification = below;
    }
    if (below != null) {
      below.above_notification = above;
    }

    notifications.remove(notification);
    if (notification.notification.id == active_notification.id && !notifications.is_empty) {
      var new_active = notifications.get(0);
      this.active_notification = new_active != null ? new_active.notification : null;
    }
    notification.hide_notification();
    notification.close();
    Vanity.Application.instance.remove_window(notification);
    refresh_positions();
    notifications_mutex.unlock();
  }

  public void show_all_notifications() {
    notifications_mutex.lock();
    if (this.visibility == NotificationVisibility.SHOW) {
      notifications_mutex.unlock();
      return;
    }

    this.visibility = NotificationVisibility.SHOW;
    if (this.display_monitor == null) {
      this.display_monitor = Vanity.Application.instance.get_active_monitor();
    }
    // iterate in reverse to preserve layers
    var iter = notifications.bidir_list_iterator();
    for (var has_next = iter.last(); has_next; has_next = iter.previous()) {
      iter.get().show_notification(this.display_monitor);
    }
    refresh_positions();
    notifications_mutex.unlock();
  }

  public void hide_all_notifications() {
    notifications_mutex.lock();
    if (this.visibility == NotificationVisibility.NONE) {
      notifications_mutex.unlock();
      return;
    }

    this.visibility = NotificationVisibility.NONE;
    this.display_monitor = null;
    notifications.@foreach((n) => {
      n.hide_notification();
      return true;
    });
    notifications_mutex.unlock();
  }

  public void toggle_notifications() {
    switch (this.visibility) {
      case NotificationVisibility.NONE :
        show_all_notifications();
        break;
      case NotificationVisibility.SHOW :
        hide_all_notifications();
        break;
      case NotificationVisibility.SHOW_TEMP :
        show_all_notifications();
        break;
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

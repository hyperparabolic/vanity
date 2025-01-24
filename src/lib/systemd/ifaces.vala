namespace VanitySystem {}

/**
 * This is just a small subset of this bus interface. Enough for unit management.
 */
[DBus (name = "org.freedesktop.systemd1.Unit")]
private interface VanitySystem.ISystemdUnitBus : DBusProxy {

  [DBus (name = "Start")]
  public abstract GLib.ObjectPath start(string mode) throws DBusError, IOError;

  [DBus (name = "Stop")]
  public abstract GLib.ObjectPath stop(string mode) throws DBusError, IOError;

  [DBus (name = "Restart")]
  public abstract GLib.ObjectPath restart(string mode) throws DBusError, IOError;

  [DBus (name = "ActiveState")]
  public abstract string active_state { owned get; }

  [DBus (name = "CanStart")]
  public abstract bool can_start {  get; }

  [DBus (name = "CanStop")]
  public abstract bool can_stop {  get; }

  [DBus (name = "Id")]
  public abstract string id { owned get; }
}

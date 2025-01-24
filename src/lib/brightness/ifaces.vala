[DBus(name = "org.freedesktop.login1.Session")]
private interface VanityBrightness.IBrightnessBus : DBusProxy {

  public abstract void set_brightness(string class, string name, uint32 value) throws Error;
}

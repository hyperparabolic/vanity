[DBus(name = "com.github.maximbaz.YubikeyTouchDetector")]
private interface VanityYubikey.IDetectorBus : DBusProxy {

  [DBus(name = "GPGState")]
  public abstract uint32 GPGState { get; set; }

  [DBus(name = "U2FState")]
  public abstract uint32 U2FState { get; set; }

  [DBus(name = "HMACState")]
  public abstract uint32 HMACState { get; set; }
}

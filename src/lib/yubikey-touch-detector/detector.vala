namespace VanityYubikey {
}

const string SUBTEXT_GPG = "GPG";
const string SUBTEXT_U2F = "U2F";
const string SUBTEXT_HMAC = "HMAC";

public class VanityYubikey.Detector : Object {
  private static Detector default_detector;

  private IDetectorBus proxy;

  // expose, can be queried directly
  public uint32 gpg_state { get; private set; }
  public uint32 u2f_state { get; private set; }
  public uint32 hmac_state { get; private set; }

  // nicer interface
  public bool press { get; private set; }
  public string subtext { get; private set; }

  public static Detector? get_default() {
    if (default_detector != null) {
      return default_detector;
    }

    try {
      default_detector = new Detector();
      return default_detector;
    } catch (Error e) {
      critical(e.message);
    }

    return null;
  }

  private Detector() throws Error {
    this.proxy = Bus.get_proxy_sync(BusType.SESSION,
                                    "com.github.maximbaz.YubikeyTouchDetector",
                                    "/com/github/maximbaz/YubikeyTouchDetector");
    sync();
    this.proxy.g_properties_changed.connect(() => sync());
  }

  private void sync() {
    this.gpg_state = this.proxy.GPGState;
    this.u2f_state = this.proxy.U2FState;
    this.hmac_state = this.proxy.HMACState;

    // doesn't support polling for multiple types simultaneously, this should be fine
    this.press = (this.gpg_state + this.u2f_state + this.hmac_state) > 0;
    this.subtext = this.gpg_state > 0 ? SUBTEXT_GPG :
                   this.u2f_state > 0 ? SUBTEXT_U2F :
                   this.hmac_state > 0 ? SUBTEXT_HMAC :
                   "";
  }
}

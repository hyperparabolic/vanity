public class VanityWeather.GeoclueLocation : VanityWeather.ILocation, Object {
  private static GeoclueLocation instance;
  private GClue.Simple gclue { get; set; }
  private GClue.ClientProxy client { get; set; }

  private bool refreshing = true;

  public double latitude { get; set; }
  public double longitude { get; set; }

  public static GeoclueLocation? get_default() {
    if (instance != null) {
      return instance;
    }

    instance = new GeoclueLocation();
    return instance;
  }

  private GeoclueLocation() {
  }

  public async void init() {
    if (gclue != null) {
      return;
    }

    try {
      gclue = yield new GClue.Simple(Vanity.APP_ID, GClue.AccuracyLevel.EXACT, null);
      client = gclue.get_client();
      client.location_updated.connect(() => this.sync());
    } catch (Error e) {
      critical(e.message);
    }
  }

  public void sync() {
    var loc = gclue.get_location();
    this.latitude = loc.latitude;
    this.longitude = loc.longitude;
    try {
      client.call_stop_sync();
    } catch (Error e) {
      critical(e.message);
    } finally {
      refreshing = false;
      this.updated();
    }
  }

  public void refresh() {
    try {
      if (!this.refreshing) {
        client.call_start_sync();
      }
    } catch (Error e) {
      critical(e.message);
    }
  }
}

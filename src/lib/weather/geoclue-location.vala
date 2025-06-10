public class VanityWeather.GeoclueLocation : VanityWeather.ILocation, Object {
  private static GeoclueLocation instance;
  private GClue.Simple gclue { get; set; }
  private GClue.ClientProxy client { get; set; }
  public double latitude { get; set; }
  public double longitude { get; set; }

  public static GeoclueLocation? get_default() {
    if (instance != null) {
      return instance;
    }

    try {
      instance = new GeoclueLocation();
    } catch (Error e) {
      critical(e.message);
    }
    return instance;
  }

  private GeoclueLocation() throws Error {
    gclue = new GClue.Simple.sync(VanityWeather.APP_ID, GClue.AccuracyLevel.EXACT);
    client = gclue.get_client();
    client.location_updated.connect(() => this.sync());
  }

  public void sync() {
    var loc = gclue.get_location();
    this.latitude = loc.latitude;
    this.longitude = loc.longitude;
  }
}

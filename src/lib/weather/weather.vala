/**
 * Location interface. Probably just sticking with geoclue (beacondb), but some
 * other thoughts if I find it's flaky away from home:
 *
 * - zip code lookup table?
 * - ip based lookup?
 * - plus code conversion?
 */
public interface VanityWeather.ILocation : Object {
  public abstract double latitude { get; set; }
  public abstract double longitude { get; set; }
  public signal void updated();

  public async virtual void init() {
  }

  public virtual void refresh() {
  }
}

public class VanityWeather.Weather : Object {
  private static Weather instance;
  public GWeather.Info info { get; set; }
  public GWeather.Location gw_loc { get; set; }

  public VanityWeather.ILocation v_loc { get; set; }
  public VanityWeather.Forecast forecast { get; set; }

  // emitted on forecast update
  public signal void updated();

  /**
   * Get the default weather singleton with geoclue location.
   */
  public static Weather? get_default() {
    if (instance != null) {
      return instance;
    }

    instance = new Weather(VanityWeather.GeoclueLocation.get_default());
    return instance;
  }

  /**
   * Weather provider.
   *
   * Can be constructed separately for some other location provider. Location should
   * be unitialized or accept duplicate init().
   */
  public Weather(ILocation location) {
    this.v_loc = location;
    this.v_loc.init.begin();
    this.v_loc.updated.connect(init);
  }

  private void init() {
    this.v_loc.updated.disconnect(init);
    this.gw_loc = GWeather.Location.get_world();
    this.gw_loc = gw_loc.find_nearest_city(this.v_loc.latitude, this.v_loc.longitude);

    this.info = new GWeather.Info(gw_loc);
    this.info.set_application_id(Vanity.APP_ID);
    this.info.set_contact_info("hi@decent.id");
    this.info.set_enabled_providers(GWeather.Provider.NWS);

    this.info.updated.connect(update_forecast);
    this.v_loc.updated.connect(sync_location);
    // auto update hourly
    GLib.Timeout.add_seconds(3600, () => {
      refresh();
      return true;
    });

    this.info.update();
  }

  private void update_forecast() {
    unowned var list = info.get_forecast_list();

    try {
      forecast = new NWSForecast(list);
      message("weather now: %s, %s", forecast.now_temp, forecast.now_icon);
      this.updated();
    } catch (Error e) {
      critical(e.message);
    }
  }

  public void refresh() {
    this.info.update();
  }

  /**
   * Force weather to sync to location.
   *
   * This should be handled automatically unless location is modified manually.
   */
  public void sync_location() {
    this.gw_loc = GWeather.Location.get_world();
    this.gw_loc = gw_loc.find_nearest_city(this.v_loc.latitude, this.v_loc.longitude);
    this.info.location = this.gw_loc;
    message("weather location updated, %s", this.gw_loc.get_city_name());
  }

  ~Weather() {
    GWeather.Info.store_cache();
  }
}

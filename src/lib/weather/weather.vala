namespace VanityWeather {
  const string APP_ID = "com.github.hyperparabolic.vanity";
}

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
  public GWeather.Info info { get; set; }
  public GWeather.Location gw_loc { get; set; }

  public VanityWeather.Forecast forecast { get; set; }

  public Weather(ILocation location) {
    gw_loc = GWeather.Location.get_world();
    gw_loc = gw_loc.find_nearest_city(location.latitude, location.longitude);

    info = new GWeather.Info(gw_loc);
    info.set_application_id(VanityWeather.APP_ID);
    info.set_contact_info("hi@decent.id");
    info.set_enabled_providers(GWeather.Provider.NWS);
    info.update();

    info.updated.connect(() => {
      unowned var list = info.get_forecast_list();

      var hour = 0;
      list.foreach((info) => {
        message(@"hour: $(hour)");
        console_dump(info);
        hour++;
      });

      try {
        forecast = new NWSForecast(list);
        debug("now: %s, %s", forecast.now_temp, forecast.now_icon);
      } catch (Error e) {
        critical(e.message);
      }
    });
  }

  private void console_dump(GWeather.Info info) {
    // notes for NWS
    // "-"
    // message(@"conditions: $(info.get_conditions())");
    message(@"daytime: $(info.is_daytime())");
    message(@"update: $(info.get_update())");
    // ##.# °F
    // message(@"dew: $(info.get_dew())");
    // ##%
    // message(@"humidity: $(info.get_humidity())");
    // City
    // message(@"location name: $(info.get_location_name())");
    // Unknown
    // message(@"pressure: $(info.get_pressure())");
    // Broken clouds
    // message(@"sky: $(info.get_sky())");
    // ##:##
    // message(@"sunrise: $(info.get_sunrise())");
    // ##:##
    // message(@"sunset: $(info.get_sunset())");
    // ##.# °F
    message(@"temp: $(info.get_temp())");
    // "-"
    // message(@"max temp: $(info.get_temp_max())");
    // "-"
    // message(@"min temp: $(info.get_temp_min())");
    // ##.# °F
    // message(@"temp summary: $(info.get_temp_summary())");
    // Unknown
    // message(@"visibility: $(info.get_visibility())");
    // City : Sky
    // message(@"weather summary: $(info.get_weather_summary())");
    message(@"symbolic icon name: $(info.get_symbolic_icon_name())");
    message(@"icon name: $(info.get_icon_name())");
  }

  ~Weather() {
    GWeather.Info.store_cache();
  }
}

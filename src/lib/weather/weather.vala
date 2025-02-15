namespace VanityWeather {
  const string APP_ID = "com.github.hyperparabolic.vanity";
}


/**
 * Location interface, just a static placeholder. Possible implementations
 * to prototype:
 *
 * - zip code lookup table?
 * - geoclue (needs better local api)?
 * - ip based lookup?
 * - plus code conversion?
 */
public interface VanityWeather.ILocation : Object {
  public abstract double latitude { get; set; }
  public abstract double longitude { get; set; }
  public virtual void sync() {
  }
}

public class VanityWeather.StaticLocation : ILocation, Object {
  public double latitude { get; set; }
  public double longitude { get; set; }
  public void sync() {
    this.latitude = 42.011568;
    this.longitude = -87.665909;
  }
}

public class VanityWeather.Weather : Object {
  public GWeather.Info info { get; set; }
  public GWeather.Location gw_loc { get; set; }

  public Weather(ILocation location) {
    gw_loc = GWeather.Location.get_world();
    gw_loc = gw_loc.find_nearest_city(location.latitude, location.longitude);

    info = new GWeather.Info(gw_loc);
    info.set_application_id(VanityWeather.APP_ID);
    // TODO
    info.set_contact_info("");
    info.set_enabled_providers(GWeather.Provider.NWS);
    info.update();

    info.updated.connect(() => {
      console_dump(info);

      var count = 0;
      unowned var list = info.get_forecast_list();
      list.foreach((i) => {
        count++;
        message("");
        message("next forecast");
        console_dump(i);
      });
      // 173 total, hourly for 7 days, but 5 extras? maybe remainder of the current day + 7?
      message(@"$(count.to_string()) total forecasts");
    });
  }

  private void console_dump(GWeather.Info info) {
    // notes for NWS
    // "-"
    message(@"conditions: $(info.get_conditions())");
    message(@"daytime: $(info.is_daytime())");
    // ##.# °F
    message(@"dew: $(info.get_dew())");
    // ##%
    message(@"humidity: $(info.get_humidity())");
    message(@"icon: $(info.get_icon_name())");
    // City
    message(@"location name: $(info.get_location_name())");
    // Unknown
    message(@"pressure: $(info.get_pressure())");
    // Broken clouds
    message(@"sky: $(info.get_sky())");
    // ##:##
    message(@"sunrise: $(info.get_sunrise())");
    // ##:##
    message(@"sunset: $(info.get_sunset())");
    message(@"symbolic icon: $(info.get_symbolic_icon_name())");
    // ##.# °F
    message(@"temp: $(info.get_temp())");
    // "-"
    message(@"max temp: $(info.get_temp_max())");
    // "-"
    message(@"min temp: $(info.get_temp_min())");
    // ##.# °F
    message(@"temp summary: $(info.get_temp_summary())");
    // Unknown
    message(@"visibility: $(info.get_visibility())");
    // City : Sky
    message(@"weather summary: $(info.get_weather_summary())");
  }

  ~Weather() {
    GWeather.Info.store_cache();
  }
}

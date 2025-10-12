namespace VanityWeather {
  const GWeather.TemperatureUnit TEMP_UNIT = GWeather.TemperatureUnit.FAHRENHEIT;
}

public errordomain VanityWeather.ForecastError {
  // any error where there isn't currently a plan for recovery
  FATAL,
}

// dumb data container object doesn't need an interface
public class VanityWeather.DaySummary : Object {
  public string temp_max { get; set; }
  public string temp_min { get; set; }
  public string icon_day { get; set; }
  public string icon_night { get; set; }
  // ISO 8601, 1 Monday, 2 Tuesday... 7 Sunday
  public uint iso_day_of_week { get; set; }
}

public interface VanityWeather.Forecast : Object {
  public abstract string location { get; set; }
  public abstract string now_temp { get; set; }
  public abstract string now_icon { get; set; }

  /**
   * Returns number of DaySummarys stored internally.
   */
  public abstract uint days_length();

  /**
   * Get DaySummary at index, zero indexed.
   */
  public abstract DaySummary? get_day(uint index);
}

public class VanityWeather.NWSForecast : VanityWeather.Forecast, Object {
  public string location { get; set; }
  public string now_temp { get; set; }
  public string now_icon { get; set; }
  // NWSForecast will include 7 DaySummary entries
  private List<VanityWeather.DaySummary> days;

  public uint days_length() {
    if (days == null) {
      return 0;
    }
    return (uint)days.length();
  }

  public DaySummary? get_day(uint index) {
    if (days == null) {
      return null;
    }
    if (index >= (uint)days.length) {
      return null;
    }
    return days.nth_data(index);
  }

  /**
   * nws_forecast_list - GWeather.Info.get_forecast_list() for the
   * GWeather.Provider.NWS provider. These Info entries each summarize
   * an hour for the upcoming week's forecast. The forecast actually
   * starts several hours in the past, and the misnamed `get_value_update`
   * contains a timestamp for each hour (not the time since last update as
   * documented).
   */
  public NWSForecast(SList<GWeather.Info> nws_forecast_list) throws ForecastError {
    if (nws_forecast_list.length() < 168) {
      // 170 is the minimum I've observed, 168 should be here for full 7 days
      throw new ForecastError.FATAL("expected at least 168 hourly forecasts, received %u", nws_forecast_list.length());
    }
    var sliced = slice_days(nws_forecast_list);
    var now = sliced.data.data;
    var now_temp_d = 0.0;
    now.get_value_temp(VanityWeather.TEMP_UNIT, out now_temp_d);
    this.location = now.get_location_name();
    this.now_temp = format_temp(now_temp_d);
    this.now_icon = now.get_symbolic_icon_name();
    this.days = new List<VanityWeather.DaySummary>();

    var day_of_week = new DateTime.now_local().get_day_of_week();
    unowned var slice = sliced;
    unowned var current_day = slice.data;
    while (slice != null) {
      current_day = slice.data;
      var summary = coalesce_day(current_day, day_of_week);
      this.days.append(summary);

      day_of_week++;
      if (day_of_week > 7) {
        day_of_week = 1;
      }
      slice = slice.next;
    }
  }

  /**
   * Slice the week long hourly nws forecast into 7 slices, one for each day.
   *
   * Each GWeather.Info entry is just a pointer to the original data. Helps
   * centralize messy iteration, but all data in this structure is unowned.
   */
  private static SList<SList<weak GWeather.Info> > slice_days(SList<GWeather.Info> nws_forecast_list) {
    SList<SList<weak GWeather.Info> > sliced = new SList<SList<weak GWeather.Info> >();
    unowned SList<GWeather.Info> current_hour = nws_forecast_list;

    // discard Info entries that are more than an hour in the past
    var unix_timestamp_now = new DateTime.now_utc().to_unix();
    time_t unix_timestamp = 0;
    current_hour.data.get_value_update(out unix_timestamp);
    while (unix_timestamp_now - unix_timestamp > 60 * 60) {
      debug(@"discarding info at $(current_hour.data.get_update())");
      current_hour = current_hour.next;
      current_hour.data.get_value_update(out unix_timestamp);
    }
    debug(@"keeping first info at $(current_hour.data.get_update())");

    var hours_max = hours_until_tomorrow();
    debug("%u hours until tomorrow", hours_max);
    for (int days = 0; days < 7; days++) {
      SList<weak GWeather.Info> day = new SList<weak GWeather.Info>();
      // establish first iteration bounds

      for (int hours = 0; hours < hours_max; hours++) {
        day.append(current_hour.data);
        debug("day %i write hour %i, time: %s", days, hours, current_hour.data.get_update());
        if (current_hour.next == null) {
          continue;
        }
        current_hour = current_hour.next;
      }

      debug("day %i contains %i hours", days, hours_max);
      sliced.append(day.copy());
      // all further days are 24 hours
      hours_max = 24;
    }

    debug("%u day slices", sliced.length());
    return sliced;
  }

  /**
   * Returns an int, number of hours until tomorrow (rounds up a partial hour).
   */
  private static int hours_until_tomorrow() {
    var time_now = new DateTime.now_local();

    var tomorrow = time_now.add_days(1);
    var tomorrow_midnight = new DateTime.local(
      tomorrow.get_year(),
      tomorrow.get_month(),
      tomorrow.get_day_of_month(),
      0,
      0,
      0);

    // microseconds
    var delta = tomorrow_midnight.difference(time_now);
    var hours = delta / TimeSpan.HOUR;
    // increment, treat forecast at the start of the current hour as "now"
    hours++;

    return (int)hours;
  }

  /**
   * Combine a list of GWeather Info into a summary.
   */
  private static DaySummary coalesce_day(SList<weak GWeather.Info> day_slice, uint day_of_week) {
    debug("day of week %u contains %u hour slices", day_of_week, day_slice.length());
    // initialize temperature reducers
    double current = 0.0;
    double max = double.MIN;
    double min = double.MAX;

    HashTable<string, int> day_icon_count = new HashTable<string, int>(str_hash, str_equal);
    HashTable<string, int> night_icon_count = new HashTable<string, int>(str_hash, str_equal);

    day_slice.foreach((hour_info) => {
      hour_info.get_value_temp(VanityWeather.TEMP_UNIT, out current);
      max = double.max(max, current);
      min = double.min(min, current);

      var icon = hour_info.get_symbolic_icon_name();
      var current_map = hour_info.is_daytime() ? day_icon_count : night_icon_count;

      if (!current_map.contains(icon)) {
        current_map.insert(icon, 1);
      } else {
        current_map.replace(icon, current_map.get(icon) + 1);
      }
    });

    var summary = new DaySummary();
    summary.temp_max = format_temp(max);
    summary.temp_min = format_temp(min);
    summary.iso_day_of_week = day_of_week;

    var current_max_count = 0;
    var current_max_icon = "";
    day_icon_count.foreach((icon, count) => {
      // maybe amplify bad weather icons?
      if (count > current_max_count) {
        current_max_icon = icon;
      }
    });
    summary.icon_day = current_max_icon;

    current_max_count = 0;
    current_max_icon = "";
    night_icon_count.foreach((icon, count) => {
      // maybe amplify bad weather icons?
      if (count > current_max_count) {
        current_max_icon = icon;
      }
    });
    summary.icon_night = current_max_icon;
    debug("day %u, max: %s, min; %s, icon_day: %s, icon_night: %s",
          summary.iso_day_of_week,
          summary.temp_max,
          summary.temp_min,
          summary.icon_day,
          summary.icon_night);

    return summary;
  }

  private static string format_temp(double temp) {
    return "%.1f°F".printf(temp);
  }
}

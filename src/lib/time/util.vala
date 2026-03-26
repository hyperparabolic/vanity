namespace VanityTime {
}

public class VanityTime.Util {

  // Returns an int64 with the number of seconds until the next 2:00 AM
  public static int seconds_until_two_am() {
    var time_now = new DateTime.now_local();

    // let datetime handle date rollover complexity
    var tomorrow = time_now.add_days(1);
    var tomorrow_two_am = new DateTime.local(
      tomorrow.get_year(),
      tomorrow.get_month(),
      tomorrow.get_day_of_month(),
      2,
      0,
      0);
    var d_seconds = (int)(tomorrow_two_am.to_unix() - time_now.to_unix()) % 86400;

    return d_seconds;
  }
}

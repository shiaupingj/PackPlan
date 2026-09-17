import '../models/pack_list.dart';

abstract final class TripFormatters {
  static String summary(PackList list) {
    return [
      tripType(list.tripType),
      duration(list),
      weatherSummary(list.weatherConditions),
    ].join(' · ');
  }

  static String tripType(TripType type) {
    return switch (type) {
      TripType.hiking => '登山',
      TripType.city => '城市旅遊',
      TripType.camping => '露營',
    };
  }

  static String duration(PackList list) {
    if (list.nights <= 0) return '${list.days}天';
    return '${list.days}天${list.nights}夜';
  }

  static String weatherSummary(Set<WeatherCondition> weatherConditions) {
    return weatherConditions.map(weather).join(' / ');
  }

  static String weather(WeatherCondition weather) {
    return switch (weather) {
      WeatherCondition.sunny => '晴天',
      WeatherCondition.cloudy => '陰天',
      WeatherCondition.rainy => '雨天',
      WeatherCondition.cold => '低溫',
    };
  }
}

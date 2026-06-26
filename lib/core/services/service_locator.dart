import 'location_service.dart';
import 'http_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  LocationService _locationService = GeolocatorLocationService();
  HttpService _httpService = RealHttpService();

  LocationService get locationService => _locationService;
  HttpService get httpService => _httpService;

  void registerLocationService(LocationService service) {
    _locationService = service;
  }

  void registerHttpService(HttpService service) {
    _httpService = service;
  }

  void reset() {
    _locationService = GeolocatorLocationService();
    _httpService = RealHttpService();
  }
}

final locator = ServiceLocator();

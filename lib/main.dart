import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_randomcolor/flutter_randomcolor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pastel Gradient Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const GradientGeneratorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GradientGeneratorPage extends StatefulWidget {
  const GradientGeneratorPage({Key? key}) : super(key: key);

  @override
  _GradientGeneratorPageState createState() => _GradientGeneratorPageState();
}

class _GradientGeneratorPageState extends State<GradientGeneratorPage> {
  late Timer _timer;
  List<Color> _currentGradientColors = [];
  String _currentTime = '';
  String _currentDate = '';
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateNewGradient();
    _updateTime();
    _fetchWeatherData();
    
    // Update time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
    
    // Change gradient every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (timer) {
      _generateNewGradient();
    });
    
    // Update weather every 30 minutes
    Timer.periodic(const Duration(minutes: 30), (timer) {
      _fetchWeatherData();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(now);
      _currentDate = DateFormat('EEEE, MMMM d, y').format(now);
    });
  }

  void _generateNewGradient() {
    setState(() {
      _currentGradientColors = List.generate(
        3,
        (_) => RandomColor.getColorObject(Options(
          luminosity: Luminosity.light,
          colorType: [
            ColorType.pink, 
            ColorType.purple, 
            ColorType.blue, 
            ColorType.green,
            ColorType.yellow
          ][math.Random().nextInt(5)],
        )),
      );
    });
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Using OpenMeteo API for weather data
      final response = await http.get(Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=37.7749&longitude=-122.4194&current=temperature_2m,weather_code,wind_speed_10m&hourly=temperature_2m&daily=temperature_2m_max,temperature_2m_min&timezone=auto'
      ));
      
      if (response.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getWeatherDescription(int weatherCode) {
    // WMO Weather interpretation codes
    if (weatherCode <= 3) return 'Clear to Partly Cloudy';
    if (weatherCode <= 49) return 'Foggy';
    if (weatherCode <= 59) return 'Drizzle';
    if (weatherCode <= 69) return 'Rain';
    if (weatherCode <= 79) return 'Snow';
    if (weatherCode <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _currentGradientColors.isEmpty 
                ? [Colors.pink.shade100, Colors.blue.shade100] 
                : _currentGradientColors,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clock Display
                Text(
                  _currentTime,
                  style: TextStyle(
                    fontSize: screenWidth * 0.15, // 15% of screen width
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black26,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                Text(
                  _currentDate,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045, // 4.5% of screen width
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black26,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.05), // 5% of screen height
                
                // Weather Display
                _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _weatherData != null
                    ? _buildWeatherInfo(screenWidth, screenHeight)
                    : Text(
                        'Weather data unavailable',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04, // 4% of screen width
                          color: Colors.white,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(double screenWidth, double screenHeight) {
    final currentWeather = _weatherData?['current'];
    if (currentWeather == null) {
      return Text(
        'No weather data',
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          color: Colors.white,
        ),
      );
    }
    
    final temp = currentWeather['temperature_2m'];
    final weatherCode = currentWeather['weather_code'];
    final windSpeed = currentWeather['wind_speed_10m'];
    final weatherDescription = _getWeatherDescription(weatherCode);
    
    // Calculate responsive sizes
    final containerSize = screenWidth * 0.4; // 40% of screen width
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05), // 5% of screen width
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$temp°C',
            style: TextStyle(
              fontSize: screenWidth * 0.09, // 9% of screen width
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenHeight * 0.01), // 1% of screen height
          Text(
            weatherDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.035, // 3.5% of screen width
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenHeight * 0.005), // 0.5% of screen height
          Text(
            'Wind: $windSpeed km/h',
            style: TextStyle(
              fontSize: screenWidth * 0.025, // 2.5% of screen width
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
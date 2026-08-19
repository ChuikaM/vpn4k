import 'package:flutter/material.dart';
import 'mainapp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initTray();
  
  runApp(const MainApp());
}
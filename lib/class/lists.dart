import 'package:flutter/material.dart';
import 'package:tcg_app/class/home.dart';
import 'package:tcg_app/class/meta.dart';
import 'package:tcg_app/class/profile.dart';
import 'package:tcg_app/class/search.dart';

List<NavigationDestination> iconList = [
  NavigationDestination(icon: Icon(Icons.home), label: "home"),
  NavigationDestination(icon: Icon(Icons.search), label: "search"),
  NavigationDestination(icon: Icon(Icons.person), label: "profile"),
  NavigationDestination(icon: Icon(Icons.local_fire_department), label: "Meta"),
];
List<Widget> widgetListe = [Home(), Search(), Profile(), Meta()];

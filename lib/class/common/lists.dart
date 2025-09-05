import 'dart:math';

import 'package:flutter/material.dart';

final _rng = Random();

List<String> cardTypes = ["monster", "spell", "trap"];

List<NavigationDestination> iconList = [
  NavigationDestination(icon: Icon(Icons.home), label: "home"),
  NavigationDestination(icon: Icon(Icons.search), label: "search"),
  NavigationDestination(icon: Icon(Icons.person), label: "profile"),
  NavigationDestination(icon: Icon(Icons.local_fire_department), label: "Meta"),
];

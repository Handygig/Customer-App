import 'package:flutter/material.dart';

class FallbackLocalizations {
  // ignore: non_constant_identifier_names
  String get no_internet_message => 'No Internet Connection';
  String get unAuthorizedError => 'Unauthorized access. Please log in again.';
}

extension LocalizedBuildContext on BuildContext {
  FallbackLocalizations get loc => FallbackLocalizations();
}
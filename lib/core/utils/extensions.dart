import 'package:flutter/material.dart';

class FallbackLocalizations {
  String get no_internet_message => 'No Internet Connection';
  String get unAuthorizedError => 'Unauthorized access. Please log in again.';
}

extension LocalizedBuildContext on BuildContext {
  FallbackLocalizations get loc => FallbackLocalizations();
}

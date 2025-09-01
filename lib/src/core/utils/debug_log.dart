import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

var logger = Logger();

void debugLog(String message, {String color = whitecolorlog}) {
  if (kDebugMode) {
    log('$color$message$resetcolorlog');
  }
}

void errorLog(String message, {String color = redcolorlog}) {
  if (kDebugMode) logger.e('$color$message$resetcolorlog');
}

void detailLog(String message, {String color = whitecolorlog}) {
  if (kDebugMode) logger.i('$color$message$resetcolorlog');
}

const redcolorlog = '\x1B[31m'; // Red
const greencolorlog = '\x1B[32m'; // Green
const yellowcolorlog = '\x1B[33m'; // Yellow
const bluecolorlog = '\x1B[34m'; // Blue
const magentacolorlog = '\x1B[35m'; // Magenta
const orangecolorlog = '\x1B[38;5;208m'; // Orange
const cyancolorlog = '\x1B[36m'; // Cyan
const whitecolorlog = '\x1B[37m'; // White
const brightblackcolorlog = '\x1B[90m'; // Bright Black
const resetcolorlog = '\x1B[0m'; // Reset color

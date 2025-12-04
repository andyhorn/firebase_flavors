import 'package:test/test.dart';

import '../../bin/src/utils/gradle_parser.dart';

void main() {
  group('GradleParser.extractApplicationId', () {
    test('extracts applicationId from defaultConfig with equals', () {
      const gradleContent = '''
android {
    defaultConfig {
        applicationId = "com.example.app"
    }
}
''';

      final result = GradleParser.extractApplicationId(gradleContent);

      expect(result, equals('com.example.app'));
    });

    test('extracts namespace when applicationId not found', () {
      const gradleContent = '''
android {
    namespace = "com.example.app"
}
''';

      final result = GradleParser.extractApplicationId(gradleContent);

      expect(result, equals('com.example.app'));
    });

    test('prefers applicationId over namespace', () {
      const gradleContent = '''
android {
    namespace = "com.example.namespace"
    defaultConfig {
        applicationId = "com.example.app"
    }
}
''';

      final result = GradleParser.extractApplicationId(gradleContent);

      expect(result, equals('com.example.app'));
    });

    test('returns null when neither found', () {
      const gradleContent = '''
android {
    compileSdkVersion = 33
}
''';

      final result = GradleParser.extractApplicationId(gradleContent);

      expect(result, isNull);
    });

    test('handles single quotes', () {
      const gradleContent = '''
android {
    defaultConfig {
        applicationId = 'com.example.app'
    }
}
''';

      final result = GradleParser.extractApplicationId(gradleContent);

      expect(result, equals('com.example.app'));
    });
  });

  group('GradleParser.extractProductFlavors', () {
    test('extracts flavors from Kotlin DSL', () {
      const gradleContent = '''
android {
    productFlavors {
        create("dev") {
            applicationIdSuffix = ".dev"
        }
        create("staging") {
            applicationIdSuffix = ".stg"
        }
        create("prod") {
        }
    }
}
''';

      final result = GradleParser.extractProductFlavors(gradleContent, true);

      expect(result, hasLength(3));
      expect(result['dev'], equals('dev')); // dot stripped
      expect(result['staging'], equals('stg')); // dot stripped
      expect(result['prod'], equals(''));
    });

    test('handles flavors without suffix in Kotlin DSL', () {
      const gradleContent = '''
android {
    productFlavors {
        create("dev") {
        }
        create("prod") {
        }
    }
}
''';

      final result = GradleParser.extractProductFlavors(gradleContent, true);

      expect(result, hasLength(2));
      expect(result['dev'], equals(''));
      expect(result['prod'], equals(''));
    });

    test('handles suffix without leading dot in Kotlin DSL', () {
      const gradleContent = '''
android {
    productFlavors {
        create("dev") {
            applicationIdSuffix = "dev"
        }
    }
}
''';

      final result = GradleParser.extractProductFlavors(gradleContent, true);

      expect(result, hasLength(1));
      expect(result['dev'], equals('dev'));
    });

    test('returns empty map when no productFlavors block', () {
      const gradleContent = '''
android {
    compileSdkVersion = 33
}
''';

      final result = GradleParser.extractProductFlavors(gradleContent, false);

      expect(result, isEmpty);
    });

    test('strips leading dot from suffix', () {
      const gradleContent = '''
android {
    productFlavors {
        create("dev") {
            applicationIdSuffix = ".dev"
        }
    }
}
''';

      final result = GradleParser.extractProductFlavors(gradleContent, true);

      expect(result['dev'], equals('dev')); // dot is stripped
    });
  });

  group('GradleParser.extractAppName', () {
    test('extracts app name from manifestPlaceholders (Kotlin DSL)', () {
      const gradleContent = '''
android {
    defaultConfig {
        manifestPlaceholders["appName"] = "My App"
    }
}
''';

      final result = GradleParser.extractAppName(gradleContent);

      expect(result, equals('My App'));
    });

    test('handles single quotes', () {
      const gradleContent = '''
android {
    defaultConfig {
        manifestPlaceholders["appName"] = 'My App'
    }
}
''';

      final result = GradleParser.extractAppName(gradleContent);

      expect(result, equals('My App'));
    });

    test('returns null when appName not found', () {
      const gradleContent = '''
android {
    defaultConfig {
        applicationId = "com.example.app"
    }
}
''';

      final result = GradleParser.extractAppName(gradleContent);

      expect(result, isNull);
    });
  });
}

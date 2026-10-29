// File: lib/core/logging/storage/log_storage_provider.dart
// Purpose: Conditional export provider for cross-platform LogStorage implementation.

import 'log_storage.dart';
import 'log_storage_stub.dart'
    if (dart.library.io) 'log_storage_io.dart'
    if (dart.library.js_interop) 'log_storage_web.dart';

export 'log_storage.dart';

/// Factory providing platform-appropriate persistent log storage
LogStorage createLogStorage() => createPlatformLogStorage();

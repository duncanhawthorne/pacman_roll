import 'package:flutter/foundation.dart';

import 'google_user.dart';
import 'secrets.dart';

final bool _gOn =
    googleOnReal &&
    !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);

final String _gId = gID;

final G g = G(gOn: _gOn, clientId: _gId);

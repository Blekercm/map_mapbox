import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image/network.dart';
import 'package:map_mapbox/map_mapbox.dart';
import 'package:map_mapbox/src/core/util.dart' as util;

export 'package:map_mapbox/src/layer/tile_provider/mbtiles_image_provider.dart';

abstract class TileProvider {
  const TileProvider();

  ImageProvider getImage(Coords coords, TileLayerOptions options);

  void dispose() {}

  String getTileUrl(Coords coords, TileLayerOptions options) {
    var data = <String, String>{
      'x': coords.x.round().toString(),
      'y': coords.y.round().toString(),
      'z': coords.z.round().toString(),
      's': getSubdomain(coords, options)
    };
    if (options.tms) {
      data['y'] = invertY(coords.y.round(), coords.z.round()).toString();
    }
    var allOpts = Map<String, String>.from(data)
      ..addAll(options.additionalOptions);
    return util.template(options.urlTemplate, allOpts);
  }

  int invertY(int y, int z) {
    return ((1 << z) - 1) - y;
  }

  String getSubdomain(Coords coords, TileLayerOptions options) {
    if (options.subdomains.isEmpty) {
      return '';
    }
    var index = (coords.x + coords.y).round() % options.subdomains.length;
    return options.subdomains[index];
  }
}

class CachedNetworkTileProvider extends TileProvider {
  const CachedNetworkTileProvider();

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return CachedNetworkImageProvider(getTileUrl(coords, options));
  }
}

class NetworkTileProvider extends TileProvider {
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return NetworkImageWithRetry(getTileUrl(coords, options));
  }
}

class NonCachingNetworkTileProvider extends TileProvider {
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return NetworkImage(getTileUrl(coords, options));
  }
}

class AssetTileProvider extends TileProvider {
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return AssetImage(getTileUrl(coords, options));
  }
}

class FileTileProvider extends TileProvider {
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return FileImage(File(getTileUrl(coords, options)));
  }
}

class CustomTileProvider extends TileProvider {
  String Function(Coords coors, TileLayerOptions options) customTileUrl;

  CustomTileProvider({@required this.customTileUrl});

  @override
  String getTileUrl(Coords coords, TileLayerOptions options) {
    return customTileUrl(coords, options);
  }

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return AssetImage(getTileUrl(coords, options));
  }
}

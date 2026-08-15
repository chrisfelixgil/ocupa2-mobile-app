import 'package:flutter/material.dart';

import '../../data/models/educational_video.dart';
import 'video_card.dart';

class VideosSection extends StatelessWidget {
  final List<EducationalVideo> videos;

  const VideosSection({
    super.key,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        child: Center(
          child: Text(
            'No hay videos educativos disponibles.',
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Column(
        children: videos.map((video) {
          return VideoCard(
            video: video,
          );
        }).toList(),
      ),
    );
  }
}

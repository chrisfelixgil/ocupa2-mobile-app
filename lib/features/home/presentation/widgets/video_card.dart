import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/educational_video.dart';

class VideoCard extends StatelessWidget {
  final EducationalVideo video;

  const VideoCard({
    super.key,
    required this.video,
  });

  Future<void> _openVideo() async {
    if (video.url.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(video.url);

    if (uri == null) {
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openVideo,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (video.thumbnail.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: video.thumbnail,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (
                      context,
                      url,
                    ) {
                      return const SizedBox(
                        height: 190,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorWidget: (
                      context,
                      url,
                      error,
                    ) {
                      return Container(
                        height: 190,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.video_library_outlined,
                          size: 50,
                        ),
                      );
                    },
                  )
                else
                  Container(
                    height: 190,
                    color: Colors.grey.shade200,
                  ),

                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.65,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  if (video.description.isNotEmpty) ...[
                    const SizedBox(height: 8),

                    Text(
                      video.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color:
                            Theme.of(context).colorScheme.primary,
                      ),

                      const SizedBox(width: 7),

                      Text(
                        'Ver video',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/news.dart';

class NewsCard extends StatelessWidget {
  final News news;

  const NewsCard({
    super.key,
    required this.news,
  });

  Future<void> _openNews() async {
    if (news.url.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(news.url);

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
        onTap: _openNews,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.image.isNotEmpty)
              CachedNetworkImage(
                imageUrl: news.image,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (
                  context,
                  url,
                ) {
                  return const SizedBox(
                    height: 180,
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
                    height: 180,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 45,
                    ),
                  );
                },
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  if (news.summary.isNotEmpty) ...[
                    const SizedBox(height: 8),

                    Text(
                      news.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.public,
                        size: 16,
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          news.source.isEmpty
                              ? 'Fuente externa'
                              : news.source,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ),

                      if (news.url.isNotEmpty)
                        const Icon(
                          Icons.open_in_new,
                          size: 18,
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

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late int _current;
  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.imageUrls.length > 1
            ? Text('${_current + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 15))
            : null,
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageCtrl,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _current = i),
        builder: (_, i) => PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(widget.imageUrls[i]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          heroAttributes: PhotoViewHeroAttributes(tag: widget.imageUrls[i]),
        ),
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (_, __) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2),
        ),
      ),
    );
  }
}

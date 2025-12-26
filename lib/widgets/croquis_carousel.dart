import 'package:flutter/material.dart';

class CroquisCarousel extends StatefulWidget {
  final List<String> urls;

  const CroquisCarousel({super.key, required this.urls});

  @override
  State<CroquisCarousel> createState() => _CroquisCarouselState();
}

class _CroquisCarouselState extends State<CroquisCarousel> {
  final PageController _controller = PageController();
  int index = 0;

  void _prev() {
    if (index > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _next() {
    if (index < widget.urls.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text("No hay croquis disponibles")),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.urls.length,
                onPageChanged: (i) => setState(() => index = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.urls[i],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Text("Error al cargar imagen")),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, size: 42),
                  onPressed: _prev,
                ),
              ),

              Positioned(
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, size: 42),
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.urls.length,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == index ? Colors.blue : Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

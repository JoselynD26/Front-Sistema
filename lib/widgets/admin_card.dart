import 'package:flutter/material.dart';

class AdminCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const AdminCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  State<AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<AdminCard> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary; 
    final orangeAccent = theme.colorScheme.tertiary; 

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovering = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovering 
                          ? primaryColor.withOpacity(0.15) 
                          : Colors.black.withOpacity(0.04),
                      blurRadius: _isHovering ? 20 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  // Subtle border, Blue on hover
                  border: Border.all(
                    color: _isHovering ? primaryColor.withOpacity(0.5) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Background circle also reacts gently
                            color: _isHovering ? orangeAccent.withOpacity(0.05) : primaryColor.withOpacity(0.03),
                          ),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
                             // ICON: Switches from Blue Gradient to Orange Gradient on Hover
                            Center(
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: _isHovering 
          ? [orangeAccent, Colors.orangeAccent]
          : [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: (_isHovering ? orangeAccent : primaryColor).withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Icon(
      widget.icon,
      size: 28,
      color: Colors.white,
    ),
  ),
),
                             const SizedBox(height: 12),
                             // Title
                             Flexible(
                               child: Text(
                                 widget.title,
                                 textAlign: TextAlign.center,
                                 maxLines: 2,
                                 overflow: TextOverflow.ellipsis,
                                 style: TextStyle(
                                   fontSize: 16, // Adjusted font size
                                   fontWeight: FontWeight.bold,
                                   color: secondaryColor, // Dark Blue ("Azul más oscuro" requested)
                                   letterSpacing: -0.3,
                                   height: 1.1,
                                 ),
                               ),
                             ),
                             if (widget.subtitle != null) ...[
                               const SizedBox(height: 6),
                               // Subtitle
                               Flexible(
                                 child: Text(
                                   widget.subtitle!,
                                   textAlign: TextAlign.center,
                                   maxLines: 2,
                                   overflow: TextOverflow.ellipsis,
                                   style: TextStyle(
                                     fontSize: 12,
                                     color: secondaryColor.withOpacity(0.7), // Lighter version of Dark Blue
                                     height: 1.2,
                                     fontWeight: FontWeight.w500,
                                   ),
                                 ),
                               ),
                             ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

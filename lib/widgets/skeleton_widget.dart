import 'package:flutter/material.dart';

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.3 + (_controller.value * 0.4);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

class SkeletonProductGrid extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;

  const SkeletonProductGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.88,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: const SkeletonBox(height: 80),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonBox(height: 14, width: 100),
          ),
          const SizedBox(height: 8),
          const SkeletonBox(height: 10, width: 80),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class SkeletonCartPanel extends StatelessWidget {
  const SkeletonCartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final cartWidth = (MediaQuery.of(context).size.width * 0.45).clamp(320.0, 435.0);
    return Container(
      width: cartWidth,
      color: Colors.white.withValues(alpha: 0.90),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SkeletonBox(width: 32, height: 34, borderRadius: 10),
                SizedBox(width: 10),
                SkeletonBox(width: 150, height: 20),
              ],
            ),
          ),
          const Divider(),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox(width: 180, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 120, height: 12),
              ],
            ),
          ),
          const Divider(),
          Container(
            height: 90,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            child: const SkeletonBox(height: 90, borderRadius: 24),
          ),
        ],
      ),
    );
  }
}

class SkeletonHistoryList extends StatelessWidget {
  const SkeletonHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SkeletonBox(width: 36, height: 36, borderRadius: 10),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 80, height: 14),
                    SizedBox(height: 6),
                    SkeletonBox(width: 120, height: 10),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SkeletonBox(width: 100, height: 14),
                  SizedBox(height: 4),
                  SkeletonBox(width: 60, height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

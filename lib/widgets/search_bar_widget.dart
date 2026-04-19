import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFavoritePressed;
  final bool isFavoriteActive;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFavoritePressed,
    this.isFavoriteActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search books or authors...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          if (onFavoritePressed != null) ...[
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(isFavoriteActive ? Icons.favorite : Icons.favorite_border, color: Colors.red),
              onPressed: onFavoritePressed,
            ),
          ],
        ],
      ),
    );
  }
}

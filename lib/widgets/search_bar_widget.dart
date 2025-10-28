import 'package:flutter/material.dart';
import '../utils/debouncer.dart';

/// Search bar widget with built-in debouncing (300ms) to reduce provider
/// notifications during typing. This prevents rapid rebuilds and improves
/// UI responsiveness when filtering large task lists.
class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  bool _isTyping = false;

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _handleSearchChange(String query) {
    setState(() => _isTyping = true);
    
    _debouncer.run(() {
      widget.onChanged(query);
      if (mounted) {
        setState(() => _isTyping = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search tasks...',
        border: InputBorder.none,
        suffixIcon: SizedBox(
          width: _isTyping ? 72 : 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isTyping)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (_isTyping) const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _debouncer.cancel();
                  setState(() => _isTyping = false);
                  widget.onClear();
                },
              ),
            ],
          ),
        ),
      ),
      style: Theme.of(context).textTheme.titleLarge,
      onChanged: _handleSearchChange,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

/// A custom expansion tile widget that supports group selection and removal.
/// Used for organizing and managing object groups in the picker interface.
class CustomExpansionTile extends StatefulWidget {
  final List<Widget> children;
  final VoidCallback onRemove;
  final bool initiallyExpanded;
  final String groupId;
  final ValueChanged<String> onGroupSelected;
  final String? selectedGroup;

  const CustomExpansionTile({
    Key? key,
    required this.children,
    required this.onRemove,
    required this.groupId,
    required this.onGroupSelected,
    this.selectedGroup,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  _CustomExpansionTileState createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _iconTurns;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = _animationController.drive(
      Tween<double>(
        begin: 0.0,
        end: 0.5,
      ).chain(CurveTween(curve: Curves.easeIn)),
    );
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleTap() {
    widget.onGroupSelected(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.selectedGroup == widget.groupId;

    return Container(
      decoration: BoxDecoration(
        border:
            isSelected
                ? Border.all(color: Pallete.gradient1, width: 3.0)
                : Border.all(color: Pallete.transparentColor),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.groupId),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Pallete.errorColor,
                  ),
                  onPressed: widget.onRemove,
                ),
                RotationTransition(
                  turns: _iconTurns,
                  child: IconButton(
                    icon: const Icon(Icons.expand_more),
                    onPressed: _toggleExpansion,
                  ),
                ),
              ],
            ),
            onTap: () {
              _handleTap();
              _toggleExpansion();
            },
          ),
          ClipRect(
            child: Align(
              heightFactor: _isExpanded ? 1.0 : 0.0,
              child: Column(children: widget.children),
            ),
          ),
        ],
      ),
    );
  }
}

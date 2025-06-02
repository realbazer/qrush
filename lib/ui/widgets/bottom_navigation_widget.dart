import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomNavigationButtons extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavigationButtons({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: (MediaQuery.of(context).size.width / 4) - 60,
      right: (MediaQuery.of(context).size.width / 4) - 60,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white30),
            boxShadow: [BoxShadow(color: Colors.black, blurRadius: 10)],
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavigationIconButton(
                isSelected: selectedIndex == 0,
                iconData: CupertinoIcons.qrcode_viewfinder,
                onTap: () => onItemTapped(0),
              ),
              _NavigationIconButton(
                isSelected: selectedIndex == 1,
                iconData: CupertinoIcons.qrcode,
                onTap: () => onItemTapped(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationIconButton extends StatelessWidget {
  final bool isSelected;
  final IconData iconData;
  final VoidCallback onTap;

  const _NavigationIconButton({
    required this.isSelected,
    required this.iconData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white30),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(
            iconData,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}

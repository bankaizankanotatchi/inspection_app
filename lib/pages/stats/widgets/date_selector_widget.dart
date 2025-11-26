import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';

class DateSelectorWidget extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final DateTime firstDate;
  final DateTime lastDate;

  const DateSelectorWidget({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    required this.firstDate,
    required this.lastDate,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: firstDate,
          lastDate: lastDate,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppTheme.primaryBlue,
                  onPrimary: Colors.white,
                  onSurface: AppTheme.darkBlue,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedDate != null ? AppTheme.primaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: selectedDate != null ? AppTheme.primaryBlue : Colors.grey,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    selectedDate != null ? _formatDate(selectedDate!) : 'Non sélectionnée',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                      color: selectedDate != null ? AppTheme.darkBlue : Colors.grey,
                    ),
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
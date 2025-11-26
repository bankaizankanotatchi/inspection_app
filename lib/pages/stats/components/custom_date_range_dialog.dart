import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/stats/widgets/date_selector_widget.dart';

class CustomDateRangeDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime, DateTime) onDateRangeApplied;

  const CustomDateRangeDialog({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    required this.onDateRangeApplied,
  });

  @override
  State<CustomDateRangeDialog> createState() => _CustomDateRangeDialogState();
}

class _CustomDateRangeDialogState extends State<CustomDateRangeDialog> {
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  @override
  void initState() {
    super.initState();
    _tempStartDate = widget.initialStartDate;
    _tempEndDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(Icons.date_range, color: AppTheme.primaryBlue),
          SizedBox(width: 8),
          Text('Période personnalisée', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DateSelectorWidget(
              label: 'Date de début',
              selectedDate: _tempStartDate,
              onDateSelected: (date) {
                setState(() {
                  _tempStartDate = date;
                });
              },
              firstDate: DateTime(2020),
              lastDate: _tempEndDate ?? DateTime.now(),
            ),
            SizedBox(height: 16),
            DateSelectorWidget(
              label: 'Date de fin',
              selectedDate: _tempEndDate,
              onDateSelected: (date) {
                setState(() {
                  _tempEndDate = date;
                });
              },
              firstDate: _tempStartDate ?? DateTime(2020),
              lastDate: DateTime.now(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Annuler', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _tempStartDate != null && _tempEndDate != null
              ? () {
                  if (_tempStartDate!.isAfter(_tempEndDate!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('La date de début doit être avant la date de fin'),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.of(context).pop();
                  widget.onDateRangeApplied(_tempStartDate!, _tempEndDate!);
                }
              : null,
          child: Text('Appliquer'),
        ),
      ],
    );
  }
}
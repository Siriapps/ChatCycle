import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';

class FilterPanel extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final Function(DateTime?, DateTime?) onApply;
  final VoidCallback onReset;

  const FilterPanel({
    super.key,
    this.fromDate,
    this.toDate,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  DateTime? _fromDate;
  DateTime? _toDate;
  int _activeFilters = 0;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.fromDate;
    _toDate = widget.toDate;
    _updateActiveFilters();
  }

  void _updateActiveFilters() {
    int count = 0;
    if (_fromDate != null) count++;
    if (_toDate != null) count++;
    setState(() {
      _activeFilters = count;
    });
  }

  Future<void> _selectDate(bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_fromDate ?? DateTime.now()) : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
        _updateActiveFilters();
      });
    }
  }

  void _applyQuickFilter(String type) {
    final now = DateTime.now();
    setState(() {
      switch (type) {
        case 'Today':
          _fromDate = DateTime(now.year, now.month, now.day);
          _toDate = null;
          break;
        case 'This Week':
          _fromDate = now.subtract(Duration(days: now.weekday - 1));
          _toDate = null;
          break;
        case 'This Month':
          _fromDate = DateTime(now.year, now.month, 1);
          _toDate = null;
          break;
      }
      _updateActiveFilters();
    });
  }

  void _handleReset() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _updateActiveFilters();
    });
    widget.onReset();
  }

  void _handleApply() {
    widget.onApply(_fromDate, _toDate);
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 5,
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Text(
                  "Filter by:",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_activeFilters > 0)
                  GestureDetector(
                    onTap: _handleReset,
                    child: Text(
                      "Reset",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.purple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 15),

            Text(
              "Date Range",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _fromDate != null ? _formatDate(_fromDate) : "From",
                            style: GoogleFonts.inter(
                              color: _fromDate != null ? Colors.black : AppColors.grey,
                            ),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _toDate != null ? _formatDate(_toDate) : "To",
                            style: GoogleFonts.inter(
                              color: _toDate != null ? Colors.black : AppColors.grey,
                            ),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                _chip("Today", () => _applyQuickFilter('Today')),
                const SizedBox(width: 8),
                _chip("This Week", () => _applyQuickFilter('This Week')),
                const SizedBox(width: 8),
                _chip("This Month", () => _applyQuickFilter('This Month')),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: _button("Reset All", Colors.white, AppColors.purple, _handleReset),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _button(
                    _activeFilters > 0 ? "Apply Filters($_activeFilters)" : "Apply Filters",
                    AppColors.purple,
                    Colors.white,
                    _handleApply,
                  ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 13),
        ),
      ),
    );
  }

  Widget _button(String text, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.purple),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

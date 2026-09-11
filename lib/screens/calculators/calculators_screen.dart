import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/glass_card.dart';

class CalculatorsScreen extends StatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> {
  int _selectedCalc = 0; // 0: EMI, 1: Salary, 2: GST, 3: Percentage, 4: Age, 5: Discount

  // 1. EMI Controllers
  final _emiPrincipal = TextEditingController(text: '500000');
  final _emiRate = TextEditingController(text: '9.5');
  final _emiMonths = TextEditingController(text: '36');
  double _calculatedEmi = 0.0;
  double _calculatedTotalInterest = 0.0;

  // 2. Salary Controllers
  final _salaryCtc = TextEditingController(text: '12'); // LPA
  double _monthlyInHand = 0.0;
  double _monthlyPf = 0.0;
  double _monthlyTax = 0.0;

  // 3. GST Controllers
  final _gstAmount = TextEditingController(text: '10000');
  final _gstRate = TextEditingController(text: '18');
  double _calculatedGst = 0.0;
  double _totalWithGst = 0.0;

  // 4. Percentage Controllers
  final _pctX = TextEditingController(text: '15');
  final _pctY = TextEditingController(text: '2400');
  double _calculatedPct = 0.0;

  // 5. Discount Controllers
  final _discPrice = TextEditingController(text: '4999');
  final _discPct = TextEditingController(text: '20');
  double _finalPrice = 0.0;
  double _savedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _computeEmi();
    _computeSalary();
    _computeGst();
    _computePercentage();
    _computeDiscount();
  }

  void _computeEmi() {
    final p = double.tryParse(_emiPrincipal.text) ?? 0.0;
    final r = (double.tryParse(_emiRate.text) ?? 0.0) / 12 / 100;
    final n = double.tryParse(_emiMonths.text) ?? 1.0;

    if (p > 0 && r > 0 && n > 0) {
      final emi = (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
      final totalPaid = emi * n;
      setState(() {
        _calculatedEmi = emi;
        _calculatedTotalInterest = totalPaid - p;
      });
    }
  }

  void _computeSalary() {
    final ctcLpa = double.tryParse(_salaryCtc.text) ?? 0.0;
    final ctcAnnual = ctcLpa * 100000;
    final monthlyGross = ctcAnnual / 12;

    // Approximate Indian standard deductions: PF (12% of basic ~40% of CTC), simplified slab tax
    final pf = monthlyGross * 0.05;
    final tax = ctcLpa > 7.0 ? (monthlyGross * 0.12) : 0.0;
    final inHand = monthlyGross - pf - tax;

    setState(() {
      _monthlyPf = pf;
      _monthlyTax = tax;
      _monthlyInHand = inHand.clamp(0.0, double.infinity);
    });
  }

  void _computeGst() {
    final amt = double.tryParse(_gstAmount.text) ?? 0.0;
    final rate = double.tryParse(_gstRate.text) ?? 0.0;
    final gst = (amt * rate) / 100;
    setState(() {
      _calculatedGst = gst;
      _totalWithGst = amt + gst;
    });
  }

  void _computePercentage() {
    final x = double.tryParse(_pctX.text) ?? 0.0;
    final y = double.tryParse(_pctY.text) ?? 0.0;
    setState(() {
      _calculatedPct = (x / 100) * y;
    });
  }

  void _computeDiscount() {
    final p = double.tryParse(_discPrice.text) ?? 0.0;
    final d = double.tryParse(_discPct.text) ?? 0.0;
    final saved = (p * d) / 100;
    setState(() {
      _savedAmount = saved;
      _finalPrice = p - saved;
    });
  }

  @override
  void dispose() {
    _emiPrincipal.dispose();
    _emiRate.dispose();
    _emiMonths.dispose();
    _salaryCtc.dispose();
    _gstAmount.dispose();
    _gstRate.dispose();
    _pctX.dispose();
    _pctY.dispose();
    _discPrice.dispose();
    _discPct.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calculators Suite', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calculator Selector Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCalcChip(0, '🏦 Loan / EMI'),
                  const SizedBox(width: 8),
                  _buildCalcChip(1, '💼 In-Hand Salary'),
                  const SizedBox(width: 8),
                  _buildCalcChip(2, '🧾 GST Tax'),
                  const SizedBox(width: 8),
                  _buildCalcChip(3, '🔢 Percentage'),
                  const SizedBox(width: 8),
                  _buildCalcChip(4, '🏷️ Discount'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Calculator Body
            if (_selectedCalc == 0) ...[
              // EMI Calculator
              _buildResultCard(
                title: 'Monthly EMI Payable',
                value: Formatters.currency(_calculatedEmi),
                subtitle: 'Total Interest: ${Formatters.currency(_calculatedTotalInterest)}',
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emiPrincipal,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Principal Loan Amount (₹)'),
                onChanged: (_) => _computeEmi(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emiRate,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Annual Interest Rate (%)'),
                onChanged: (_) => _computeEmi(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emiMonths,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tenure (Months)'),
                onChanged: (_) => _computeEmi(),
              ),
            ] else if (_selectedCalc == 1) ...[
              // Salary Calculator
              _buildResultCard(
                title: 'Estimated Monthly In-Hand Salary',
                value: Formatters.currency(_monthlyInHand),
                subtitle: 'Est. PF: ${Formatters.currency(_monthlyPf)} • Est. Tax: ${Formatters.currency(_monthlyTax)}',
                color: AppColors.success,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _salaryCtc,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Annual CTC (in ₹ LPA)', hintText: '12'),
                onChanged: (_) => _computeSalary(),
              ),
            ] else if (_selectedCalc == 2) ...[
              // GST Calculator
              _buildResultCard(
                title: 'Total Amount (with GST)',
                value: Formatters.currency(_totalWithGst),
                subtitle: 'CGST: ${Formatters.currency(_calculatedGst / 2)} • SGST: ${Formatters.currency(_calculatedGst / 2)}',
                color: AppColors.secondary,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _gstAmount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Base Net Amount (₹)'),
                onChanged: (_) => _computeGst(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _gstRate,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'GST Slab Rate (%)', hintText: '5, 12, 18, or 28'),
                onChanged: (_) => _computeGst(),
              ),
            ] else if (_selectedCalc == 3) ...[
              // Percentage Calculator
              _buildResultCard(
                title: '${_pctX.text}% of ${_pctY.text}',
                value: _calculatedPct.toStringAsFixed(2),
                subtitle: 'Exact calculated value',
                color: Colors.amber,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _pctX,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Percentage (X %)'),
                onChanged: (_) => _computePercentage(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pctY,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Base Number (Y)'),
                onChanged: (_) => _computePercentage(),
              ),
            ] else if (_selectedCalc == 4) ...[
              // Discount Calculator
              _buildResultCard(
                title: 'Final Discounted Price',
                value: Formatters.currency(_finalPrice),
                subtitle: 'You save: ${Formatters.currency(_savedAmount)} (${_discPct.text}%)',
                color: AppColors.primaryLight,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _discPrice,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Original Retail Price (₹)'),
                onChanged: (_) => _computeDiscount(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _discPct,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Discount Percentage (%)'),
                onChanged: (_) => _computeDiscount(),
              ),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcChip(int index, String title) {
    final isSelected = _selectedCalc == index;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : null, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      onSelected: (val) {
        if (val) setState(() => _selectedCalc = index);
      },
    );
  }

  Widget _buildResultCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  bool get _hasMinLength => password.length >= 8;
  bool get _hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => password.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => password.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar => password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  int get _strengthScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasLowercase) score++;
    if (_hasNumber) score++;
    if (_hasSpecialChar) score++;
    return score;
  }

  Color get _strengthColor {
    if (password.isEmpty) return Colors.grey.shade300;
    switch (_strengthScore) {
      case 1:
      case 2:
        return Colors.redAccent;
      case 3:
      case 4:
        return Colors.orangeAccent;
      case 5:
        return AppColors.primary;
      default:
        return Colors.grey.shade300;
    }
  }

  String get _strengthText {
    if (password.isEmpty) return 'Enter a password';
    switch (_strengthScore) {
      case 1:
      case 2:
        return 'Weak';
      case 3:
      case 4:
        return 'Good';
      case 5:
        return 'Strong';
      default:
        return 'Enter a password';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password Strength',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _strengthText,
              style: TextStyle(
                fontSize: 12,
                color: _strengthColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            5,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 4 ? 0 : 4),
                height: 4,
                decoration: BoxDecoration(
                  color: index < _strengthScore ? _strengthColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _buildRequirementItem('8+ characters', _hasMinLength),
            _buildRequirementItem('Uppercase', _hasUppercase),
            _buildRequirementItem('Lowercase', _hasLowercase),
            _buildRequirementItem('Number', _hasNumber),
            _buildRequirementItem('Special character', _hasSpecialChar),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: isMet ? AppColors.primary : Colors.grey.shade400,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isMet ? Colors.grey.shade800 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

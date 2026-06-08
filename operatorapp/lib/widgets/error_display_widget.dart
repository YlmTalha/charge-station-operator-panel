import 'package:flutter/material.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final IconData? icon;

  const ErrorDisplayWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.retryButtonText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              _getDisplayMessage(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFD1D5DB),
                fontSize: 16,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryButtonText ?? 'Yeniden Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDisplayMessage() {
    final errorLower = error.toLowerCase();
    
    if (errorLower.contains('kullanıcı adı') || errorLower.contains('şifre')) {
      return 'Kullanıcı adı veya şifre yanlış.\nLütfen bilgilerinizi kontrol edin.';
    } else if (errorLower.contains('yetkisiz') || errorLower.contains('403')) {
      return 'Bu işlem için yetkiniz bulunmuyor.\nLütfen yöneticinize başvurun.';
    } else if (errorLower.contains('sunucu hatası') || errorLower.contains('500')) {
      return 'Sunucu hatası oluştu.\nLütfen daha sonra tekrar deneyin.';
    } else if (errorLower.contains('ağ bağlantısı') || errorLower.contains('network')) {
      return 'İnternet bağlantınızı kontrol edin.\nLütfen tekrar deneyin.';
    } else if (errorLower.contains('endpoint') || errorLower.contains('404')) {
      return 'Servis geçici olarak kullanılamıyor.\nLütfen daha sonra tekrar deneyin.';
    } else if (errorLower.contains('timeout')) {
      return 'İstek zaman aşımına uğradı.\nLütfen tekrar deneyin.';
    } else {
      return 'Bir hata oluştu.\nLütfen tekrar deneyin.';
    }
  }
}
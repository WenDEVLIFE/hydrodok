import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // Use userEmail for the 'username' (your gmail address)
  // Use an App Password (not your main log in password) for 'password'
  // Generate App Password here: https://myaccount.google.com/apppasswords
  // IMPORTANT: Do NOT commit your real password to version control.
  static const String _gmailUsername = 'trainradar2026@gmail.com';
  static const String _gmailAppPassword = 'ilhc ktsv befy zoun';

  final SmtpServer _smtpServer = gmail(_gmailUsername, _gmailAppPassword);

  Future<void> sendOtp(String recipientEmail, String otp) async {
    final message = Message()
      ..from = Address(_gmailUsername, 'Hydrodok Register Verification')
      ..recipients.add(recipientEmail)
      ..subject = 'Hydrodok Register Verification Code'
      ..text =
          'Your verification code is: $otp\n\nThis code will expire in 10 minutes.'
      ..html =
      '''
        <h1>Verification Code</h1>
        <p>Your verification code is: <strong>$otp</strong></p>
        <p>This code will expire in 10 minutes.</p>
        <p>If you did not request this code, please ignore this email.</p>
      ''';

    try {
      final sendReport = await send(message, _smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent.');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      throw 'Failed to send OTP email: ${e.toString()}';
    }
  }
}
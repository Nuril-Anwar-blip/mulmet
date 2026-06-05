import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

const dartDefineSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const dartDefineSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const supabaseUrl = dartDefineSupabaseUrl == '' ? localSupabaseUrl : dartDefineSupabaseUrl;
const supabaseAnonKey = dartDefineSupabaseAnonKey == '' ? localSupabaseAnonKey : dartDefineSupabaseAnonKey;

bool get isSupabaseConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

String? validateEmailAddress(String email) {
  final trimmedEmail = email.trim();
  final emailPattern = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
  if (!emailPattern.hasMatch(trimmedEmail)) {
    return 'Masukkan format email yang benar.';
  }
  if (trimmedEmail.toLowerCase().endsWith('@email.com')) {
    return 'Gunakan email aktif, contoh: nama@gmail.com atau nama@outlook.com.';
  }
  return null;
}

String readableAuthError(AuthException error) {
  final message = error.message.toLowerCase();
  if (message.contains('rate limit')) {
    return 'Batas pengiriman email Supabase tercapai. Tunggu beberapa menit atau matikan Confirm email di Supabase untuk mode demo.';
  }
  if (message.contains('invalid login')) {
    return 'Email atau password salah. Pastikan akun sudah terdaftar.';
  }
  if (message.contains('email not confirmed')) {
    return 'Email belum dikonfirmasi. Cek inbox, atau matikan Confirm email di Supabase untuk demo.';
  }
  if (message.contains('already registered') || message.contains('already exists')) {
    return 'Email ini sudah terdaftar. Silakan langsung login.';
  }
  if (message.contains('invalid')) {
    return 'Data akun belum valid. Gunakan email aktif dan password minimal 8 karakter.';
  }
  return error.message;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isSupabaseConfigured) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  runApp(const BankMandiriApp());
}

class BankMandiriApp extends StatelessWidget {
  const BankMandiriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bank Mandiri',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          primary: AppColors.navy,
          surface: AppColors.surface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.input,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class AppColors {
  static const navy = Color(0xFF001F3F);
  static const blue = Color(0xFF0D4D7C);
  static const background = Color(0xFFF6F8FB);
  static const surface = Colors.white;
  static const input = Color(0xFFF0F3F7);
  static const muted = Color(0xFF7D8792);
  static const success = Color(0xFF11A66A);
  static const warning = Color(0xFFFFA529);
  static const danger = Color(0xFFE33F3F);
}

class AppData {
  static const balance = 'Rp 12.450.000';
  static const userName = 'Aditya Pratama';
  static const account = '123 - **** 8829';

  static const favorites = [
    FavoriteContact('Siska', 'Mandiri', '1234567890', 'SP'),
    FavoriteContact('Ahmad', 'BCA', '9087123412', 'AM'),
    FavoriteContact('Rian', 'BRI', '7712009945', 'RN'),
  ];

  static const banks = [
    'Bank Mandiri',
    'Bank Central Asia',
    'Bank Rakyat Indonesia',
    'BNI',
    'Bank BCA Syariah',
    'Bank Bengkulu',
    'Bank BTN',
    'Citibank N.A.',
    'Commonwealth Bank',
    'Danamon',
  ];

  static const transactions = [
    BankTransaction('Transfer Keluar', '12 Mei - 14:20', '-Rp 1.250.000', true, Icons.swap_horiz),
    BankTransaction('Pembayaran QRIS', '10 Mei - 19:46', 'Rp 45.000', true, Icons.qr_code_2),
    BankTransaction('Transfer Masuk', '08 Mei - 09:12', '+Rp 5.000.000', true, Icons.call_received),
    BankTransaction('Pembayaran PLN', '28 Apr - 21:00', 'Rp 342.500', false, Icons.bolt),
  ];
}

class FavoriteContact {
  const FavoriteContact(this.name, this.bank, this.accountNumber, this.initials);
  final String name;
  final String bank;
  final String accountNumber;
  final String initials;
}

class BankTransaction {
  const BankTransaction(this.title, this.date, this.amount, this.success, this.icon);
  final String title;
  final String date;
  final String amount;
  final bool success;
  final IconData icon;
}

class AuthService {
  const AuthService();

  Future<void> signIn({required String email, required String password}) async {
    if (!isSupabaseConfigured) {
      throw const AuthException('Supabase belum dikonfigurasi. Isi lib/supabase_config.dart atau jalankan dengan --dart-define.');
    }
    await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    if (!isSupabaseConfigured) {
      throw const AuthException('Supabase belum dikonfigurasi. Isi lib/supabase_config.dart atau jalankan dengan --dart-define.');
    }
    return Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'phone': phone},
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = const AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email dan password wajib diisi.');
      return;
    }
    final emailError = validateEmailAddress(email);
    if (emailError != null) {
      _showMessage(emailError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signIn(email: email, password: password);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on AuthException catch (error) {
      _showMessage(readableAuthError(error));
    } catch (_) {
      _showMessage('Login gagal. Periksa koneksi dan data akun.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const SizedBox(height: 28),
          const BrandPill(),
          const SizedBox(height: 18),
          Text('Selamat Datang Kembali', style: titleStyle),
          const SizedBox(height: 6),
          const Text('Kelola keuangan Anda dengan aman', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 34),
          AuthCard(
            children: [
              const FieldLabel('Email'),
              AppTextField(
                controller: _emailController,
                icon: Icons.person_outline,
                hint: 'Masukkan email Anda',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 14),
              const FieldLabel('Password'),
              AppTextField(
                controller: _passwordController,
                icon: Icons.lock_outline,
                hint: 'Masukkan password Anda',
                obscure: true,
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Switch(value: false, onChanged: (_) {}, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  const Text('Biometrik', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const Spacer(),
                  TextButton(onPressed: () {}, child: const Text('Lupa Password?', style: TextStyle(fontSize: 12))),
                ],
              ),
              PrimaryButton(
                label: _isLoading ? 'Memproses...' : 'Masuk',
                icon: Icons.arrow_forward,
                onPressed: _isLoading ? null : _signIn,
              ),
              const SizedBox(height: 24),
              const Text('Belum memiliki akun Livin?', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Buka Rekening Baru'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined, size: 14, color: AppColors.muted),
              SizedBox(width: 6),
              Text('SECURE ENCRYPTED LOGIN', style: TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: .4)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = const AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Lengkapi semua data pendaftaran.');
      return;
    }
    final emailError = validateEmailAddress(email);
    if (emailError != null) {
      _showMessage(emailError);
      return;
    }
    if (_nikController.text.trim().length != 16) {
      _showMessage('NIK harus 16 digit.');
      return;
    }
    if (password.length < 8) {
      _showMessage('Password minimal 8 karakter.');
      return;
    }
    if (password != confirmPassword) {
      _showMessage('Konfirmasi password tidak sama.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _authService.signUp(fullName: name, email: email, password: password, phone: phone);
      if (!mounted) return;
      if (response.session != null) {
        _showMessage('Rekening berhasil dibuat.');
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
        return;
      }
      _showMessage('Akun berhasil dibuat. Jika diminta, konfirmasi email lalu login.');
      Navigator.pop(context);
    } on AuthException catch (error) {
      _showMessage(readableAuthError(error));
    } catch (_) {
      _showMessage('Pendaftaran gagal. Periksa koneksi dan data akun.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTopBar(
            title: 'Bank Mandiri',
            leading: Icons.arrow_back,
            onLeading: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
          const Text('Daftar Akun Baru', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 6),
          const Text('Lengkapi data diri Anda untuk menikmati layanan perbankan digital masa depan.', style: TextStyle(color: AppColors.muted, height: 1.35)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                AuthCard(
                  children: [
                    const FieldLabel('Nama Lengkap'),
                    AppTextField(controller: _nameController, icon: Icons.person_outline, hint: 'Masukkan nama sesuai KTP'),
                    const SizedBox(height: 14),
                    const FieldLabel('NIK (No. KTP)'),
                    AppTextField(controller: _nikController, icon: Icons.badge_outlined, hint: '16 digit nomor identitas', keyboardType: TextInputType.number),
                    const SizedBox(height: 14),
                    const FieldLabel('Nomor Telepon'),
                    AppTextField(controller: _phoneController, icon: Icons.phone_android, hint: '08xx xxxx xxxx', keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    const FieldLabel('Email'),
                    AppTextField(controller: _emailController, icon: Icons.mail_outline, hint: 'contoh@email.com', keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    const FieldLabel('Buat Password'),
                    AppTextField(controller: _passwordController, icon: Icons.lock_outline, hint: 'Minimal 8 karakter', obscure: true),
                    const SizedBox(height: 14),
                    const FieldLabel('Konfirmasi Password'),
                    AppTextField(controller: _confirmPasswordController, icon: Icons.lock_reset, hint: 'Ulangi password', obscure: true),
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton(label: _isLoading ? 'Memproses...' : 'Daftar Sekarang', icon: Icons.how_to_reg, onPressed: _isLoading ? null : _signUp),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 0,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          const HeaderGreeting(),
          const SizedBox(height: 18),
          const BalanceCard(),
          const SizedBox(height: 18),
          Row(
            children: [
              QuickAction(icon: Icons.swap_horiz, label: 'Transfer', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen()))),
              QuickAction(icon: Icons.qr_code_2, label: 'QRIS', color: const Color(0xFFFFD7BE), onTap: () {}),
              QuickAction(icon: Icons.receipt_long, label: 'Tagihan', onTap: () {}),
              QuickAction(icon: Icons.grid_view, label: 'Lainnya', onTap: () {}),
            ],
          ),
          const SizedBox(height: 18),
          const PromoBanner(),
          const SizedBox(height: 22),
          SectionTitle(title: 'Transaksi Terakhir', action: 'Lihat Semua', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
          const SizedBox(height: 12),
          ...AppData.transactions.take(3).map((item) => TransactionTile(item: item)),
        ],
      ),
    );
  }
}

class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          const SimpleHeader(title: 'Transfer Dana'),
          const SizedBox(height: 20),
          const Text('Sumber Dana', style: labelStyle),
          const SizedBox(height: 8),
          const AccountSourceCard(),
          const SizedBox(height: 22),
          SectionTitle(title: 'Daftar Favorit', action: 'Lihat Semua', onTap: () {}),
          const SizedBox(height: 12),
          SizedBox(
            height: 82,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                CircleContact(name: 'Baru', icon: Icons.add, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankPickerScreen()))),
                ...AppData.favorites.map((item) => CircleContact(name: item.name, initials: item.initials, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConfirmTransferScreen(contact: item))))),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Tujuan Transfer', style: labelStyle),
          const SizedBox(height: 10),
          SelectRow(icon: Icons.account_balance, title: 'Bank Tujuan', value: 'Mandiri', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankPickerScreen()))),
          const SizedBox(height: 12),
          const FieldLabel('Nomor Rekening'),
          const AppTextField(icon: Icons.dialpad, hint: 'Masukkan nomor rekening'),
          const SizedBox(height: 14),
          const FieldLabel('Nominal'),
          const AppTextField(icon: Icons.payments_outlined, hint: 'Rp 0'),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Lanjutkan',
            icon: Icons.arrow_forward,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConfirmTransferScreen(contact: AppData.favorites.first))),
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 2,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          const SimpleHeader(title: 'Riwayat'),
          const SizedBox(height: 18),
          const AppTextField(icon: Icons.search, hint: 'Cari transaksi'),
          const SizedBox(height: 14),
          Row(
            children: [
              FilterChipWidget(label: '30 Hari Terakhir', selected: true),
              const SizedBox(width: 10),
              FilterChipWidget(label: 'Semua Jenis', selected: false),
            ],
          ),
          const SizedBox(height: 20),
          SectionTitle(title: 'Mei 2024', action: '3 Transaksi', onTap: () {}),
          const SizedBox(height: 10),
          ...AppData.transactions.take(3).map((item) => TransactionTile(item: item)),
          const SizedBox(height: 18),
          const Text('April 2024', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 10),
          TransactionTile(item: AppData.transactions.last),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 3,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          const SimpleHeader(title: 'Profil'),
          const SizedBox(height: 18),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.navy, width: 3),
                    color: const Color(0xFFDDE8F2),
                  ),
                  child: const Icon(Icons.person, size: 70, color: AppColors.blue),
                ),
                Positioned(
                  right: 2,
                  bottom: 4,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.navy,
                    child: IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Center(child: Text(AppData.userName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy))),
          const Center(child: Text('Nasabah Prioritas', style: TextStyle(color: AppColors.muted, fontSize: 12))),
          const SizedBox(height: 22),
          const FieldLabel('Alamat Email'),
          const EditableInfo(text: 'aditya.pratama@email.com'),
          const SizedBox(height: 14),
          const FieldLabel('Nomor Telepon'),
          const EditableInfo(text: '+62 812 3456 7890'),
          const SizedBox(height: 18),
          PrimaryButton(label: 'Simpan Perubahan', icon: Icons.save_outlined, onPressed: () {}),
          const SizedBox(height: 24),
          const Text('Pengaturan Akun', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 12),
          const SettingsTile(icon: Icons.password, title: 'Ubah PIN', subtitle: 'Amankan transaksi Anda'),
          const SettingsTile(icon: Icons.security, title: 'Keamanan', subtitle: 'Biometrik & perangkat'),
        ],
      ),
    );
  }
}

class BankPickerScreen extends StatelessWidget {
  const BankPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          AppTopBar(title: 'Pilih Bank Tujuan', leading: Icons.arrow_back, onLeading: () => Navigator.pop(context), trailing: Icons.help_outline),
          const SizedBox(height: 16),
          const AppTextField(icon: Icons.search, hint: 'Cari nama bank atau kode bank'),
          const SizedBox(height: 20),
          const Text('Bank Populer', style: labelStyle),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.7,
            children: ['Mandiri', 'BCA', 'BRI', 'BNI'].map((bank) => BankLogoTile(bank: bank)).toList(),
          ),
          const SizedBox(height: 22),
          const Text('Semua Bank', style: labelStyle),
          const SizedBox(height: 8),
          ...AppData.banks.map((bank) => ListOption(title: bank, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddRecipientScreen(bankName: bank))))),
        ],
      ),
    );
  }
}

class AddRecipientScreen extends StatelessWidget {
  const AddRecipientScreen({super.key, required this.bankName});
  final String bankName;

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      index: 1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          AppTopBar(title: 'Tambah Penerima', leading: Icons.arrow_back, onLeading: () => Navigator.pop(context), trailing: Icons.notifications_none),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration,
            child: Row(
              children: [
                const IconBox(icon: Icons.account_balance),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Bank Tujuan', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    Text(bankName, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                  ]),
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ubah'))
              ],
            ),
          ),
          const SizedBox(height: 24),
          const FieldLabel('Nomor Rekening'),
          const AppTextField(icon: Icons.dialpad, hint: 'Masukkan nomor rekening'),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Verifikasi',
            icon: Icons.check_circle_outline,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConfirmTransferScreen(contact: FavoriteContact('Amanda Sutrisno', bankName, '1340090621', 'AS')))),
          ),
          const SizedBox(height: 24),
          SectionTitle(title: 'Rekening Terakhir', action: 'Lihat Semua', onTap: () {}),
          const SizedBox(height: 10),
          ...[
            const FavoriteContact('Amanda Sutrisno', 'Mandiri', '1340 0906 21', 'AS'),
            const FavoriteContact('Budi Darmawan', 'Mandiri', '120 112 0045', 'BD'),
            const FavoriteContact('Kevin Sanjaya', 'Mandiri', '111 000 7722', 'KS'),
          ].map((item) => RecipientTile(contact: item)),
          const SizedBox(height: 18),
          const Text('Transaksi aman & terenkripsi oleh Bank Mandiri', textAlign: TextAlign.center, style: TextStyle(color: AppColors.success, fontSize: 12)),
        ],
      ),
    );
  }
}

class ConfirmTransferScreen extends StatelessWidget {
  const ConfirmTransferScreen({super.key, required this.contact});
  final FavoriteContact contact;

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AppTopBar(title: 'Konfirmasi', leading: Icons.arrow_back, onLeading: () => Navigator.pop(context), trailing: Icons.notifications_none),
          const SizedBox(height: 18),
          const Center(child: Text('Jumlah Transfer', style: TextStyle(color: AppColors.muted, fontSize: 12))),
          const SizedBox(height: 4),
          const Center(child: Text('Rp 2.500.000', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.navy))),
          const SizedBox(height: 22),
          const TransferInfoCard(title: 'Dari Rekening', icon: Icons.credit_card, name: 'Tabungan Mandiri', subtitle: AppData.account),
          const Center(child: Icon(Icons.keyboard_arrow_down, color: AppColors.muted)),
          TransferInfoCard(title: 'Ke Rekening', icon: Icons.person_outline, name: contact.name, subtitle: '${contact.bank} - ${contact.accountNumber}'),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration,
            child: const Column(
              children: [
                PriceLine(label: 'Biaya Admin', value: 'Rp 6.500'),
                PriceLine(label: 'Metode', value: 'BI-FAST'),
                Divider(height: 24),
                PriceLine(label: 'Total Bayar', value: 'Rp 2.506.500', strong: true),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Icon(Icons.fingerprint, size: 56, color: Color(0xFFB8C6D5)),
          const SizedBox(height: 8),
          const Text('Sentuh untuk verifikasi biometrik', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 26),
          PrimaryButton(
            label: 'Konfirmasi & Bayar',
            icon: Icons.verified_user_outlined,
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReceiptScreen())),
          ),
          const SizedBox(height: 12),
          const Text('Transaksi terenkripsi dan aman', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          AppTopBar(title: 'Bank Mandiri', leading: Icons.arrow_back, onLeading: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false)),
          const SizedBox(height: 16),
          const Icon(Icons.check_circle, color: AppColors.success, size: 58),
          const SizedBox(height: 10),
          const Center(child: Text('Transfer Berhasil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy))),
          const Center(child: Text('12 Oct 2023 - 14:32 WIB', style: TextStyle(color: AppColors.muted, fontSize: 12))),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: cardDecoration,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DIGITAL RECEIPT', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                Text('TRF-993771635', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                SizedBox(height: 18),
                Center(child: Text('Total Transaksi', style: TextStyle(color: AppColors.muted, fontSize: 12))),
                Center(child: Text('Rp 2.500.000,00', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy))),
                Divider(height: 30),
                ReceiptLine(label: 'Sumber Dana', value: 'Tabungan Mandiri\n123 **** 4567'),
                ReceiptLine(label: 'Penerima', value: 'Aditya Pratama\nBank BCA - 8829 **** 1122'),
                ReceiptLine(label: 'Nominal Transfer', value: 'Rp 2.500.000'),
                ReceiptLine(label: 'Biaya Admin', value: 'Rp 6.500'),
                ReceiptLine(label: 'Total Bayar', value: 'Rp 2.506.500', strong: true),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Expanded(child: Text('Dapatkan Cashback\nHingga Rp 50.000', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              Icon(Icons.stars, color: Colors.white),
            ]),
          ),
          const SizedBox(height: 18),
          PrimaryButton(label: 'Bagikan Struk', icon: Icons.share, onPressed: () {}),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Kembali ke Beranda'),
          )
        ],
      ),
    );
  }
}

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: child,
        ),
      ),
    );
  }
}

class PlainScaffold extends StatelessWidget {
  const PlainScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: child));
}

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.muted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (next) {
          if (next == index) return;
          final pages = [const HomeScreen(), const TransferScreen(), const HistoryScreen(), const ProfileScreen()];
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => pages[next]));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Transfer'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class BrandPill extends StatelessWidget {
  const BrandPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: softShadow),
      child: const Text('Bank Mandiri', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)),
    );
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, required this.title, this.leading, this.trailing, this.onLeading});
  final String title;
  final IconData? leading;
  final IconData? trailing;
  final VoidCallback? onLeading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          if (leading != null) IconButton(onPressed: onLeading, icon: Icon(leading, color: AppColors.navy)) else const SizedBox(width: 48),
          Expanded(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy))),
          if (trailing != null) IconButton(onPressed: () {}, icon: Icon(trailing, color: AppColors.navy)) else const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class SimpleHeader extends StatelessWidget {
  const SimpleHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 18, backgroundColor: Color(0xFFDDE8F2), child: Icon(Icons.person, color: AppColors.blue, size: 20)),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
        const Spacer(),
        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: AppColors.navy)),
      ],
    );
  }
}

class HeaderGreeting extends StatelessWidget {
  const HeaderGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 20, backgroundColor: Color(0xFFDDE8F2), child: Icon(Icons.person, color: AppColors.blue)),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Halo,', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          Text('Budi', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)),
        ]),
        const Spacer(),
        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: AppColors.navy)),
        const Text('Bank Mandiri', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)),
      ],
    );
  }
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(16), boxShadow: softShadow),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Total Saldo Anda', style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(height: 6),
                Text(AppData.balance, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                SizedBox(height: 14),
                Text('Mandiri Utama - 123 ****', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFF071120), borderRadius: BorderRadius.circular(6)),
            alignment: Alignment.center,
            child: const Text('VISA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
          )
        ],
      ),
    );
  }
}

class AccountSourceCard extends StatelessWidget {
  const AccountSourceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(12), boxShadow: softShadow),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('Tabungan Mandiri\n**** 8829', style: TextStyle(color: Colors.white70, height: 1.5))),
            Icon(Icons.copy, color: Colors.white70, size: 18),
          ]),
          SizedBox(height: 18),
          Text('Saldo Tersedia', style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(height: 4),
          Text(AppData.balance, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          Align(alignment: Alignment.centerRight, child: Text('Ganti Rekening', style: TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }
}

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(colors: [Color(0xFF071120), Color(0xFF0F3B56)]),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(label: Text('Eksklusif', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
          Spacer(),
          Text('Cashback hingga 50%\ndi merchant pilihan.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.icon,
    required this.hint,
    this.obscure = false,
    this.controller,
    this.keyboardType,
    this.autofillHints,
  });
  final IconData icon;
  final String hint;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: AppColors.muted),
        suffixIcon: obscure ? const Icon(Icons.visibility_outlined, size: 18, color: AppColors.muted) : null,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.navy,
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.navy)),
      );
}

class QuickAction extends StatelessWidget {
  const QuickAction({super.key, required this.icon, required this.label, required this.onTap, this.color = const Color(0xFFEAF1F8)});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.navy, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, required this.action, required this.onTap});
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)),
        const Spacer(),
        TextButton(onPressed: onTap, child: Text(action, style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.item});
  final BankTransaction item;

  @override
  Widget build(BuildContext context) {
    final amountColor = item.amount.startsWith('-') ? AppColors.danger : AppColors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration,
      child: Row(
        children: [
          IconBox(icon: item.icon, color: item.amount.startsWith('+') ? const Color(0xFFE1F6EE) : const Color(0xFFEAF1F8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
              Text(item.date, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.amount, style: TextStyle(fontWeight: FontWeight.w900, color: amountColor)),
              const SizedBox(height: 4),
              StatusPill(success: item.success),
            ],
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.success});
  final bool success;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: success ? const Color(0xFFE1F6EE) : const Color(0xFFFFF3D7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(success ? 'Berhasil' : 'Diproses', style: TextStyle(fontSize: 10, color: success ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w800)),
    );
  }
}

class CircleContact extends StatelessWidget {
  const CircleContact({super.key, required this.name, required this.onTap, this.initials, this.icon});
  final String name;
  final String? initials;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: initials == null ? Colors.white : const Color(0xFFFFE1D3),
              child: initials == null ? Icon(icon, color: AppColors.navy) : Text(initials!, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)),
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontSize: 12, color: AppColors.navy)),
          ],
        ),
      ),
    );
  }
}

class SelectRow extends StatelessWidget {
  const SelectRow({super.key, required this.icon, required this.title, required this.value, required this.onTap});
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration,
        child: Row(children: [
          Icon(icon, color: AppColors.navy),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy))),
          const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  const FilterChipWidget({super.key, required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: selected ? AppColors.navy : AppColors.input, borderRadius: BorderRadius.circular(18)),
      child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.navy, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class EditableInfo extends StatelessWidget {
  const EditableInfo({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: AppColors.input, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.navy))),
        const Icon(Icons.edit_outlined, color: AppColors.navy, size: 18),
      ]),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration,
      child: Row(children: [
        IconBox(icon: icon),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ])),
        const Icon(Icons.chevron_right, color: AppColors.muted),
      ]),
    );
  }
}

class BankLogoTile extends StatelessWidget {
  const BankLogoTile({super.key, required this.bank});
  final String bank;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddRecipientScreen(bankName: bank))),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: cardDecoration,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const IconBox(icon: Icons.account_balance, color: AppColors.navy, iconColor: Colors.white),
          const SizedBox(height: 8),
          Text(bank, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
        ]),
      ),
    );
  }
}

class ListOption extends StatelessWidget {
  const ListOption({super.key, required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: cardDecoration,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
        onTap: onTap,
      ),
    );
  }
}

class RecipientTile extends StatelessWidget {
  const RecipientTile({super.key, required this.contact});
  final FavoriteContact contact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: cardDecoration,
      child: Row(children: [
        CircleAvatar(backgroundColor: const Color(0xFFFFE1D3), child: Text(contact.initials, style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w900))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
          Text('${contact.bank} - ${contact.accountNumber}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ])),
      ]),
    );
  }
}

class TransferInfoCard extends StatelessWidget {
  const TransferInfoCard({super.key, required this.title, required this.icon, required this.name, required this.subtitle});
  final String title;
  final IconData icon;
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration,
      child: Row(children: [
        IconBox(icon: icon),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
          Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ])),
      ]),
    );
  }
}

class PriceLine extends StatelessWidget {
  const PriceLine({super.key, required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: strong ? AppColors.navy : AppColors.muted, fontWeight: strong ? FontWeight.w900 : FontWeight.w500))),
        Text(value, style: TextStyle(color: AppColors.navy, fontWeight: strong ? FontWeight.w900 : FontWeight.w700)),
      ]),
    );
  }
}

class ReceiptLine extends StatelessWidget {
  const ReceiptLine({super.key, required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12))),
        Expanded(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: AppColors.navy, fontWeight: strong ? FontWeight.w900 : FontWeight.w700))),
      ]),
    );
  }
}

class IconBox extends StatelessWidget {
  const IconBox({super.key, required this.icon, this.color = const Color(0xFFEAF1F8), this.iconColor = AppColors.navy});
  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: iconColor, size: 21),
    );
  }
}

const titleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.navy);
const labelStyle = TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy, fontSize: 13);

final cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  boxShadow: softShadow,
);

final softShadow = [
  const BoxShadow(
    color: Color(0x10000000),
    blurRadius: 18,
    offset: Offset(0, 8),
  )
];

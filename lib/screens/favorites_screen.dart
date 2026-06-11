import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/bank_service.dart';
import '../services/feature_service.dart';
import '../theme/app_theme.dart';
import 'add_recipient_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<FavoriteRecipient> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = SessionManager.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    final favorites = await BankService.getFavorites(user.id);
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      _isLoading = false;
    });
  }

  Future<void> _editFavorite(FavoriteRecipient favorite) async {
    final nameController = TextEditingController(text: favorite.name);
    final accountController =
        TextEditingController(text: favorite.accountNumber);
    final bankController = TextEditingController(text: favorite.bankName);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Favorit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama')),
            TextField(
                controller: accountController,
                decoration: const InputDecoration(labelText: 'No. Rekening')),
            TextField(
                controller: bankController,
                decoration: const InputDecoration(labelText: 'Bank')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan')),
        ],
      ),
    );

    if (saved != true) return;
    await FeatureService.updateFavorite(
      favoriteId: favorite.id,
      name: nameController.text,
      accountNumber: accountController.text,
      bankName: bankController.text,
    );
    await _load();
  }

  Future<void> _deleteFavorite(FavoriteRecipient favorite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Favorit'),
        content: Text('Hapus ${favorite.name} dari daftar favorit?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FeatureService.deleteFavorite(favorite.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Favorit',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRecipientScreen()),
          );
          await _load();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? Center(
                  child: Text('Belum ada favorit.',
                      style: GoogleFonts.hankenGrotesk(
                          color: AppColors.secondary)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final fav = _favorites[index];
                    return ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryFixed,
                        child: Text(fav.name.substring(0, 1).toUpperCase()),
                      ),
                      title: Text(fav.name,
                          style: GoogleFonts.hankenGrotesk(
                              fontWeight: FontWeight.w700)),
                      subtitle: Text('${fav.bankName} • ${fav.accountNumber}'),
                      trailing: PopupMenuButton(
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(
                              value: 'delete', child: Text('Hapus')),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') _editFavorite(fav);
                          if (value == 'delete') _deleteFavorite(fav);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

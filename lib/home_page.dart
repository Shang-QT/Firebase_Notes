import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crudnote/auth_service.dart';
import 'package:firebase_crudnote/crud_service.dart';
import 'package:firebase_crudnote/login_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CrudService service = CrudService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  bool showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Firebase Felecilda'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                showFavoritesOnly = !showFavoritesOnly;
              });
            },
            // Icon changes based on filter state
            icon: Icon(
              showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            tooltip: 'Filter Favorites',
          ),
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
              AuthService().signOut();
              Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginPage()),
            );
          },
         ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openAddDialog(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var docs = snapshot.data!.docs;

          if (showFavoritesOnly) {
            docs = docs.where((doc) {
              // Safely access data to avoid errors on old items
              final data = doc.data() as Map<String, dynamic>;
              return data.containsKey('is_favorite') &&
                  data['is_favorite'] == true;
            }).toList();
          }

          if (docs.isEmpty) {
            return Center(
              child: Text(
                showFavoritesOnly ? 'No favorites yet.' : 'No items found.',
                style: const TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemBuilder: (context, index) {
              var item = docs[index];

              final data = item.data() as Map<String, dynamic>;
              final imageUrl = data ['image_url'];    

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  leading: imageUrl != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      cacheWidth: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(
                        width: 60,
                        height: 60,
                        child: Icon(Icons.broken_image),
                      ),
                    ), // Image.network
                  ) // ClipRRect
                  : null,
                  title: Text(
                    data['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Quantity ${data['quantity'] ?? 0}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // IconButton(
                      //   onPressed: () =>
                      //       service.toggleFavorite(item.id, isFavorite),
                      //   icon: Icon(
                      //     isFavorite ? Icons.favorite : Icons.favorite_border,
                      //     color: isFavorite ? Colors.red : Colors.grey,
                      //   ),
                      // ),
                      IconButton(
                        onPressed: () => openEditDialog(context, item),
                        icon: Icon(Icons.edit, color: Colors.orange),
                      ),
                      IconButton(
                        onPressed: () => _confirmDelete(context, item.id),
                        icon: Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            },
            padding: EdgeInsets.all(8),
            itemCount: docs.length,
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () {
              service.deleteItem(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void openAddDialog(BuildContext context) {
    _nameController.clear();
    _quantityController.clear();

    File? selectedImageFile;
    String? selectedImageUrl;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ontext, setState) =>
        AlertDialog(

        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            if (selectedImageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                selectedImageFile!,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('upload Image'),
              onPressed: () async {
                final pickedFile = await service.pickImageForAddItem();
                if(pickedFile != null) {
                setState((){
                selectedImageFile = pickedFile.file;
                selectedImageUrl = pickedFile.url;
                });
              }
            }
          )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(8),
              ),
            ),
            child: const Text('Save'),
            onPressed: () async {
              if(_nameController.text.isNotEmpty && _quantityController.text. isNotEmpty) {
                await service.addItemwithImage(
                  _nameController.text,
                int.parse(_quantityController.text),
                selectedImageUrl,
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      ),
    );
  }

  void openEditDialog(BuildContext context, DocumentSnapshot item) {
    final data = item.data() as Map<String, dynamic>;
    _nameController.text = data['name'];
    _quantityController.text = data['quantity'].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty &
                  _quantityController.text.isNotEmpty) {
                service.updateItem(
                  item.id,
                  _nameController.text,
                  int.parse(_quantityController.text),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(8),
              ),
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}
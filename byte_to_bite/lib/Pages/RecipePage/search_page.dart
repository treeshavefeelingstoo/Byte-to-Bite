import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class SearchRecipePage extends StatefulWidget {
  const SearchRecipePage({super.key});

  @override
  State<SearchRecipePage> createState() => _SearchRecipePageState();
}

class _SearchRecipePageState extends State<SearchRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _searchHashtagsController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _searchHashtagsController.dispose();
    super.dispose();
  }


  Future<void> _submitSearch() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to post a recipe')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Parse hashtags
      final hashtagsText = _searchHashtagsController.text.trim();
      final hashtags = hashtagsText
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .map((tag) => tag.startsWith('#') ? tag : '#$tag')
          .toList();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search Successful!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, hashtags);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Recipes'),
        backgroundColor: const Color(0xFF479E36),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isUploading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submitSearch,
              child: const Text(
                'Search',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Hashtags
              TextFormField(
                controller: _searchHashtagsController,
                enabled: !_isUploading,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Hashtags',
                  hintText: 'e.g., #vegan, #glutenfree, #healthy',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                  helperText: 'Separate hashtags with commas',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter at least one hashtag';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

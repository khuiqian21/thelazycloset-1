import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'albumdb.dart';
import 'album.dart';
import 'image_page.dart';
import 'package:image_cropper/image_cropper.dart';
import 'removeapi.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

class PhotoAlbumScreen extends StatefulWidget {
  final int id;

  const PhotoAlbumScreen({super.key, required this.id});

  @override
  State<PhotoAlbumScreen> createState() => _PhotoAlbumScreenState();
}

class _PhotoAlbumScreenState extends State<PhotoAlbumScreen> {
  Album album = Album(name: '', images: []);
  bool isLoading = false;

  @override
  void initState() {
    refreshAlbum();
    super.initState();
  }

  Future refreshAlbum() async {
    setState(() => isLoading = true);
    album = await AlbumDB.instance.readAlbum(widget.id);
    setState(() => isLoading = false);
  }

  Future _pickImage(ImageSource source) async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: source);
    if (pickedImage != null) {
      final croppedImage = await ImageCropper().cropImage(
        sourcePath: pickedImage.path, // Set desired aspect ratio
        compressQuality: 100, // Adjust the compression quality as needed
        maxWidth: 500, // Limit the maximum width of the cropped image
        maxHeight: 500, // Limit the maximum height of the cropped image
      );
      if (croppedImage != null) {
        final removeApi = RemoveAPI();
        final removedBgImage = await removeApi.removeBgApi(croppedImage.path);

        setState(() {
          album.images.add(base64Encode(removedBgImage));
        });
        await AlbumDB.instance.update(album);
      }
    }
    return;
  }

  Future deleteImage(int index) async {
    setState(() {
      album.images.removeAt(index);
    });
    await AlbumDB.instance.update(album);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const ImageIcon(
            AssetImage('images/backarrow.png'),
            size: 20,
            color: Colors.white,
          ),
        ),
        title: const ImageIcon(
          AssetImage('images/hanger.png'),
          size: 30,
          color: Colors.white,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: album.images.length,
                    itemBuilder: (context, index) {
                      return RawMaterialButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImagePage(
                                imagePath: album.images[index],
                                index: index,
                              ),
                            ),
                          );
                        },
                        onLongPress: () async {
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                backgroundColor:
                                    const Color.fromARGB(255, 31, 30, 30),
                                title: const Text(
                                  'Delete image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                content: const Text(
                                  'Are you sure you want to delete this image?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                actionsAlignment:
                                    MainAxisAlignment.spaceBetween,
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Cancel',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        )),
                                    onPressed: () async =>
                                        Navigator.pop(context),
                                  ),
                                  TextButton(
                                    child: const Text('Confirm',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        )),
                                    onPressed: () async {
                                      deleteImage(index);
                                      Navigator.pop(context);
                                      refreshAlbum();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Container(
                            decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image:
                                Image.memory(base64Decode(album.images[index]))
                                    .image,
                            fit: BoxFit.cover,
                          ),
                        )),
                      );
                    },
                  )),
            ),
            FloatingActionButton(
              onPressed: () async {
                _pickImage(ImageSource.gallery);
              },
              backgroundColor: Colors.black,
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

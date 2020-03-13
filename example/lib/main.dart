import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scaffold_list/scaffold_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scaffold List Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ScaffoldListDemoPage(),
    );
  }
}

// Model Class
class Post {
  final int userId;
  final int id;
  final String title;
  final String body;

  Post({this.userId, this.id, this.title, this.body});

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        userId: json['userId'],
        id: json['id'],
        title: json['title'],
        body: json['body'],
      );

  static List<Post> fromJsonList(List<dynamic> data) =>
      data.map((item) => Post.fromJson(item)).toList();
}

class ScaffoldListDemoPage extends StatefulWidget {
  ScaffoldListDemoPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ScaffoldListDemoPageState createState() => _ScaffoldListDemoPageState();
}

class _ScaffoldListDemoPageState extends State<ScaffoldListDemoPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scaffoldListKey = GlobalKey<ScaffoldListState>();

  Future<List<Post>> _posts;

  @override
  void initState() {
    super.initState();
    _posts = _fetchPosts();
  }

  Future<List<Post>> _fetchPosts() async {
    final response =
        await http.get('https://jsonplaceholder.typicode.com/posts');

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.
      return Post.fromJsonList(jsonDecode(response.body));
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Scaffold List Demo'),
        actions: <Widget>[
          IconButton(
            tooltip: MaterialLocalizations.of(context).searchFieldLabel,
            icon: Icon(Icons.search),
            onPressed: () async {
              // Open search delegate
              // Returns Future<Post> or null if closed
              final Post post =
                  await _scaffoldListKey.currentState.showSearch();

              if (post != null) {
                _scaffoldKey.currentState.showSnackBar(SnackBar(
                  content: Text("Selected post with id = ${post.id}"),
                ));
              }
            },
          )
        ],
      ),
      // Type must be passed as template for this example we are using `Post`
      body: ScaffoldList<Post>(
        // Use key to show search delegate
        key: _scaffoldListKey,
        // List can be Stream<List<Post>>, Future<List<Post>> or List<Post>
        list: _posts,
        // Build your item widget
        itemBuilder: (BuildContext context, Post post) => ListTile(
          title: Text(post.title),
          subtitle: Text(post.body),
        ),
        // Useaful when using Stream<List<T>> or Future<List<T>>
        filter: (Post post) => post.title.toLowerCase().startsWith("s"),
        // Also useaful when using Stream<List<T>> or Future<List<T>>
        sort: (Post postA, Post postB) =>
            postA.title.length.compareTo(postB.title.length),
        // Filter search results use key to show search delegate as shown above
        searchFilter: (Post post, String query) =>
            post.title.toLowerCase().contains(query.toLowerCase()),
      ),
    );
  }
}

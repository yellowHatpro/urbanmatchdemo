import 'dart:async';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

import 'connectionStatusSingleton.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late StreamSubscription _connectionChangeStream;
  List<dynamic> _repositories = [];
  final Map<String, bool> _loadingCommits = {};
  bool _isLoading = false;
  bool _isOffline = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _fetchRepositories();
    ConnectionStatusSingleton connectionStatusSingleton = ConnectionStatusSingleton
        .getInstance();
    _connectionChangeStream =
        connectionStatusSingleton.connectionChange.listen(connectionChanged);
  }

  void connectionChanged(dynamic hasConnection) {
    setState(() {
      _isOffline = !hasConnection;
    });
  }

  Future<void> _fetchRepositories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
          Uri.parse('https://api.github.com/users/freeCodeCamp/repos'));

      setState(() {
        _isLoading = false;
        if (response.statusCode == 200) {
          _repositories = json.decode(response.body);
          for (var repo in _repositories) {
            _loadingCommits[repo['name']] = false;
          }
          _fetchLastCommits();
        } else {
          _repositories = [];
          _isError = true;
          Fluttertoast.showToast(
            msg: "Failed to fetch repositories",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 3,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _repositories = [];
        _isError = true;
      });
    }
  }

  Future<void> _fetchLastCommits() async {
    for (var repo in _repositories) {
      setState(() {
        _loadingCommits[repo['name']] = true;
      });

      final commitResponse =
      await http.get(Uri.parse(
          'https://api.github.com/repos/freeCodeCamp/${repo['name']}/commits'));
      if (commitResponse.statusCode == 200) {
        final List<dynamic> commits = json.decode(commitResponse.body);
        if (commits.isNotEmpty) {
          var lastCommitObject = {
            'message': commits[0]['commit']['message'],
            'author': commits[0]['commit']['author']['name'],
            'date': commits[0]['commit']['author']['date'],
          };
          repo['last_commit'] = lastCommitObject;
        }
      }

      setState(() {
        _loadingCommits[repo['name']] = false;
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181825),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isError || _isOffline ?
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Failed to fetch repositories',
              style: TextStyle(fontSize: 18,
                  color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _fetchRepositories();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _repositories.length,
        itemBuilder: (BuildContext context, int index) {
          final repo = _repositories[index];
          return Card(
            color: const Color(0xFF313244),
            margin: const EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(repo['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFFa896ec)),),
                  const SizedBox(height: 8),
                  Text(repo['description'] ?? '',
                    style: const TextStyle(color: Color(0xFFa896ec)),),
                  const SizedBox(height: 8),
                  if (_loadingCommits[repo['name']] == true)
                    const Center(child: CircularProgressIndicator())
                  else
                    if (repo['last_commit'])
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Last Commit:',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFa896ec)),),
                          Text('Message: ${repo['last_commit']['message']}',
                            style: const TextStyle(color: Color(0xFFa896ec)),),
                          Text('Author: ${repo['last_commit']['author']}',
                            style: const TextStyle(color: Color(0xFFa896ec)),),
                          Text('Date: ${repo['last_commit']['date']}',
                            style: const TextStyle(color: Color(0xFFa896ec)),),
                        ],
                      ),
                  const SizedBox(height: 8),
                  Text('${repo['stargazers_count'] ?? 0} stars',
                    style: const TextStyle(color: Color(0xFFa896ec)),),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

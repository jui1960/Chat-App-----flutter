import 'package:flutter/material.dart';
import 'package:chat_app/menu_view.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/theme_notifier.dart';

class Conversation {
  final String name;
  final String lastMessage;
  final String time;
  final String imageUrl;

  const Conversation({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.imageUrl,
  });
}

class ChatsView extends StatelessWidget {
  const ChatsView({super.key});

  final List<Conversation> sampleConversations = const [
    // Conversation(name: 'Alif Emu', lastMessage: 'How is your life going?', time: '12:30 PM', imageUrl: "https://via.placeholder.com/150/007bff/ffffff?text=AE"),
    // You can uncomment sample data here if you want to see the list populate.
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final headerTextColor = isDarkMode ? Colors.white : Colors.black;
    final searchFillColor = isDarkMode ? const Color(0xFF283543) : Colors.white;
    final listBackgroundColor = isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white;

    Widget listContent;

    if (sampleConversations.isEmpty) {
      listContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              "No active conversations.",
              style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500),
            ),
            Text(
              "Start a chat to see it here.",
              style: TextStyle(
                  fontSize: 14, color: isDarkMode ? Colors.grey : Colors.grey.shade500),
            ),
          ],
        ),
      );
    } else {
      listContent = ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sampleConversations.length,
        separatorBuilder: (context, index) => Divider(
            height: 1,
            indent: 80,
            endIndent: 10,
            color: isDarkMode ? Colors.grey.shade800 : const Color(0xFFF1F1F1)),
        itemBuilder: (context, index) {
          final conversation = sampleConversations[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              backgroundImage: NetworkImage(conversation.imageUrl),
            ),
            title: Text(conversation.name,
                style: TextStyle(fontWeight: FontWeight.bold, color: headerTextColor)),
            subtitle: Text(
              conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
            ),
            trailing: Text(conversation.time,
                style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade600 : Colors.grey)),
            onTap: () {
              // TODO: Navigate to ChatScreen
            },
          );
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ChatApp",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: headerTextColor),
              ),
              IconButton(
                icon: Icon(Icons.group_add, color: Theme.of(context).colorScheme.secondary),
                onPressed: () {
                  // TODO: Navigate to Group Creation Screen
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: searchFillColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: isDarkMode ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: TextField(
              style: TextStyle(color: headerTextColor),
              decoration: InputDecoration(
                hintText: "Search a friend",
                hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade600 : Colors.grey),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.secondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: listBackgroundColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: listContent,
          ),
        ),
      ],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const ChatsView(),
    const MenuView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF0F5F8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: isDarkMode ? Colors.white60 : Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? const Color(0xFF1E2733) : Colors.white,
      ),
    );
  }
}
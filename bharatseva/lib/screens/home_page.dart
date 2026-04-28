import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../models/scheme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  VoiceProvider? _voiceProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _voiceProvider = Provider.of<VoiceProvider>(context, listen: false);
      _voiceProvider!.addListener(_onVoiceUpdate);
    });
  }

  @override
  void dispose() {
    _voiceProvider?.removeListener(_onVoiceUpdate);
    super.dispose();
  }

  void _onVoiceUpdate() {
    if (_voiceProvider != null && _voiceProvider!.suggestedSchemes.isNotEmpty) {
      final schemes = List<Scheme>.from(_voiceProvider!.suggestedSchemes);
      _voiceProvider!.clearSuggestedSchemes();
      _showSchemesBottomSheet(schemes);
    }
  }

  void _showSchemesBottomSheet(List<Scheme> schemes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recommended Schemes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFB2056),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: schemes.length,
                  itemBuilder: (context, index) {
                    final scheme = schemes[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(20),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFFB2056).withAlpha(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scheme.nameHi,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFB2056),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            scheme.descriptionHi,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Bharat Seva',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFB2056),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<VoiceProvider>(
        builder: (context, voiceProvider, child) {
          if (voiceProvider.formState == VoiceFormState.notStarted) {
            return SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.assured_workload_outlined,
                      size: 100,
                      color: Color(0xFFFB2056),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        voiceProvider.startOnboarding();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFB2056),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'शुरुआत करें',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          }

          if (voiceProvider.formState == VoiceFormState.completed) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Your Profile Summary',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFB2056),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            children: voiceProvider.userProfile.entries.map((e) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        e.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // View schemes or restart
                        if (voiceProvider.suggestedSchemes.isNotEmpty) {
                          final schemes = List<Scheme>.from(voiceProvider.suggestedSchemes);
                          voiceProvider.clearSuggestedSchemes();
                          _showSchemesBottomSheet(schemes);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFB2056),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'View Recommended Schemes',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Icon(
                  Icons.assured_workload_outlined,
                  size: 80,
                  color: const Color(0xFFFB2056).withAlpha(204),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      voiceProvider.isListening
                          ? 'Listening...'
                          : (voiceProvider.spokenText.isEmpty
                                ? 'Tap the mic and say what kind of scheme you are looking for'
                                : voiceProvider.spokenText),
                      key: ValueKey<String>(
                        voiceProvider.isListening.toString() +
                            voiceProvider.spokenText,
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: voiceProvider.isListening
                            ? const Color(0xFFFB2056)
                            : Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                GestureDetector(
                  onTap: () {
                    voiceProvider.toggleListening();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: voiceProvider.isListening ? 180 : 140,
                    width: voiceProvider.isListening ? 180 : 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(
                        0xFFFB2056,
                      ).withAlpha(voiceProvider.isListening ? 38 : 13),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: voiceProvider.isListening ? 130 : 100,
                        width: voiceProvider.isListening ? 130 : 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFFFB2056,
                          ).withAlpha(voiceProvider.isListening ? 77 : 26),
                        ),
                        child: Center(
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFB2056), Color(0xFFFF5E80)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFB2056).withAlpha(102),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                voiceProvider.isListening
                                    ? Icons.mic
                                    : Icons.mic_none,
                                key: ValueKey<bool>(voiceProvider.isListening),
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(1),
                        spreadRadius: 2,
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Swipe up to explore all schemes',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
